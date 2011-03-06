class UserInterfaceComponentsController < ApplicationController

  def load
    @user_interface_component = UserInterfaceComponent::get(params[:ui_component])
    render @user_interface_component.to_s.downcase
  end

  def update_links
    @aspect_ids = params[:aspect_ids]
    respond_to do |format|
      format.js
    end
  end

end