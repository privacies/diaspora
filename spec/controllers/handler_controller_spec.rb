require 'spec_helper'

describe HandlerController do

  describe "GET 'getPosts'" do
    it "should be successful" do
      get 'getPosts'
      response.should be_success
    end
  end

end
