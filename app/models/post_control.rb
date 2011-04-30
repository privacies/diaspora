class PostControl < ActiveRecord::Base
  belongs_to :status_message
  validates_associated :status_message_id, :unless => lambda {|pc| pc.status_message.try(:valid?)}
  validates_associated :status_message
  serialize :parameters

  before_save :filter_parameters, :if => :parameters_changed?

  def usable_for(user)
    @usable = true
    if parameters[:to_users]
      @usable &= parameters[:to_users].split(',').include?(user.diaspora_handle)
    else
      @usable &= ((parameters[:public] and parameters[:public].to_i == 1) || status_message.diaspora_handle == user.diaspora_handle)
    end
    @usable &= fresh?
  end

  #TODO refactor
  def to_json
    as_json(:only => [:parameters, :content])['post_control'].to_json
  end

  private

  def fresh?
    return true if !parameters[:freshness_condition] || !parameters[:token_date]
    (Time.now < (parameters[:token_date] + parameters[:freshness_condition].to_i.minutes))
  end

  def filter_parameters
    self.parameters[:freshness_condition] = parameters[:freshness_condition].to_i if parameters[:freshness_condition]
    self.parameters[:token_date] = Time.now if parameter_changed?(:token_date)
  end

  def parameter_changed?(key)
    previous_parameters, new_parameters = parameters_change
    new_parameters[:token] && previous_parameters.try('fetch', :token) != new_parameters[:token]
  end

end
