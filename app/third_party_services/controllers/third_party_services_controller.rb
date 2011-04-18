class ThirdPartyServicesController < ApplicationController
  before_filter :authenticate_user!
  
  before_filter :load_aspect_ids

  def load
    @third_party_service = ThirdPartyService::get(params[:service_name])
    render @third_party_service.view_file
  end

  def update_links
    @aspect_ids = params[:aspect_ids]
    respond_to do |format|
      format.js
    end
  end

  private

  def load_aspect_ids
    if params[:aspect_ids] == 'all' || !params[:aspect_ids].present?
      @aspect     = :all
      @aspect_ids = current_user.aspect_ids
    else
      @aspect_ids = params[:aspect_ids].split(',')
    end

    if params[:aspect_ids] && params[:aspect_ids].is_a?(Array)
      @object_aspect_ids = params[:aspect_ids].map(&:to_i)
    else
      @object_aspect_ids = []
    end
  end

end
