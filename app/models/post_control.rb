class PostControl < ActiveRecord::Base
  belongs_to :status_message
  validates_associated :status_message_id, :unless => lambda {|pc| pc.status_message.try(:valid?)}
  validates_associated :status_message
  validates_presence_of :content
end
