class ThirdPartyUserToken < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :value
  validates_uniqueness_of :value, :scope => :user_id
end
