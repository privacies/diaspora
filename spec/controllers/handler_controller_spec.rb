require 'spec_helper'

describe HandlerController do
  render_views
  before do
    @user = Factory :user
    sign_in :user, @user
  end

  describe "GET 'get_posts'" do
    it "should be successful" do
      get 'get_posts'
      response.should be_success
    end
  end

end
