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

    def create_post(params)
      image_url         = params[:photo] ? params[:photo].url.gsub("/","#") : self::EMPTY_VALUE
      message           = params[:post].message.blank? ? self::EMPTY_VALUE : params[:post].message
      target_aspect_ids = params[:target_aspect_ids].present? ? params[:target_aspect_ids] : params[:aspect_ids]
      user              = params[:user]
      
      target_aspect_ids = target_aspect_ids.join(",") if target_aspect_ids.is_a? Array
      params               = "createPost/%{userId}/%{aspectIds}/%{aspectContacts}/%{message}/%{postUrl}/" % {
       :userId             => user.person.diaspora_handle.to_s,
       :aspectIds          => target_aspect_ids,
       :aspectContacts     => get_aspect_contacts_from_ids(target_aspect_ids, user),
       :message            => message,
       :postUrl            => image_url
      }
      Rails.logger.info("LFN: CREATE POST : #{params.to_yaml}")
      call_service(params)
    end

    # Get the url params for the link
    def url_params(params = {})
      user            = params[:user]
      aspect_id       = params[:aspect_id]
      aspect_contacts = get_aspect_contacts(aspect_id, user).join(",").to_s
      
      aspect_id = aspect_id.join(',') if aspect_id.is_a? Array
      url_params = {:userId => user.person.diaspora_handle.to_s,
                    :aspectId => aspect_id.to_s,
                    :aspectContacts => aspect_contacts
                    # :siteOwner => 'bob',
                    # :currentUser => 'bob',
                    # :siteName => 'RRbob312201044',
                    # :token => 'd3d12e0e-7968-458e-92a5-f7ba583cb053',
                    # :lfnid => 'Ym9iIyQjVElDS0VUX2YxZTRjZjIxMGRhNzExMWNkYzI4OTk1ZjEyYTliNjllY2Q4ZjFjYjYjJCNib2JAMTIz'
                    }
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
    def receive_posts(params)
      post   = params[:post]
      target = params[:target]
      params           = 'receivePost/{userId}/{aspectContact}/%{message}/%{postUrl}/' % {
        :userId        => post.person.diaspora_handle,
        :aspectContact => target.person.diaspora_handle,
        :message       => post.message.blank? ? self::EMPTY_VALUE : post.message,
        :postUrl       => post.url.blank? ? self::EMPTY_VALUE : post.url.gsub("/","#")
      }
      Rails.logger.info("LFN: RECEIVE POST : #{params.to_yaml}")
      call_service(params)
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
