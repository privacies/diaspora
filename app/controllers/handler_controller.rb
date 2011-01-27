class HandlerController < ApplicationController
  def getPosts
    @userId=params[:userId]
    @aspectId=params[:aspectId]
    @aspectContacts=params[:aspectContacts]
    
    params='getPosts/'+@userId+'/'+@aspectId+'/'+@aspectContacts+'/'
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
      params = {'xml' => URI.encode(@return_xml)}
      
      uri = URI.parse(encoded_uri_string)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.path)
      request.set_form_data( params )
      request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 
      response = http.request(request)
    rescue
    end
    @return_body = response
    logger.debug(response.body)
    
  end
  
  def mediator(uri_string)
    require 'net/http'
    require 'uri'
    begin
      encoded_uri_string=uri_string 
      logger.debug("After encode: "+encoded_uri_string)
      uri = URI.parse(encoded_uri_string)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.path)
      response = http.request(request)
      logger.debug(response.body)
    rescue
    end
    return response.body
  end

end
