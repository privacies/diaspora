class HandlerController < ApplicationController

  before_filter :load_params

  layout false

  def call
    respond_to do |format|
      format.xml { render :text => send(params[:request].underscore)}
    end
  end

  def get_posts
    service_uri   = "http://lam.lfn.net/LAMService/"

    @userId         = params[:userId].to_s
    @aspectId       = params[:aspectId].to_s
    @aspectContacts = params[:aspectContacts].to_s
    
    uri_string = service_uri + ('getPosts/%{userId}/%{aspectId}/%{aspectContacts}/' % params)
    return_xml = CGI.unescapeHTML(mediator(uri_string))
    # require 'rexml/document'
    # doc         = REXML::Document.new(CGI.unescapeHTML(@return_xml))
    # @return_xml = doc.elements[1].elements[1].to_s

    cxml_uri      = "http://cxml.lfn.net/internalposts.cxml"

    begin
      encoded_uri_string = URI.encode(cxml_uri)
      xml_val            = URI.encode(return_xml)
      params             = {'xml' => xml_val }
      response           = Net::HTTP.post_form(URI.parse(encoded_uri_string), {'xml'=>xml_val})
      # TODO remove the encoding header
      #uri = URI.parse(encoded_uri_string)
      #http = Net::HTTP.new(uri.host, uri.port)
      #request = Net::HTTP::Get.new(uri.path)
      #request.set_form_data( params )
      #request = Net::HTTP::Get.new( uri.path+ '?' + request.body )
      #response = http.request(request)
    rescue
    end
    cxml_call = encoded_uri_string + "?xml=" + xml_val
    logger.debug(encoded_uri_string)
    logger.debug(xml_val)
    logger.debug(response)
    response.nil? ? "EMPTY" : format_response(response.body)
  end

  #TODO refactor
  def format_response(response)
    response.gsub('<?xml version="1.0" encoding="utf-8"?>', '')
  end

  def get_new_posts
    service_uri   = "http://lam.lfn.net/LAMService/"
    "http://lam.lfn.net/LAMService/getNewPost/%{userId}/%{aspectId}/%{aspectContacts}/%{userInputs}/" % params
    # <diasporaUrl>/handler/getNewPost?
    # userId=<userId>&aspectId=<aspectId>&aspectContacts=<aspectContacts>&userInputs=<userInputs>
  end

  def load_params
    @userId         = params[:userId].to_s
    @aspectId       = params[:aspectId].to_s
    @aspectContacts = params[:aspectContacts].to_s
  end

  def mediator(uri_string)
    begin
      logger.debug("Before encode: " + uri_string)
      encoded_uri_string = uri_string
      logger.debug("After encode: " + encoded_uri_string)
      uri                = URI.parse(encoded_uri_string)
      http               = Net::HTTP.new(uri.host, uri.port)
      request            = Net::HTTP::Get.new(uri.path)
      response           = http.request(request)
      logger.debug(response.body)
    rescue
    end
    return (response.nil? ? "EMPTY" : response.body)
  end

end
