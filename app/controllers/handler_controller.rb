class HandlerController < ApplicationController

  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  layout false

  def call
    begin
      #call the third party service
      if params[:third_party_service]
        if @service = ThirdPartyService::get(params[:third_party_service])
          service_response = @service::send(params[:call].underscore, params)
        end
      #call methods of the handler controller
      else
        service_response = send(params[:call].underscore)
      end
    rescue Exception => e
      logger.error("Handler controller, in call : #{params.to_yaml} #{e} #{e.backtrace}")
    end
    render :text => service_response
  end

  def invoke
    render :text => ThirdPartyService::invoke(params)
  end

end
