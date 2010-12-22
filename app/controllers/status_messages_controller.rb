#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class StatusMessagesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html
  respond_to :json, :only => :show

  def create

    if params[:status_message][:aspect_ids] == "all"
      params[:status_message][:aspect_ids] = current_user.aspects.collect{|x| x.id}
      target_aspects=params[:status_message][:aspect_ids]
    else
      target_aspects=[params[:status_message][:aspect_ids]]
    end

    photos = Photo.all(:id.in => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)

    public_flag = params[:status_message][:public]
    public_flag.to_s.match(/(true)/) ? public_flag = true : public_flag = false
    params[:status_message][:public] = public_flag
    @status_message = current_user.build_post(:status_message, params[:status_message])


    if photos || @status_message.save!(:safe => true)
      raise 'MongoMapper failed to catch a failed save' unless @status_message.id

      @status_message.photos += photos unless photos.nil?
      current_user.add_to_streams(@status_message, params[:status_message][:aspect_ids])
      current_user.dispatch_post(@status_message, :to => params[:status_message][:aspect_ids], :url => post_url(@status_message))


      for photo in photos
        photo.public = public_flag
        photo.save
        current_user.add_to_streams(photo, params[:status_message][:aspect_ids])
        current_user.dispatch_post(photo, :to => params[:status_message][:aspect_ids])
        
        target_contacts = Contact.all(:aspect_ids.in => target_aspects, :pending => false)
        
        target_handles = target_contacts.collect do |contact|
          contact.person.diaspora_handle
        end
    
        created_posts(photo, target_handles.to_s)
      end

      respond_to do |format|
        format.js{ render :json => { :post_id => @status_message.id,
                                     :html => render_to_string(
                                       :partial => 'shared/stream_element',
                                       :locals => {
                                         :post => @status_message,
                                         :person => @status_message.person,
                                         :photos => @status_message.photos,
                                         :comments => [],
                                         :aspects => current_user.aspects,
                                         :current_user => current_user
                                        }
                                     )
                                    },
                                     :status => 201 }
        format.html{ respond_with @status_message }
      end
    else
      respond_to do |format|
        format.js{ render :status => 406 }
      end
    end
  end

  def destroy
    @status_message = current_user.my_posts.where(:_id =>  params[:id]).first
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
    comments_hash = Comment.hash_from_post_ids [@status_message.id]
    person_hash = Person.from_post_comment_hash comments_hash
    @comment_hashes = comments_hash[@status_message.id].map do |comment|
      {:comment => comment,
        :person => person_hash[comment.person_id]
      }
    end
    respond_with @status_message
  end
  
  def created_posts (photo, target_handles)
    params={'userId'=>current_user.person.diaspora_handle.to_s, 'aspectId'=> target_handles, 'serializedItemString'=> photo.id.to_s }
    makeHTTPReq(params)
  end
  
  def makeHTTPReq(params)
    require 'net/http'
    require 'uri'
    uri = URI.parse( "http://10.0.0.250/LAMService.svc" )
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.path)
    request.set_form_data( params )
    request = Net::HTTP::Get.new( uri.path+ '?' + request.body )
    response = http.request(request)
    logger.debug(response.body)
  end
end