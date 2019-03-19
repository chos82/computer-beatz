ActionController::Routing::Routes.draw do |map|
  map.resources :news

  map.resources :newsletter, :only => [:index, :show]
  map.paged_newsletter 'newsletter/pages/:page', :controller => :newsletter
  
  map.resources :privacy_policy, :only => [:index]
  map.resources :terms, :only => [:index]
  map.resources :faq, :only => [:index]
  map.resources :about, :only => [:index]
  map.resources :player, :only => [:project, :single, :all], :collection => {:all => :get},
                                      :member => {:project => :get, :single => :get}
  map.resources :releases, :except => [:create, :new], :member => {:make_favourite => :put,
                                    :remove_from_favourites => :delete,
                                    :add_comment => :post, :favourized_by => :get,
                                    :member => :get, :cover => :get,
                                    :preview => :get,
                                    :delete_comment => :delete}
  map.paged_releases 'releases/pages/:page', :controller => :releases

  map.resources :projects, :except => [:destroy], :member => {:invite => :get,
                                                              :audio => :get, :logo => :get,
                                                               :delete_comment => :delete,
                                                               :pending => :get},
                                                  :collection => [:auto_complete_reciever] do |project|
    project.resources :releases, :only => [:create, :new]
  end
  map.paged_projects 'projects/pages:page', :controller => :projects

  map.resources :project_memberships, :only => [:destroy], :member => {:accept => :put}
  
  map.resources :invitations, :only => [:destroy], :member => {:accept => :delete},
                              :collection => {:groups => :get, :friendships => :get, :administration => :get}
                                  
  map.resources :groups, :collection => {:search => [:post, :get],
                                         :auto_complete_search => [:get],
                                         :auto_complete_reciever => :get},
                         :member => {:give_away_form => :get,
                                     :give_away => :post} do |group|
    group.resources :topics, :except => [:edit] do |topic|
      topic.resources :news_messages, :except => [:show]
    end
    group.resources :members, :except => [:show], :collection => {:pending => :get},
                              :member => {:decline => :put, :approve => :put, :cancel => :put}
  end
  map.paged_groups 'groups/pages/:page', :controller => :groups
  map.paged_group_topics 'groups/:id/topics/pages/:page', :controller => :topics
  
  map.resources :static, :only => [], :collection => {:textile => :get}
  
  map.resources :preview, :only => [], :collection => {:redcloth => [:post]}
  
  map.root :controller => 'home'
  
  map.resources :messages, :only => [:reply, :send_reply],
                              :member => {:reply => :get, :send_reply => [:post]},
                              :collection => {:compose => :get,
                                              :send_composed => :post,
                                              :auto_complete_reciever => :get,
                                              :check_reciever => :post}
  
  map.resources :users, :collection => {:auto_complete_search => :get,
                                        :search => [:post, :get],
                                        :advanced_search => [:post, :get],
                                        :advanced_form => :get,
                                        :auto_complete_login => :get,
                                        :forbidden => :get},
                        :member => {:favourites => :get, :tagged => :get, :cancel => :get, :tag => :get, :tags => :get} do |users|
    users.resources :guestbook_entries, :only =>[:create, :destroy]
    users.resources :memberships, :only => [:index]
    users.resource :account, :only => [:edit, :show, :update]
    users.resources :group_admin_invitations, :only => [:destroy], :member => {:accept => :delete}
    users.resources :friendships, :except => [:edit, :show, :update],
                                  :member => {:accepting => :get, :accept => :get, :decline => :delete},
                                  :collection => {:requested => :get}
    users.resource :messages, :only => [:create, :new]
    users.resources :invitations, :only => [:new, :create, :show]
  end
  map.inbox_index ':id/inbox', :controller => :inbox
  map.paged_inbox ':id/inbox/pages/:page', :controller => :inbox
  map.inbox ':user_id/inbox/:id', :controller => :inbox, :action => :destroy, :conditions => {:method => :delete}
  map.inbox ':user_id/inbox/:id', :controller => :inbox, :action => :show
  map.delete_all_inbox ':id/inbox', :controller => :inbox, :action => :delete_all, :conditions => {:method => :delete}
  map.read_inbox ':user_id/inbox/:id/read', :controller => :inbox, :action => :read, :conditions => {:method => :put}
  map.outbox_index ':id/outbox', :controller => :outbox
  map.paged_outbox ':id/outbox/pages/:page', :controller => :outbox
  map.outbox ':user_id/outbox/:id', :controller => :outbox, :action => :destroy, :conditions => {:method => :delete}
  map.outbox ':user_id/outbox/:id', :controller => :outbox, :action => :show
  map.delete_all_outbox ':id/outbox', :controller => :outbox, :action => :delete_all, :conditions => {:method => :delete}
  
  map.resource :session, :only => [:create, :destroy, :new]
  map.resource :password, :except => [:index, :show, :destroy]

  map.activate '/activate/:id', :controller => 'accounts', :action => 'show'
  
  map.advert '/advert', :controller => 'advert'
  
  map.myprojects '/:id/myprojects', :controller => 'users', :action => 'myprojects' 
  map.myinvitations '/:id/myinvitations', :controller => 'invitations', :action => 'index' 
  map.myaccount '/:id/myaccount', :controller => 'users', :action => 'edit' 
  map.mygroups '/:id/mygroups', :controller => 'memberships', :action => 'mygroups'
  map.myfriends '/:id/myfriends', :controller => 'friendships', :action => 'myfriends'
  map.myfavourites '/:id/myfavourites', :controller => 'users', :action => 'myfavourites'
  map.mytag '/:id/mytag/:tag', :controller => 'users', :action => 'mytag'
  map.mytags '/:id/mytags', :controller => 'users', :action => 'mytags'
  map.mytaggings '/:id/mytaggings', :controller => 'users', :action => 'mytaggings'
  map.myprofile '/:id/myprofile', :controller => 'users', :action => 'myprofile'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.forgot_password '/forgot_password', :controller => 'passwords', :action => 'new'
  map.reset_password '/reset_password/:id', :controller => 'passwords', :action => 'edit'
  map.change_password '/change_password', :controller => 'accounts', :action => 'edit'
  
  map.tagged_by_user 'users/:id/tag/:tag', :controller => :users, :action => :tag
  
  map.paged_mytaggings '/:id/mytaggings/pages/:page', :controller => 'users', :action => 'mytaggings'
  map.paged_mytag '/:id/mytag/:tag/pages/:page', :controller => 'users', :action => 'mytag'
  map.paged_myfavourites '/:id/myfavourites/pages/:page', :controller => 'users', :action => 'myfavourites'
  map.paged_myfriends '/:id/myfriends/pages/:page', :controller => 'friendships', :action => 'myfriends'
  map.paged_mygroups '/:id/mygroups/pages/:page', :controller => 'memberships', :action => 'mygroups'
  map.paged_myprofile '/:id/myprofile/pages/:page', :controller => 'users', :action => 'myprofile'
  map.paged_users_show '/users/:id/pages/:page', :controller => 'users', :action => 'show'
  map.paged_users '/users/pages/:page', :controller => 'users', :action => 'show'
  map.paged_myprojects '/:id/myprojects/pages/:page', :controller => 'users', :action => 'myprojects'
  map.paged_music   '/music/pages/:page', :controller => 'music', :action => :index
  
  map.namespace :admin do |admin|
    admin.resources :users, :member => { :enable => :put, :remove => :delete } do |users|
      users.resources :roles
    end    
    admin.resources :roles
    admin.resources :music, :collection => {:reported_entries => :get}
    admin.resources :artists
    admin.resources :albums
    admin.resources :mixes
    admin.resources :labels
    admin.resources :tracks
    admin.resources :comments
    admin.resources :groups
    admin.resources :releases, :only => [:index], :member => {:publish => :put, :decline => :post, :new_decline => :get}
    admin.resources :newsletter
    admin.root :controller => 'home'
  end
  
  map.resources :music, :only => [:index, :make_favourite, :remove_from_favourites, :add_comment, :manage_tags, :post_tags],
                        :collection => {:auto_complete_search => :get,
                                        :auto_complete_tags => :get,
                                        :advanced_form => :get,
                                        :auto_complete_label => :get,
                                        :auto_complete_artist => :get,
                                        :auto_complete_track => :get,
                                        :auto_complete_album => :get,
                                        :auto_complete_mix => :get,
                                        :auto_complete_tag_search => :get,
                                        :search => [:post, :get],
                                        :advanced_search => [:post, :get],
                                        :tags => :get},
                        :member => {:make_favourite => :put,
                                    :remove_from_favourites => :delete,
                                    :add_comment => :post, :manage_tags => :get, :post_tags => :post,
                                    :taggers => :get,
                                    :edit_tags => :get,
                                    :favourized_by => :get},
                        :has_many => [:similar] do |mus|
    mus.resource :report, :only => [:new, :create]
  end
                        
  map.resources :report, :only => [], :member => {:comment => :post}
  
  # as comments should be moved to a controller this might be helpful once.. map.resources :comments#, :has_one => [:report]
  
  map.resources :labels, :collection => {:auto_complete_for_label_name => :get, :tags => :get}, 
                          :member => { :set_license => :get, :tracks => :get, :albums => :get, :mixes => :get, :artists => :get}
                          
  map.resources :artists, :collection => {:auto_complete_for_artist_name => :get, :tags => :get},
                          :member => {:tracks => :get, :albums => :get, :mixes => :get, :labels => :get}
  
  map.resources :tracks, :collection => {:auto_complete_for_track_name => :get, :tags => :get}
  
  map.resources :albums, :collection => {:auto_complete_for_album_name => :get, :tags => :get}
  
  map.resources :mixes, :collection => {:auto_complete_for_mix_name => :get, :tags => :get}
  
  map.sitemap 'feed.rss' , :controller => 'feed', :action => 'news'
  map.podcast 'podcast.rss', :controller => 'feed', :action => 'podcast'
  
  map.sitemap 'sitemap.xml', :controller => 'sitemap' , :action => 'sitemap'
  
  map.docnoize 'docnoize', :controller => :static, :action => :docnoize
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
