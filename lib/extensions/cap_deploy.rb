# NOTE: to deploy a branch you need to do something like this:
# cap staging deploy --set-before branch=shakti-1.0-rc1 --set-before engine_branch=fluxx_engine-1.0-rc1 --set-before crm_branch=fluxx_crm-1.0-rc1 --set-before grant_branch=fluxx_grant-1.0-rc1 deploy:migrations

set :stages, %w(standalone staging production)
set :default_stage, 'standalone'
require 'capistrano/ext/multistage'

fluxx_application_name = FLUXX_APPLICATION_NAME
set :application, fluxx_application_name

set :user, "fluxx"
set :scm_user, Proc.new { Capistrano::CLI.ui.ask("Subversion user: ") }
set :scm_password, Proc.new { Capistrano::CLI.password_prompt("Subversion password for #{scm_user}: ") }
set :branch, (variables.include?(:branch) ? branch : 'master')
set :engine_branch, (variables.include?(:engine_branch) ? engine_branch : 'master')
set :crm_branch, (variables.include?(:crm_branch) ? crm_branch : 'master')
set :grant_branch, (variables.include?(:grant_branch) ? grant_branch : 'master')
set :deploy_via, :remote_cache

set :try_sudo, 'sudo'
set :use_sudo, false 

default_run_options[:pty] = true
set :repository,  "git@github.com:fluxxlabs/fluxx_#{fluxx_application_name}.git"
set :scm, "git"
set :git_enable_submodules, 1

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/fluxx/oss/#{application}"

require 'erb'

before "deploy:setup", :db
after "deploy:update_code", "db:symlink" 

before "bundle:install", "fluxx:checkout_gems"
after "deploy", "thinking_sphinx:index"
after "deploy:migrations", "thinking_sphinx:index"
after "deploy", "fluxx:reload_all_templates"
after "deploy:migrations", "fluxx:reload_all_templates"

namespace :uname do
  desc "Invoke uname on remote servers"
  task :default do
    run "uname -a"
  end
end

namespace :fluxx do
  
  desc "checkout fluxx_engine, fluxx_crm, fluxx_grant gems"
  task :checkout_gems do
    
    require 'capistrano/recipes/deploy/scm'
    require 'capistrano/recipes/deploy/strategy'
    [['fluxx_engine', 'git@github.com:solpath/fluxx_engine.git', engine_branch], 
     ['fluxx_crm', 'git@github.com:solpath/fluxx_crm.git', crm_branch], 
     ['fluxx_grant', 'git@github.com:solpath/fluxx_grant.git', grant_branch]].each do |gem_triplet|
      gem_name, gem_path, gem_branch = gem_triplet
      gem_cache = "#{gem_name}_cache"
      local_git = Capistrano::Deploy::SCM.new('git', {:repository => gem_path, :branch => gem_branch})

      git_revision = local_git.query_revision(gem_branch){ |cmd| with_env("LC_ALL", "C") { run_locally("cd ../#{gem_name}; #{cmd}") } }
      
      repo_cache = "#{shared_path}/#{gem_cache}"
      command = "if [ -d #{repo_cache} ]; then " +
        "#{local_git.sync(git_revision, repo_cache)}; " +
        "else #{local_git.checkout(git_revision, repo_cache)}; fi"
      run command
      
      # Copy the gem to the appropriate spot
      run "cp -RPp #{repo_cache} #{current_release}/#{gem_name}"  # && #{mark}"
    end
    
    # For the Gemfile.lock, we need to alter it to contain the gems inside
    randnum = rand(9999999)
    run "sed 's/remote: \\.\\.\\/fluxx_/remote: \\.\\/fluxx_/g' #{current_release}/Gemfile.lock > /tmp/Gemfile.lock.#{randnum}; cp /tmp/Gemfile.lock.#{randnum} #{current_release}/Gemfile.lock"
  end
  desc "reload all letter templates"
  task :reload_all_templates do
    run "cd #{deploy_to}/current && rake fluxx_crm:reload_doc_templates RAILS_ENV=#{rails_env}"
  end
end

namespace :db do
  desc "Create database yaml in shared path" 
  task :default do
    db_config = ERB.new <<-EOF
    base: &base
      adapter: mysql
      encoding: utf8
      reconnect: false
      host: localhost
      port: 3306
      pool: 5
      username: #{user}
      password: #{password}

    development:
      database: #{application}_development
      <<: *base

    test:
      database: #{application}_test
      <<: *base

    production:
      database: #{application}_production
      <<: *base

    staging:
      database: #{application}_production
      <<: *base
    EOF

    run "mkdir -p #{shared_path}/config" 
    put db_config.result, "#{shared_path}/config/database.yml" 
  end

  desc "Make symlink for database yaml" 
  task :symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
  end
  
end

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end

after "deploy:setup", "thinking_sphinx:shared_sphinx_folder"
