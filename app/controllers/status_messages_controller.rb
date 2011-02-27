#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class StatusMessagesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html
  respond_to :mobile
  respond_to :json, :only => :show

  def create
    params[:status_message][:aspect_ids] = params[:aspect_ids]

    # if params[:status_message][:aspect_ids] == "all"
    #   params[:status_message][:aspect_ids] = current_user.aspects.collect{|x| x.id}
    #   target_aspects=params[:status_message][:aspect_ids]
    # else
    #   target_aspects=[Aspect.find(params[:status_message][:aspect_ids]).id]
    # end
    target_aspects = params[:status_message][:aspect_ids]
    photos = Photo.where(:id => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)

    public_flag = params[:status_message][:public]
    public_flag.to_s.match(/(true)|(on)/) ? public_flag = true : public_flag = false
    params[:status_message][:public] = public_flag

    @status_message = current_user.build_post(:status_message, params[:status_message])
    aspects = current_user.aspects_from_ids(params[:aspect_ids])

    if @status_message.save
      Rails.logger.info("event=create type=status_message chars=#{params[:status_message][:message].length}")

      current_user.add_to_streams(@status_message, aspects)
      receiving_services = params[:services].map{|s| current_user.services.where(
                                  :type => "Services::"+s.titleize).first} if params[:services]
      current_user.dispatch_post(@status_message, :url => post_url(@status_message), :services => receiving_services)

      if !photos.empty?
        for photo in photos
          was_pending = photo.pending
          photo.public = public_flag
          photo.pending = false
          @status_message.photos << photo
          if was_pending
            current_user.add_to_streams(photo, aspects)
            current_user.dispatch_post(photo)
            created_post(photo, target_aspects)
          end
        end
      end

      respond_to do |format|
        format.js { render :json => {:post_id => @status_message.id,
                                     :html => render_to_string(
                                       :partial => 'shared/stream_element',
                                       :locals => {
                                         :post => @status_message,
                                         :person => @status_message.person,
                                         :photos => @status_message.photos,
                                         :comments => [],
                                         :all_aspects => current_user.aspects,
                                         :current_user => current_user
                                       }
                                     )
        },
                           :status => 201 }
        format.html { redirect_to :back}
        format.mobile { redirect_to :back}
      end

    else
      respond_to do |format|
        format.js { render :json =>{:errors =>   @status_message.errors.full_messages}, :status => 406 }
        format.html {redirect_to :back} 
      end
    end
  end

  ####################################################################################
  # Privacies Code
  ##This function is responsible for sending createdPost call to mediator. This is what it does:
  # Arguments : Photo Shared and Aspects in which photo is shared
  # * Finds out the contacts associated with the aspects
  # * Gets the Handles of the contacts
  # * Throws away the handles of the contacts who are in different pod
  # * Creates the URL to be sent to LAM with: user who has created photo, Aspects in which he has shared the phtoo
  # , Photo URL and the handles of viewers who should receive that photo
  ####################################################################################
  def created_post(photo, target_aspects)
    target_contacts = Contact.joins(:aspects).where(:aspects => {:id => target_aspects}, :pending => false)
    diaspora_host=photo.diaspora_handle.split("@")[1]

    target_handles = target_contacts.collect do |contact|
      contact.person.diaspora_handle
    end

    local_target_handles = target_handles.select do |handle|
      handle.split("@")[1].eql?(diaspora_host)
    end

    if local_target_handles.empty?
      local_target_handles="NONE"
    else
      local_target_handles=local_target_handles.join(",").to_s
    end

    photo_url="http;//"+diaspora_host+photo.url

    params='createdPost/'+current_user.person.diaspora_handle.to_s+'/'+target_aspects.join(",").to_s+
    '/'+photo_url.gsub("/","#")+'/'+local_target_handles+'/'
    makeHTTPReq(params)
  end

  ###########################################################################
  # Privacies Code
  # HTTP get request
  # createdPost calls this function to send the photos to LAM
  # Have enabled threading so that Request to LAM is asynchronous and does not delay
  # response to the use who has posted the photo
  # Have also enabled exception handling incase LAM server is not reachable
  ###########################################################################  

  def makeHTTPReq(params)
    service_uri="http://lam.lfn.net/LAMService/"
    require 'net/http'
    require 'uri'
    uri_string= service_uri + params
    logger.debug("Before encode: "+uri_string)
    begin
      Thread.new do
        encoded_uri_string=URI.encode(uri_string).gsub("%","!")
        logger.debug("After encode: "+encoded_uri_string)
        uri = URI.parse(encoded_uri_string)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.path)
        response = http.request(request)
        logger.debug(response.body)
      end
    rescue
    end
  end

  def destroy
    @status_message = current_user.posts.where(:id => params[:id]).first
    if @status_message
      @status_message.destroy
      render :nothing => true, :status => 200
    else
      Rails.logger.info "event=post_destroy status=failure user=#{current_user.diaspora_handle} reason='User does not own post'"
      render :nothing => true, :status => 404
    end
  end

  def show
    @status_message = current_user.find_visible_post_by_id params[:id]
    if @status_message
      @object_aspect_ids = @status_message.aspects.map{|a| a.id}

      # mark corresponding notification as read
      if notification = Notification.where(:recipient_id => current_user.id, :target_id => @status_message.id).first
        notification.unread = false
        notification.save
      end

      respond_with @status_message
    else
      redirect_to :back
    end
  end

end
