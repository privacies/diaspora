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

    photos = Photo.where(:id => [*params[:photos]], :diaspora_handle => current_user.person.diaspora_handle)

    public_flag = params[:status_message][:public]
    public_flag.to_s.match(/(true)|(on)/) ? public_flag = true : public_flag = false
    params[:status_message][:public] = public_flag

    @status_message = current_user.build_post(:status_message, params[:status_message])
    aspects = current_user.aspects_from_ids(params[:aspect_ids])

    if @status_message.save
      current_user.add_to_streams(@status_message, aspects)
      current_user.dispatch_post(@status_message, :url => post_url(@status_message))
      if !photos.empty?
        @status_message.photos += photos
        for photo in photos
          photo.public = public_flag
          photo.pending = false
          photo.save
          current_user.add_to_streams(photo, aspects)
          current_user.dispatch_post(photo)
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
        format.html { respond_with @status_message }
        format.mobile{ redirect_to :back}
      end
    else
      respond_to do |format|
        format.js { render :status => 406 }
      end
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
    @object_aspect_ids = @status_message.aspects.map{|a| a.id}

    # mark corresponding notification as read
    if notification = Notification.where(:recipient_id => current_user.id, :target_id => @status_message.id).first
      notification.unread = false
      notification.save
    end

    respond_with @status_message
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
  def created_posts (photo, target_aspects)
    target_contacts = Contact.all(:aspect_ids.in => target_aspects, :pending => false)
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
  
end
