include_recipe 'deploy'
include_recipe 'postgresql9::service'

service "postgresql" do
  action :start
end

execute "reload pg_hba" do
  command "pg_ctl reload -D #{node[:postgresql9][:datadir]}"
  action :nothing
end


node[:deploy].each do |application, deploy|
  execute "Creating PostgreSQL database #{application}" do
    command "#{node[:postgresql9][:prefix]}/bin/psql -c 'CREATE DATABASE #{application}'"
    user node[:postgresql9][:user]
    not_if "#{node[:postgresql9][:prefix]}/bin/psql -l -t  | awk '{print $1}' | grep -v '^|\?$' | grep #{application}",
      :user => node[:postgresql9][:user]
  end
end

template "#{node[:postgresql9][:datadir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner node[:postgresql9][:user]
  group node[:postgresql9][:group]
  mode "0644"
  notifies :run, resources(:execute => 'reload pg_hba'), :immediate
end
