class Lfn < ThirdPartyService
  class << self

    SERVICE_URI = "http://lam.lfn.net/LAMService/invoke"

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
      if params[:photo].try(:url)
        photos = params[:photo].try(:url)
      else
        photos = params[:post].photos ? params[:post].photos.map {|i| i.try(:url) } : nil
      end
      message           = params[:post].message
      user              = params[:user]
      type              = params[:type] || 'json'
      
      params            = {
       :userId          => user.person.diaspora_handle.to_s,
       :aspectIds       => value_as_array(params[:target_aspect_ids]),
       :aspectContacts  => get_aspect_contacts_from_ids(params[:target_aspect_ids]),
       :message         => message,
       :postControl     => params[:post].control.try(:to_json),
       :postUrl         => photos
      }
      Rails.logger.info("LFN: CREATE POST : #{params.to_yaml}")
      invoke({:method => 'createPost', :service_url => SERVICE_URI, :params => params, :type => type})
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
    def receive_post(params)
      object         = params[:post]
      target         = params[:target]
      type           = params[:type] || 'json'
      url            = params[:url] || (object.respond_to?(:url) ? object.url : nil)
      post           = object.is_a?(StatusMessage) ? object : object.status_message
      params         = {
        :userId      => post.diaspora_handle,
        :receiverId  => target.person.diaspora_handle,
        :message     => post.message,
        :postControl => post.control.try(:to_json),
        :postUrl     => url
      }
      Rails.logger.info("LFN: RECEIVE POST : #{params.to_yaml}")
      invoke({:method => 'receivePost', :service_url => SERVICE_URI, :params => params, :type => type})
    end

    # retrieve the posts from the lfn service
    def get_posts(params)
      sub_handler       = params[:sub_handler]
      type              = params[:type]
      params.merge!({ :userId         => params[:user_id],
                      :aspectIds      => value_as_array(params[:aspect_ids]),
                      :aspectContacts => value_as_array(params[:aspect_contacts]) })
      Rails.logger.info("LFN: GET POSTS : #{params.to_yaml}")
      mediator_xml = invoke({:method => 'getPosts', :service_url => SERVICE_URI, :params => params, :type => type})
      return_xml   = CGI.unescapeHTML(mediator_xml)
      if sub_handler.present?
        begin
          response = Net::HTTP.post_form(URI.parse(URI.encode(sub_handler)),
                                         {'xml' => URI.encode(return_xml)})
          return_xml = format_response(response.body)
        rescue
        end
      end
      return_xml
    end

    def forward(params)
      uri      = URI.parse("http://cxml.lfn.net/" + params[:file] + "." + params[:type])
      response = Net::HTTP::get_response(uri)
      response.body
    end

    private

    #remove the xml encoding for the lfn
    def format_response(response)
      response.gsub('<?xml version="1.0" encoding="utf-8"?>', '')
    end

    def value_as_array(value)
      value = value.split(",") if value.is_a? String
      value
    end

  end

end
