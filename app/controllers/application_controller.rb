#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class ApplicationController < ActionController::Base
  has_mobile_fu
  protect_from_forgery :except => :receive

  before_filter :set_contacts_notifications_and_status, :except => [:create, :update]
  before_filter :count_requests
  before_filter :set_invites
  before_filter :set_locale
  before_filter :which_action_and_user

  def set_contacts_notifications_and_status
    if user_signed_in? 
      @aspect = nil
      @aspects = current_user.aspects.fields(:name)
      @aspects_dropdown_array = @aspects.collect{|x| [x.to_s, x.id]}
      @notification_count = Notification.for(current_user, :unread =>true).all.count
    end
  end
  
  def mobile_except_ipad
    if is_mobile_device?
      if request.env["HTTP_USER_AGENT"].include? "iPad"
        session[:mobile_view] = false
      else
        session[:mobile_view] = true
      end
    end
  end

  def count_requests
    @request_count = Request.to(current_user.person).count if current_user
  end

  def set_invites
    if user_signed_in?
      @invites = current_user.invites
    end
  end

  def which_action_and_user
    str = "controller=#{self.class} action=#{self.action_name} "
    if current_user
      str << "uid=#{current_user.id}"
    else
      str << 'uid=nil'
    end
    Rails.logger.info str
  end

  def set_locale
    if user_signed_in?
      I18n.locale = current_user.language
    else
      I18n.locale = request.compatible_language_from AVAILABLE_LANGUAGE_CODES
    end
  end

  def get_javascript_strings_for(language)
    Il8n.t('javascripts').to_json
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
end
  
  
end
