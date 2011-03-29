class PostControl < ActiveRecord::Base
  belongs_to :status_message
  validates_associated :status_message_id, :unless => lambda {|pc| pc.status_message.try(:valid?)}
  validates_associated :status_message
  serialize :parameters

  def usable_for(user)
    parameters.try(:public) or status_message.diaspora_handle == user.diaspora_handle
  end

  #TODO refactor
  def to_json
    as_json(:only => [:parameters, :content])['post_control'].to_json
  end
end
