class Lfn < UserInterfaceComponent
  class << self

    SERVICE_URI = "http://lam.lfn.net/LAMService/"

    ####################################################################################
    # Privacies Code
    # This function is responsible for sending createdPost call to mediator. This is what it does:
    # Arguments : Photo Shared and Aspects in which photo is shared
    # * Finds out the contacts associated with the aspects
    # * Gets the Handles of the contacts
    # * Throws away the handles of the contacts who are in different pod
    # * Creates the URL to be sent to LAM with: user who has created photo, Aspects in which he has shared the phtoo
    # , Photo URL and the handles of viewers who should receive that photo
    ####################################################################################

    def created_post(params)
      photo                 = params[:photo]
      target_aspects        = params[:target_aspects]
      user                  = params[:user]

      target_contacts       = Contact.joins(:aspects).where(:aspects => {:id => target_aspects}, :pending => false)
      diaspora_host         = photo.diaspora_handle.split("@")[1]
      target_handles        = target_contacts.collect do |contact|
        contact.person.diaspora_handle
      end

      local_target_handles = target_handles.select do |handle|
        handle.split("@")[1].eql?(diaspora_host)
      end

      local_target_handles = (local_target_handles.empty? ? "NONE" : local_target_handles.join(",").to_s)

      params = 'createdPost/' + user.person.diaspora_handle.to_s + '/' + target_aspects.join(",").to_s +
      '/'+ photo.url.gsub("/","#") + '/' + local_target_handles + '/'

      call_service(params)
    end

    # Get the url params for the link
    def url_params(params = {})
      user            = params[:user]
      aspect_id       = params[:aspect_id]
      aspect_contacts = get_aspect_contacts(aspect_id, user).join(",").to_s
      aspect_contacts = 'None' if aspect_contacts.blank?
      
      url_params = {:siteOwner => 'bob',
                    :userId => user.person.diaspora_handle.to_s,
                    :aspectId => aspect_id.to_s,
                    :aspectContacts => aspect_contacts,
                    :currentUser => 'bob',
                    :siteName => 'RRbob312201044',
                    :token => 'd3d12e0e-7968-458e-92a5-f7ba583cb053',
                    :lfnid => 'Ym9iIyQjVElDS0VUX2YxZTRjZjIxMGRhNzExMWNkYzI4OTk1ZjEyYTliNjllY2Q4ZjFjYjYjJCNib2JAMTIz'}
    end

    ####################################################################################
    ##This function is responsible for sending receivedPost call to mediator. This is what it does:
    # Arguments : Photo pod-user has received
    # * Finds out if the photo was sent by local user. If yes, discard. We only consider photos received by another pod
    # * Gets the Handle of the user who sent the post
    # * Gets the handles of the contacts who will receive the photo
    # * Creates the URL to be sent to LAM with: user who has created photo, 
    #   Photo URL and the handles of viewer who should receive that photo
    ####################################################################################
    def received_posts(params)

      post   = params[:post]
      target = params[:target]

      ###########################################################################
      # Privacies Code
      # Call to received_post function if received is not a status message. We only want to add photo
      # collections in LAM
      ###########################################################################        
      return unless post.is_a? Photo
      remote_path = post.remote_photo_path
      if (remote_path)
        Rails.logger.debug("received remote post: "+ post.id.to_s)
        params           = 'receivePost/{userId}/{aspectContact}/%{message}/%{postUrl}/' % {
          :userId        => post.person.diaspora_handle,
          :aspectContact => target.person.diaspora_handle,
          :message       => post.message,
          :postUrl       => post.url.gsub("/","#")
        }
        call_service(params)
      else
        Rails.logger.debug("This is a local photo. No request sent")
      end
      Rails.logger.debug("Done with received_posts")
    end

    ###########################################################################
    # Privacies Code
    # HTTP get request
    # createdPost calls this function to send the photos to LAM
    # Have enabled threading so that Request to LAM is asynchronous and does not delay
    # response to the use who has posted the photo
    # Have also enabled exception handling incase LAM server is not reachable
    ###########################################################################  
    def call_service(params)
      uri_string = SERVICE_URI + params
      begin
        Rails.logger.debug("Before encode: "+ uri_string)
        encoded_uri_string = URI.encode(uri_string).gsub("%","!")
        Rails.logger.debug("After encode: " + encoded_uri_string)
        uri      = URI.parse(encoded_uri_string)
        response = Net::HTTP.get_response(uri)
        Rails.logger.debug(response.body)
      rescue
      end
    end

  end

end
