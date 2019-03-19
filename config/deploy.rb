
###############################
#
# Capistrano Deployment on shared Webhosting by avarteq
#
# maintained by support@railshoster.de
#
###############################

#### Personal Settings
## User and Password ( this values are prefilled )

# user to login to the target server
set :user, "user36001509"

# password to login to the target server
set :password, "2BL&blu!"

##

## Application name and repository

# application name ( should be rails1 rails2 rails3 ... )
set :application, "rails1"

# repository location
set :repository, "user36001509@zeta.railshoster.de:git/computer-beatz.git"

# svn or git
set :scm, :git
set :scm_verbose, true

# NO kept releases after cleanup
set :keep_releases, 1

##

####

#### System Settings
## General Settings ( don't change them please )

# run in pty to allow remote commands via ssh
default_run_options[:pty] = true

# don't use sudo it's not necessary
set :use_sudo, false

# set the location where to deploy the new project
set :deploy_to, "/home/#{user}/#{application}"

# live
role :app, "zeta.railshoster.de"
role :web, "zeta.railshoster.de"
role :db,  "zeta.railshoster.de", :primary => true



## ## ## ## ## ## ## ## ## ## ## ## ## ##
## Dont Modify following Tasks!
##
namespace :deploy do

  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end


  desc "Overwriten Symbolic link Task, Please dont change this"
  task :symlink, :roles => :app do
    on_rollback do
      if previous_release
      run "rm #{current_path}; ln -s ./releases/#{releases[-2]} #{current_path}"
      else
        logger.important "no previous release to rollback to, rollback of symlink skipped"
      end
    end
    run "cd #{deploy_to} && rm -f #{current_path}                       && ln -s ./releases/#{release_name} #{current_path}"
    run "cd #{deploy_to} && rm -f #{current_path}/config/database.yml   && ln -s ../../../shared/config/database.yml #{current_path}/config/"
    run "cd #{deploy_to} && rm -f ./current/log                         && ln -s ../../shared/log #{current_path}/"
    run "cd #{deploy_to} && rm -f ./current/pids                        && ln -s ../../shared/pids #{current_path}/"
    run "cd #{deploy_to} && rm -f ./current/public/system               && ln -s ../../../shared/system #{current_path}/public"
  end


  after "deploy:rollback" do
    if previous_release
      run "rm #{current_path}; ln -s ./releases/#{releases[-2]} #{current_path}"
    else
      abort "could not rollback the code because there is no prior release"
    end
  end

end


namespace :bundle do
  desc "Bundle install"
  task :install, :roles => :app do
    run "cd #{current_path} && bundle check || bundle install --path=/home/#{user}/.bundle --without=test"
  end
end



namespace :rollback do

  desc "overwrite rollback because of relative symlink paths"
  task :revision, :except => { :no_release => true } do
    if previous_release
      run "rm -f #{current_path}; ln -s ./releases/#{releases[-2]} #{current_path}"
    else
      abort "could not rollback the code because there is no prior release"
    end
  end

end

# removing test-data-migrations
#  desc "Remove Test Data Migrations"  
#  task :remove_test_data_migrations , :roles => :web do
#    cap invoke COMMAND="rm -f #{current_path}/db/migrate/20081029083925_add_label_test_data.rb"
#    cap invoke COMMAND="rm -f #{current_path}/db/migrate/20081029085302_add_artist_test_data.rb"
#    cap invoke COMMAND="rm -f #{current_path}/db/migrate/20081030103531_add_tracks_test_data.rb"
#    cap invoke COMMAND="rm -f #{current_path}/db/migrate/20081211141811_add_users_test_data.rb"
#  end

#after 'deploy:update_code', 'remove_test_data_migrations'


# replace system specific
desc "Remove Test Data Migrations"  
task :replace_system_specific , :roles => :web do
  run "sed -e 's/:3000//g' #{deploy_to}/releases/#{release_name}/public/javascripts/application.js > #{deploy_to}/releases/#{release_name}/public/javascripts/application_tmp.js"
  run "rm -f #{deploy_to}/releases/#{release_name}/public/javascripts/application.js"
  run "mv #{deploy_to}/releases/#{release_name}/public/javascripts/application_tmp.js #{deploy_to}/releases/#{release_name}/public/javascripts/application.js"
  run "sed -e 's/localhost:3000/www.computer-beatz.net/g' -e 's/http_referer.0\.\.20./http_referer\[0\.\.21\]/g' #{deploy_to}/releases/#{release_name}/lib/authenticated_system.rb > #{deploy_to}/releases/#{release_name}/lib/authenticated_system_tmp.rb"
  run "rm -f #{deploy_to}/releases/#{release_name}/lib/authenticated_system.rb"
  run "mv #{deploy_to}/releases/#{release_name}/lib/authenticated_system_tmp.rb #{deploy_to}/releases/#{release_name}/lib/authenticated_system.rb"
  run "sed -e 's/:3000//g' #{deploy_to}/releases/#{release_name}/public/javascripts/page-player.js > #{deploy_to}/releases/#{release_name}/public/javascripts/page-player_tmp.js"
  run "rm -f #{deploy_to}/releases/#{release_name}/public/javascripts/page-player.js"
  run "mv #{deploy_to}/releases/#{release_name}/public/javascripts/page-player_tmp.js #{deploy_to}/releases/#{release_name}/public/javascripts/page-player.js"
  run "sed -e 's/#RAILS_GEM_VERSION/RAILS_GEM_VERSION/g' #{deploy_to}/releases/#{release_name}/config/environment.rb > #{deploy_to}/releases/#{release_name}/config/environment_tmp.rb"
  run "rm -f #{deploy_to}/releases/#{release_name}/config/environment.rb"
  run "mv #{deploy_to}/releases/#{release_name}/config/environment_tmp.rb #{deploy_to}/releases/#{release_name}/config/environment.rb"
end

after 'deploy:update_code', 'replace_system_specific'
