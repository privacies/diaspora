#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

Diaspora::Application.routes.draw do

  # TODO make it generic
  # match "handler/:uic/:request", :to => 'handler#call'
  match "handler/:third_party_service/:call", :to => 'handler#call'
  match "handler/lfn/:file.:format" => 'handler#call', :call => 'forward', :constraints => { :file => /.*/, :format => /(jpg)|(dzc)|(dzi)/ }
  match "handler/:call", :to => 'handler#call'

  post "mediator/invoke", :to => 'handler#invoke'

  match "api/:request", :to => 'api#call', :defaults => { :format => 'json' }

  resources :status_messages, :only => [:create, :destroy, :show]
  resources :comments,        :only => [:create]
  resources :requests,        :only => [:destroy, :create]

  resource :profile
  match 'services/inviter/:provider' => 'services#inviter', :as => 'service_inviter'
  match 'services/finder/:provider' => 'services#finder', :as => 'friend_finder'
  resources :services

  match 'admins/user_search' => 'admins#user_search'
  match 'admins/admin_inviter' => 'admins#admin_inviter'

  match 'notifications/read_all' => 'notifications#read_all'
  resources :notifications,   :only => [:index, :update]
  resources :posts,           :only => [:show], :path => '/p/'

  resources :contacts
  resources :aspect_memberships, :only => [:destroy, :create]


  resources :conversations do
    resources :messages, :only => [:create, :show]
    resource :conversation_visibility, :only => [:destroy], :path => '/visibility/'
  end

  resources :people, :except => [:edit, :update] do
    resources :status_messages
    resources :photos
  end

  match '/people/by_handle' => 'people#retrieve_remote', :as => 'person_by_handle'
  match '/auth/:provider/callback' => 'services#create'
  match '/auth/failure' => 'services#failure'

  match 'photos/make_profile_photo' => 'photos#make_profile_photo'
  resources :photos, :except => [:index]

  devise_for :users, :controllers => {:registrations => "registrations",
                                      :password      => "devise/passwords",
                                      :invitations   => "invitations"} do

    get 'invitations/resend/:id' => 'invitations#resend', :as => 'invitation_resend'
                                      end


  # added public route to user
  match 'public/:username',          :to => 'users#public'
  match 'getting_started',           :to => 'users#getting_started', :as => 'getting_started'
  match 'getting_started_completed', :to => 'users#getting_started_completed'
  match 'users/export',              :to => 'users#export'
  match 'users/export_photos',       :to => 'users#export_photos'
  match 'login'                      => redirect('/users/sign_in')
  resources :users,                  :except => [:create, :new, :show]

  match 'aspects/move_contact',      :to => 'aspects#move_contact', :as => 'move_contact'
  match 'aspects/add_to_aspect',     :to => 'aspects#add_to_aspect', :as => 'add_to_aspect'
  match 'aspects/remove_from_aspect',:to => 'aspects#remove_from_aspect', :as => 'remove_from_aspect'
  match 'aspects/manage',            :to => 'aspects#manage'
  match 'aspects/lfn',               :to => 'aspects#lfn'
  resources :aspects

  #public routes
  match 'webfinger',            :to => 'publics#webfinger'
  match 'hcard/users/:guid',      :to => 'publics#hcard'
  match '.well-known/host-meta',:to => 'publics#host_meta'
  match 'receive/users/:guid',    :to => 'publics#receive'
  match 'hub',                  :to => 'publics#hub'

  # route for uicomponnents
  match 'uic/:action/:ui_component', :to => 'user_interface_components#:action', :as => :uic
  match 'update_uic_links', :to => 'user_interface_components#update_links'

  match 'localize', :to => "localize#show"
  match 'mobile/toggle', :to => 'home#toggle_mobile', :as => 'toggle_mobile'
  #root
  root :to => 'home#show'
end
