#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
require File.join(File.dirname(__FILE__), "..", "..", "spec", "helper_methods")

def set_app_config username
  current_config = YAML.load(File.read(Rails.root.join('config', 'app_config.yml.example')))
  current_config[Rails.env.to_s] ||= {}
  current_config[Rails.env.to_s]['pod_url'] ||= "#{username}.joindiaspora.com"
  current_config['default']['pod_url'] ||= "#{username}.joindiaspora.com"
  file = File.new(Rails.root.join('config','app_config.yml'),'w')
  file.write(current_config.to_yaml)
  file.close
end

username = "lfn"
set_app_config username unless File.exists?(Rails.root.join('config', 'app_config.yml'))

require Rails.root.join('config',  "initializers", "_load_app_config.rb")
include HelperMethods
module Resque
  def enqueue(klass, *args)
    if $process_queue
      klass.send(:perform, *args)
    else
      true
    end
  end
end
# Create seed user
user = User.build( :email => "e@lfn.com",
                     :username => "lfn",
                    :password => "lfnadmin",
                    :password_confirmation => "lfnadmin",
                    :person => {
                      :profile => { :first_name => "LFN", :last_name => "Admin",
                      :image_url => "/images/user/tom.jpg"}})

user.save!
user.person.save!
user.seed_aspects

user2 = User.build( :email => "jrichardlai+diaspora@gmail.com",
                    :password => "lfnadmin",
                    :password_confirmation => "lfnadmin",
                     :username => "jrichardlai",
                    :person => {:profile => { :first_name => "Test", :last_name => "name",
                      :image_url => "/images/user/korth.jpg"}})


user2.save!
user2.person.save!
user2.seed_aspects
# connecting users

connect_users(user, user.aspects.first, user2, user2.aspects.first)
