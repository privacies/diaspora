class PostControl < ActiveRecord::Base
  belongs_to :status_message
  validates_presence_of :status_message_id
  validates_presence_of :content
end
