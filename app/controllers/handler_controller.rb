class HandlerController < ApplicationController

  before_filter :load_params

  layout false

  def call
    respond_to do |format|
      format.xml { render :text => send(params[:request].underscore)}
    end
  end
  
  def forward
    uri      = URI.parse("http://cxml.lfn.net/" + params[:file] + "." + params[:format])
    logger.debug("Forward Handler TO #{uri} : #{(time = Time.now).to_s}")
    begin
      # response = Net::HTTP::get_response(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 120 # in seconds
      http.read_timeout = 120 # in seconds
      response = http.start() {|http|
        http.get(uri.path)
      }
    rescue Timeout::Error
      logger.debug("Timeout for #{uri} : #{Time.now - time}")
    end
    render :text => (response.nil? ? "EMPTY" : response.body)
  end

  def get_posts
    service_uri   = "http://lam.lfn.net/LAMService/"

    @userId         = params[:userId]
    @aspectId       = params[:aspectId]
    @aspectContacts = params[:aspectContacts].blank? ? UserInterfaceComponent::EMPTY_VALUE : params[:aspectContacts]

    uri_string = service_uri + ('getPosts/%{userId}/%{aspectId}/%{aspectContacts}/' % params)
    mediator_xml = mediator(uri_string)
    return_xml = CGI.unescapeHTML(mediator_xml)
    cxml_uri   = params[:subhandler].present? ? params[:subhandler] : "http://cxml.lfn.net/internalposts.cxml"

    begin
      encoded_uri_string = URI.encode(cxml_uri)
      xml_val            = URI.encode(return_xml)
      params             = {'xml' => xml_val }
      response           = Net::HTTP.post_form(URI.parse(encoded_uri_string), {'xml'=>xml_val})
    rescue
    end
    cxml_call = encoded_uri_string + "?xml=" + xml_val
    logger.debug(encoded_uri_string)
    logger.debug(xml_val)
    logger.debug(response)
    response.nil? ? "EMPTY" : format_response(response.body)
  end

  def format_response(response)
    response.gsub('<?xml version="1.0" encoding="utf-8"?>', '')
  end

  def get_new_posts
    service_uri = "http://lam.lfn.net/LAMService/"

    @userId         = params[:userId]
    @aspectId       = params[:aspectId]
    @aspectContacts = params[:aspectContacts]
    @userInputs     = params[:userInputs].blank? ? UserInterfaceComponent::EMPTY_VALUE : params[:userInputs]

    uri_string  = service_uri + "getNewPost/%{userId}/%{aspectId}/%{aspectContacts}/%{userInputs}/" % params
    render :text => CGI.unescapeHTML(mediator(uri_string))
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
      uri      = URI.parse(encoded_uri_string)
      response = Net::HTTP::get_response(uri)
      logger.debug(response.body)
    rescue
    end
    return (response.nil? ? "EMPTY" : response.body)
  end

end
