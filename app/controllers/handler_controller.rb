class HandlerController < ApplicationController

  before_filter :authenticate_user!
  
  layout false

  def call
    begin
      #call the third party service
      if params[:third_party_service]
        if @service = UserInterfaceComponent::get(params[:third_party_service])
          service_response = @service::send(params[:call], params)
        end
      #call methods of the handler controller
      else
        service_response = send(params[:call])
      end
    rescue Exception => e
      logger.error("Handler controller, in call : #{params.to_yaml} #{e} #{e.backtrace}")
    end
    render :text => service_response
  end

  def invoke
    render :text => UserInterfaceComponent::invoke_3rd_party_service(params)
  end

end
