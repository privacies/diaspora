#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class StatusMessage < Post
  include Diaspora::Socketable
  include Diaspora::Taggable

  include YoutubeTitles
  require File.join(Rails.root, 'lib/youtube_titles')
  include ActionView::Helpers::TextHelper

  acts_as_taggable_on :tags
  extract_tags_from :raw_message

  validates_length_of :text, :maximum => 1000, :text => "please make your status messages less than 1000 characters"
  xml_name :status_message
  xml_attr :raw_message
  xml_attr :post_control

  has_many :photos, :dependent => :destroy
  has_one  :control, :dependent => :destroy, :class_name => 'PostControl'
  accepts_nested_attributes_for :control, :allow_destroy => true

  validate :message_or_photos_present?

  alias_attribute :message, :text

  attr_accessible :text, :message, :control, :control_attributes

  serialize :youtube_titles, Hash
  before_save do
    get_youtube_title text
  end

  before_create :build_tags

  def text(opts = {})
    self.formatted_message(opts)
  end

  def post_control
    respond_to?(:control) && control ? control.try(:to_json) : ''
  end

  #MERGE attributes json
  def post_control=(text)
    if respond_to?(:control) and !text.blank?
      attributes = ActiveSupport::JSON.decode(text)
      if control
        #test if it works
        self.control.attributes = attributes
      else
        self.build_control(attributes)
      end
    end
  end

  def raw_message
    read_attribute(:text)
  end
  def raw_message=(text)
    write_attribute(:text, text)
  end

  def formatted_message(opts={})
    return self.raw_message unless self.raw_message

    escaped_message = opts[:plain_text] ? self.raw_message: ERB::Util.h(self.raw_message)
    mentioned_message = self.format_mentions(escaped_message, opts)
    self.format_tags(mentioned_message, opts)
  end

  def format_mentions(text, opts = {})
    people = self.mentioned_people
    regex = /@\{([^;]+); ([^\}]+)\}/
    form_message = text.gsub(regex) do |matched_string|
      person = people.detect{ |p|
        p.diaspora_handle == $~[2] unless p.nil?
      }

      if opts[:plain_text]
        person ? ERB::Util.h(person.name) : ERB::Util.h($~[1])
      else
        person ? "<a href=\"/people/#{person.id}\" class=\"mention\">@#{ERB::Util.h(person.name)}</a>" : ERB::Util.h($~[1])
      end
    end
    form_message
  end

  def mentioned_people
    if self.persisted?
      create_mentions if self.mentions.empty?
      self.mentions.includes(:person => :profile).map{ |mention| mention.person }
    else
      mentioned_people_from_string
    end
  end

  def create_mentions
    mentioned_people_from_string.each do |person|
      self.mentions.create(:person => person)
    end
  end

  def mentions?(person)
    mentioned_people.include? person
  end

  def notify_person(person)
    self.mentions.where(:person_id => person.id).first.try(:notify_recipient)
  end

  def mentioned_people_from_string
    regex = /@\{([^;]+); ([^\}]+)\}/
    identifiers = self.raw_message.scan(regex).map do |match|
      match.last
    end
    identifiers.empty? ? [] : Person.where(:diaspora_handle => identifiers)
  end

  def to_activity
    <<-XML
  <entry>
    <title>#{x(self.formatted_message(:plain_text => true))}</title>
    <content>#{x(self.formatted_message(:plain_text => true))}</content>
    <link rel="alternate" type="text/html" href="#{self.author.url}p/#{self.id}"/>
    <id>#{self.author.url}p/#{self.id}</id>
    <published>#{self.created_at.xmlschema}</published>
    <updated>#{self.updated_at.xmlschema}</updated>
    <activity:verb>http://activitystrea.ms/schema/1.0/post</activity:verb>
    <activity:object-type>http://activitystrea.ms/schema/1.0/note</activity:object-type>
  </entry>
      XML
  end

  def as_json(opts={})
    opts ||= {}
    if(opts[:format] == :twitter)
      {
        :id => self.guid,
        :text => self.formatted_message(:plain_text => true),
        :entities => {
            :urls => [],
            :hashtags => self.tag_list,
            :user_mentions => self.mentioned_people.map{|p| p.diaspora_handle},
          },
        :source => 'diaspora',
        :created_at => self.created_at,
        :user => self.author.as_json(opts)
      }
    else
      super(opts)
    end
  end

  def socket_to_user(user_or_id, opts={})
    unless opts[:aspect_ids]
      user_id = user_or_id.instance_of?(Fixnum) ? user_or_id : user_or_id.id
      aspect_ids = AspectMembership.connection.execute(
        AspectMembership.joins(:contact).where(:contacts => {:user_id => user_id, :person_id => self.author_id}).select('aspect_memberships.aspect_id').to_sql
      ).map{|r| r.first}
      opts.merge!(:aspect_ids => aspect_ids)
    end
    super(user_or_id, opts)
  end

  protected

  def message_or_photos_present?
    if self.text.blank? && self.photos == []
      errors[:base] << 'Status message requires a message or at least one photo'
    end
  end
end

