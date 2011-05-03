class ThirdPartyUserToken < ActiveRecord::Base
  belongs_to :person
  validates_presence_of :value
  validates_uniqueness_of :value, :scope => :person_id
end
