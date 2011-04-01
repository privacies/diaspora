class Lfn < ThirdPartyService
  class << self

    SERVICE_URI = "http://lam.lfn.net/LAMService/invoke"

    # Get the url params for the link
    def url_params(params = {})
      user                = params[:user]
      aspect_id           = params[:aspect_id]
      aspect_contacts     = get_aspect_contacts(aspect_id, user)

      aspect_contacts     = aspect_contacts.join(",").to_s if aspect_contacts.is_a? Array
      aspect_id           = aspect_id.join(',') if aspect_id.is_a? Array

      url_params = { :userId => user.person.diaspora_handle.to_s,
                     :aspectId => aspect_id.to_s,
                     :aspectContacts => aspect_contacts }
    end

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
      image_url         = params[:photo].try(:url)
      message           = params[:post].message
      user              = params[:user]
      type              = params[:type]
      
      params            = {
       :userId          => user.person.diaspora_handle.to_s,
       :aspectIds       => value_as_array(params[:target_aspect_ids]),
       :aspectContacts  => get_aspect_contacts_from_ids(params[:target_aspect_ids], user),
       :message         => message,
       :postControl     => params[:post].control.try(:to_json),
       :postUrl         => image_url
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
      post           = params[:post]
      target         = params[:target]
      type           = params[:type]
      params         = {
        :userId      => post.person.diaspora_handle,
        :receiverId  => target.person.diaspora_handle,
        :message     => post.message,
        :postControl => post.control.try(:to_json),
        :postUrl     => post.url_params
      }
      Rails.logger.info("LFN: RECEIVE POST : #{params.to_yaml}")
      invoke({:method => 'receivePost', :service_url => SERVICE_URI, :params => params, :type => type})
    end

    # retrieve the posts from the lfn service
    def get_posts(params)
      sub_handler       = params[:sub_handler]
      type              = params[:type]
      params            = {
        :userId         => params[:user_id],
        :aspectIds      => value_as_array(params[:aspect_ids]),
        :aspectContacts => value_as_array(params[:aspect_contacts])
      }
      Rails.logger.info("LFN: GET POSTS : #{params.to_yaml}")
      mediator_xml = invoke({:method => 'getPosts', :service_url => SERVICE_URI, :params => params, :type => type})
      return_xml   = CGI.unescapeHTML(mediator_xml)
      if sub_handler.present?
        begin
          response = Net::HTTP.post_form(URI.parse(URI.encode(sub_handler)),
                                         {'xml' => URI.encode(return_xml)})
          logger.debug(response)
          return_xml = format_response(response.body)
        rescue
        end
      end
      return_xml
    end

    def forward(params)
      uri      = URI.parse("http://cxml.lfn.net/" + params[:file] + "." + params[:format])
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
