#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Aspect < ActiveRecord::Base
  belongs_to :user

  has_many :aspect_memberships
  has_many :contacts, :through => :aspect_memberships

  has_many :post_visibilities
  has_many :posts, :through => :post_visibilities

  validates_presence_of :name
  validates_length_of :name, :maximum => 20
  validates_uniqueness_of :name, :scope => :user_id, :case_sensitive => false

  attr_accessible :name

  before_validation do
    name.strip!
  end

  def has_post? post
    post_ids = post_visibilities.each { |pv| pv.post_id }
    post_ids.each { |id|
      return true if id == post.id
    }
    return false
  end

  def to_s
    name
  end

  def to_api_json
    {:id => id, :name => name}
  end

end

