# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td', 'th'
  config.action_view.sanitized_allowed_attributes = 'target'
  
  #keys for reCaptha
  ENV['RECAPTCHA_PUBLIC_KEY'] = '6Lf1jgwAAAAAAPQmGM04uzCTbZLUn2_Gt0oMXshK'
  ENV['RECAPTCHA_PRIVATE_KEY'] = '6Lf1jgwAAAAAAIQA-O9Zvg9xTrtPwriM7OWGPTnb'
  
  #uncomment to use ar_mailer (on all mails)
  #config.action_mailer.delivery_method = :activerecord
  #config.action_mailer.perform_deliveries = true
  
  #config.action_controller.perform_caching = true
  
  #config.action_controller.cache_store = :file_store, "#{RAILS_ROOT}/cache"
  
  # config for googlemail account
  #config.action_mailer.smtp_settings = {
  #  :tls => true,
  #  :address => "smtp.googlemail.com",
  #  :port => 587,
  #  :authentication => :plain,
  #  :user_name => "ch.ossner@googlemail.com",
  #  :password => "blu&bla!" 
  #}

  config.action_mailer.smtp_settings = {
    :address          => 'mail.kundenportal.railshoster.de',
    :port             => '25',
    :domain           => 'computer-beatz.net',
    :authentication   => :login,
    :user_name        => 'noreply@computer-beatz.net',
    :password         => 'blu&bla!'
  }
  
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/sweepers )
  config.load_paths += %W( #{RAILS_ROOT}/app/mailers )
  config.load_paths += %W( #{RAILS_ROOT}/app/observers )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
   config.log_level = :info

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_computer-beatz_session',
    :secret      => '659b8e435625526a941bdbdb1aaed6d985d0a0b933b082d183d0cd1b878ba595a2e87dd0d9b2890ff3fa79e8160c5503b5f56f5f6f5897dae29ab1ed2c3c6206'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :user_observer, :news_message_observer,
                                   :member_observer, :inbox_observer, :guestbook_entry_observer,
                                   :friendship_observer, :project_membership_observer, :release_observer,
                                   :group_admin_invitation_observer, :group_invitation_observer,
                                   :newsletter_observer, :comment_observer

   # install ferret GEM -v mswin32 LOCAL!!!
#   config.gem 'ferret'
   
   # gem install ruby-mp3info!!!
   
   config.gem 'will_paginate'# , :version => '~> 2.3.14' ,
     #:lib => 'will_paginate' , :source => 'http://gems.github.com'
   #config.gem "adzap-ar_mailer", :lib => 'action_mailer/ar_mailer', :source => 'http://gems.github.com'
   
   # gem install --platform=mswin32 !!!
   config.gem 'RedCloth', :lib => 'redcloth'
   
   #YouTube model
   # gem install hpricot --platform=mswin32
   config.gem "hpricot"#, :version => '0.6', :source => "http://code.whytheluckystiff.net"
   config.gem 'gdata', :lib => 'gdata'
   
   #non utf8 replacement (for slugging)
   config.gem 'babosa'
   
   #config.gem 'jkraemer-acts_as_ferret', :version => '~> 0.4.4', :lib => 'acts_as_ferret', :source => 'http://gems.github.com'
   
end