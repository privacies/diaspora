require 'spec_helper'

describe HandlerController do
  render_views
  before do
    @user = Factory :user
    sign_in :user, @user
  end
end
