class ApiController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json
  respond_to :xml
  
  def call
    @action = params[:request].underscore
    head 404 and return unless respond_to?(@action)
    send(@action)
  end

  def get_all_users
    render_collection User.all
  end

  def get_all_aspects
    render_collection current_user.aspects
  end

  def get_all_aspect_contacts
    if params[:aspect_id].present? and params[:aspect_id].to_i != 0
      aspect_contacts = current_user.contacts.joins(:aspect_memberships).where(:aspect_memberships => {:aspect_id => params[:aspect_id]})
    else
      aspect_contacts = current_user.contacts
    end
    render_collection aspect_contacts.collect(&:user)
  end

  protected

  def render_collection(collection)
    respond_to do |format|
      format.xml  { render :xml => collection.map(&:to_api_json).to_xml }
      format.json { render :json => collection.map(&:to_api_json) }
    end
  end

end