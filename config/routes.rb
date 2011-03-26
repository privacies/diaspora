#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

Diaspora::Application.routes.draw do

  # TODO make it generic
  match "handler/:third_party_service/:call", :to => 'handler#call'
  match "handler/lfn/:file.:format" => 'handler#call', :call => 'forward', :constraints => { :file => /.*/, :format => /(jpg)|(dzc)|(dzi)/ }
  match "handler/:call", :to => 'handler#call'

  post "mediator/invoke", :to => 'handler#invoke'

  match "api/:request", :to => 'api#call', :defaults => { :format => 'json' }

  resources :status_messages, :only => [:new, :create, :destroy, :show]
  resources :comments,        :only => [:create, :destroy]
  resources :requests,        :only => [:destroy, :create]
  resource :likes,            :only => [:create]

  # Posting and Reading

  resources :aspects do
    collection do
      match 'move_contact'       => :move_contact
      match 'add_to_aspect'      => :add_to_aspect
      match 'remove_from_aspect' => :remove_from_aspect
      match 'manage'             => :manage
    end
    match 'toggle_contact_visibility' => :toggle_contact_visibility
  end

  resources :status_messages, :only => [:new, :create, :destroy, :show]
  get 'p/:id' => 'posts#show', :as => 'post'

  match 'photos/make_profile_photo' => 'photos#make_profile_photo'
  resources :photos, :except => [:index]

  resources :comments, :only => [:create, :destroy]

  get 'tags/:name' => 'tags#show', :as => 'tag'

  resource :like, :only => [:create]

  resources :conversations do
    resources :messages, :only => [:create, :show]
    delete 'visibility' => 'conversation_visibilities#destroy'
  end

  resources :notifications, :only => [:index, :update] do
    get 'read_all' => :read_all, :on => :collection
  end


  # Users and people

  resource :user, :only => [:edit, :update, :destroy], :shallow => true do
    get :export
    get :export_photos
  end

  controller :users do
    get 'public/:username'          => :public,          :as => 'users_public'
    match 'getting_started'         => :getting_started, :as => 'getting_started'
    get 'getting_started_completed' => :getting_started_completed
  end

  # This is a hack to overide a route created by devise.
  # I couldn't find anything in devise to skip that route, see Bug #961
  match 'users/edit' => redirect('/user/edit')

  devise_for :users, :controllers => {:registrations => "registrations",
                                      :password      => "devise/passwords",
                                      :sessions      => "sessions",
                                      :invitations   => "invitations"} do
    get 'invitations/resend/:id' => 'invitations#resend', :as => 'invitation_resend'
  end
  get 'login' => redirect('/users/sign_in')

  scope 'admins' do
    match 'user_search'   => 'admins#user_search'
    match 'admin_inviter' => 'admins#admin_inviter'
  end

  resource :profile

  resources :requests, :only => [:destroy, :create]

  resources :contacts, :except => [:index, :update]
  resources :aspect_memberships, :only => [:destroy, :create]

  resources :people, :except => [:edit, :update] do
    resources :status_messages
    resources :photos
  end
  match 'people/by_handle' => 'people#retrieve_remote', :as => 'person_by_handle'

  # route for third party services
  match 'tps/:action/:service_name', :to => 'third_party_services#:action', :as => :tps
  match 'update_tps_links', :to => 'third_party_services#update_links'

  match 'localize', :to => "localize#show"

  # Federation

  controller :publics do
    get 'webfinger'             => :webfinger
    get 'hcard/users/:guid'     => :hcard
    get '.well-known/host-meta' => :host_meta
    get 'receive/users/:guid'   => :receive
    get 'hub'                   => :hub
  end

  # External

  resources :services, :only => [:index, :destroy]
  controller :services do
    match '/auth/:provider/callback' => :create
    match '/auth/failure'            => :failure
    scope 'services' do
      match 'inviter/:provider' => :inviter, :as => 'service_inviter'
      match 'finder/:provider'  => :finder,  :as => 'friend_finder'
    end
  end

  scope 'api/v0', :controller => :apis do
    match 'statuses/public_timeline' => :public_timeline
    match 'statuses/home_timeline'   => :home_timeline
    match 'statuses/show/:guid'      => :statuses
    match 'statuses/user_timeline'   => :user_timeline

    match 'users/show'               => :users
    match 'users/search'             => :users_search
    match 'users/profile_image'      => :users_profile_image

    match 'tags_posts/:tag'          => :tag_posts
    match 'tags_people/:tag'         => :tag_people
  end


  # Mobile site
  match 'mobile/toggle', :to => 'home#toggle_mobile', :as => 'toggle_mobile'


  # Startpage

  root :to => 'home#show'
end
