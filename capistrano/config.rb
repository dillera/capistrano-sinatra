set :application, "ubuntu-kiosk"
set :scm, :git
set :deploy_to, "~/#{application}"
set :scm_verbose, true
set :branch, 'master'
set :deploy_via, :remote_cache

config = YAML.load(File.read(File.expand_path('../../config/capistrano.yml', __FILE__)))
set :repository,  config['repository']
role :app, *config['servers']
set :user, config['user']
set :password, config['password']
set :sudo_user, config['sudo_user']
set :sudo_password, config[:sudo_password]

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :rvm_ruby_string, :local               # use the same ruby as used locally for deployment
set :rvm_autolibs_flag, "read-only"        # more info: rvm help autolibs


