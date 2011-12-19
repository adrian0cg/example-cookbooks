include_recipe "deploy::default"

# No need to check out the source when we're on a Rails
# App Server.
unless node[:scalarium][:instance][:roles].include?('rails-app')
  node[:deploy].each do |application, deploy|

    scalarium_deploy_dir do
      user deploy[:user]
      group deploy[:group]
      path deploy[:deploy_to]
    end

    scalarium_deploy do
      deploy_data deploy
      app application
    end

    template "#{deploy[:deploy_to]}/current/config/database.yml" do
      source "database.yml.erb"
      mode "0660"
      group deploy[:group]
      owner deploy[:user]
      variables(:database => deploy[:database], :environment => deploy[:rails_env])
      cookbook "rails" 
    end

    execute "fix access rights on deployment directory" do
      command "chmod o-w #{deploy[:deploy_to]}"
      action :run
    end
  end
end

include_recipe 'sphinx::client'

node[:deploy].each do |application, deploy|
  directory "/var/log/sphinx" do
    action :create
    owner deploy[:user]
    group deploy[:group]
    mode "0755"
  end

  directory "/var/run/sphinx" do
    action :create
    owner deploy[:user]
    group deploy[:group]
    mode "0755"
  end

  execute "rake thinking_sphinx:configure" do
    cwd "#{deploy[:deploy_to]}/current"
    user deploy[:user]
    environment 'RAILS_ENV' => deploy[:rails_env], "HOME" => "/home/#{deploy[:user]}"
  end

  execute 'rake thinking_sphinx:rebuild' do
    cwd "#{deploy[:deploy_to]}/current"
    user deploy[:user]
    environment 'RAILS_ENV' => deploy[:rails_env], "HOME" => "/home/#{deploy[:user]}"
  end

  cron "sphinx reindex cronjob" do
    action  :create
    minute  "*/#{node[:sphinx][:cron_interval]}"
    hour    '*'
    day     '*'
    month   '*'
    weekday '*'
    command "cd #{deploy[:deploy_to]}/current && RAILS_ENV=#{deploy[:rails_env]} rake thinking_sphinx:index"
    user deploy[:user]
    path "/usr/bin:/usr/local/bin:/bin"
  end

  template "/etc/monit/conf.d/sphinx_#{application}.monitrc" do
    source "sphinx.monitrc.erb"
    owner "root"
    mode "0644"
    variables :application => application, :deploy => deploy
  end

  execute "monit reload" do
  end
end
