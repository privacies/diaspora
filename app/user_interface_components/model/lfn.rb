class Lfn < UserInterfaceComponent
  class << self
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
      #   <% lfn_string= "&siteOwner=bob&currentUser=bob&siteName=RRbob312201044&token=d3d12e0e-7968-458e-92a5-f7ba583cb053&lfnid=Ym9iIyQjVElDS0VUX2YxZTRjZjIxMGRhNzExMWNkYzI4OTk1ZjEyYTliNjllY2Q4ZjFjYjYjJCNib2JAMTIz" %>
      #   <%= link_to "Lfn", aspects_lfn_path.to_s+"?userId="+current_user.person.diaspora_handle.to_s+
      #                       "&aspectId="+aspect_id.to_s+
      #                       "&aspectContacts="+get_aspect_contacts(aspect_id).join(",").to_s+
      #                       lfn_string %>
      # </div>
    end

    def get_posts
      @userId         = params[:userId].to_s
      @aspectId       = params[:aspectId].to_s
      @aspectContacts = params[:aspectContacts].to_s

      params='get_posts/'+@userId+'/'+@aspectId+'/'+@aspectContacts+'/'
      logger.debug(params)


      service_uri="http://lam.lfn.net/LAMService/"
      require 'net/http'
      require 'uri'
      uri_string= service_uri + params
      logger.debug("Before encode: "+uri_string)

      @return_xml=CGI.unescapeHTML(mediator(uri_string))
      # require 'rexml/document'
      # doc = REXML::Document.new(CGI.unescapeHTML(@return_xml))
      # @return_xml=doc.elements[1].elements[1].to_s

      cxml_uri="http://cxml.lfn.net/internalposts.cxml"

      begin
        encoded_uri_string=URI.encode(cxml_uri)
        xml_val=URI.encode(@return_xml)
        params = {'xml' => xml_val }
        response=Net::HTTP.post_form(URI.parse(encoded_uri_string), {'xml'=>xml_val})
        #uri = URI.parse(encoded_uri_string)
        #http = Net::HTTP.new(uri.host, uri.port)
        #request = Net::HTTP::Get.new(uri.path)
        #request.set_form_data( params )
        #request = Net::HTTP::Get.new( uri.path+ '?' + request.body )
        #response = http.request(request)
      rescue
      end
      @cxml_call=encoded_uri_string+"?xml="+xml_val
      logger.debug(encoded_uri_string)
      logger.debug(xml_val)
      logger.debug(response)
      @return_body = if (response.nil?); "EMPTY"; else; response.body; end
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


    ####################################################################################
    ##This function is responsible for sending receivedPost call to mediator. This is what it does:
    # Arguments : Photo pod-user has received
    # * Finds out if the photo was sent by local user. If yes, discard. We only consider photos received by another pod
    # * Gets the Handle of the user who sent the post
    # * Gets the handles of the contacts who will receive the photo
    # * Creates the URL to be sent to LAM with: user who has created photo, 
    #   Photo URL and the handles of viewer who should receive that photo
    ####################################################################################
    def received_posts(post)
      #implement this
      if (post.class.to_s.include?("Photo"))
        Rails.logger.debug("Photo received: "+post.id.to_s)
        received_posts(post)
      else
        Rails.logger.debug("Not photo: "+post.id.to_s)
      end
      remote_path=post.remote_photo_path
      if (remote_path)
        Rails.logger.debug("received remote post: "+post.id.to_s)
        sender=post.person.diaspora_handle
        target=self.person.diaspora_handle
        params="receivedPost/"+sender+"/"+target+"/"+post.url.gsub(":",";").gsub("/","#")+"/"
        makeHTTPReqLib(params)
      else
        Rails.logger.debug("This is a local photo. No request sent")
      end
      Rails.logger.debug("Done with received_posts")
    end

    def makeHTTPReqLib(params)
      service_uri="http://lam.lfn.net/LAMService/"
      require 'net/http'
      require 'uri'
      uri_string= service_uri + params
      Rails.logger.debug("Before encode: "+uri_string)
      encoded_uri_string=URI.encode(uri_string).gsub("%","!")
      Rails.logger.debug("After encode: "+encoded_uri_string)
      uri = URI.parse(encoded_uri_string)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.path)
      response = http.request(request)
      Rails.logger.debug(response.body)
    end
  end

end
