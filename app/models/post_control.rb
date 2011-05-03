class PostControl < ActiveRecord::Base
  belongs_to :status_message
  validates_associated :status_message_id, :unless => lambda {|pc| pc.status_message.try(:valid?)}
  validates_associated :status_message
  serialize :parameters

  before_save :filter_parameters, :if => :parameters_changed?

  def usable_for(user)
    @usable = true
    @usable &= valid_token?(user)
    @usable &= valid_user?(user)
    @usable &= fresh?
  end

  #TODO refactor
  def to_json
    as_json(:only => [:parameters, :content])['post_control'].to_json
  end

  private

  def valid_token?(user)
    return true unless parameters[:check_token]
    user.third_party_user_tokens.find_by_value(parameters[:check_token])
  end

  def valid_user?(user)
    return true unless parameters[:to_users]
    parameters[:to_users].split(',').include?(user.diaspora_handle)
  end

  def fresh?
    return true if !parameters[:freshness_condition] || !parameters[:token_date]
    (Time.now < (parameters[:token_date] + parameters[:freshness_condition].to_i.minutes))
  end

  def filter_parameters
    status_message.author.third_party_user_tokens.find_or_create_by_value(parameters[:token]) if parameters[:token]

    self.parameters[:freshness_condition] = parameters[:freshness_condition].to_i if parameters[:freshness_condition]
    self.parameters[:token_date] = Time.now if parameter_changed?(:token_date)
    true
  end

  def parameter_changed?(key)
    previous_parameters, new_parameters = parameters_change
    new_parameters[key] && previous_parameters.try('fetch', key) != new_parameters[key]
  end

end