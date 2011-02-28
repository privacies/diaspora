class UserInterfaceComponentsController < ApplicationController

  def load
    @user_interface_component = UserInterfaceComponent::get(params[:ui_component])
    render @user_interface_component.to_s.downcase
  end

end