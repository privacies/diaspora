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
    
    @return_xml=mediator(uri_string)
    
    cxml_uri="http://cxml.lfn.net/posts.cxml?xml="+@return_xml
    
    begin
      encoded_uri_string=URI.encode(cxml_uri)
      logger.debug("After encode cxml uri: "+encoded_uri_string)
      uri = URI.parse(encoded_uri_string)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.path)
      response = http.request(request)
      logger.debug(response.body)
    rescue
    end
    
    @return_body=response.body
    
  end
  
  def mediator(uri_string)
    require 'net/http'
    require 'uri'
    begin
      encoded_uri_string=URI.encode(uri_string).gsub("%","!")
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
