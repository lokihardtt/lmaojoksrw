require "bundler/capistrano"
require "rvm/capistrano"
require "whenever/capistrano"

server "45.55.216.62", :web, :app, :db, primary: true

set :application, "openfreemarket"
set :user, "developer"
set :port, 22
set :deploy_to, "/home/#{user}/Application/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false
set :shared_children, shared_children + %w{public/assets public/uploads public/pgp}

set :scm, "git"
set :repository, "git@gitlab.com:stevez00/openfreemarket.git"
set :branch, "master"
set :rvm_ruby_string, '2.1.2'

set :max_asset_age, 2

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases
after "deploy:finalize_update", "deploy:assets:determine_modified_assets", "deploy:assets:conditionally_precompile"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    # sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    # run "ln -nfs #{shared_path}/config/Procfile #{release_path}/Procfile"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit #{shared_path}/config/database.yml and add your username and password"
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  task :symlink_uploads do
    run "ln -nfs #{shared_path}/uploads  #{release_path}/public/uploads"
  end
  after 'deploy:update_code', 'deploy:symlink_uploads'

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"

  namespace :assets do
    desc "Figure out modified assets."
    task :determine_modified_assets, :roles => assets_role, :except => { :no_release => true } do
      set :updated_assets, capture("find #{latest_release}/app/assets -type d -name .git -prune -o -mmin -#{max_asset_age} -type f -print", :except => { :no_release => true }).split
    end

    desc "Remove callback for asset precompiling unless assets were updated in most recent git commit."
    task :conditionally_precompile, :roles => assets_role, :except => { :no_release => true } do
      if(updated_assets.empty?)
        callback = callbacks[:after].find{|c| c.source == "deploy:assets:precompile" }
        callbacks[:after].delete(callback)
        logger.info("Skipping asset precompiling, no updated assets.")
      else
        logger.info("#{updated_assets.length} updated assets. Will precompile.")
      end
    end
  end
end

namespace :migration do
  task :migrate do
    run "cd #{current_path}; bundle exec rake db:migrate RAILS_ENV=production"
  end

  task :seed do
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=production"
  end
end

namespace :database do 
  task :create do
    run "cd #{current_path}; bundle exec rake db:create"
  end

  task :drop do 
    run "cd #{current_path}; bundle exec rake db:drop"
  end
end