class ThirdPartyServicesController < ApplicationController
  before_filter :authenticate_user!
  
  before_filter :load_aspect_ids

  def load
    @third_party_service = ThirdPartyService::get(params[:service])
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
    if params[:aspectId] == 'all'
      @aspect = :all
    elsif params[:aspect_ids].present?
      @object_aspect_ids = params[:aspect_ids]
    else
      @object_aspect_ids = params[:aspectId].split(',').map(&:to_i)
    end
  end

end
