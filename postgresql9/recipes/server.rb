include_recipe "postgresql9::prepare"

local_unpacked = "/tmp/postgresql-#{node[:postgresql9][:version]}"
local_package = "/tmp/postgresql-#{node[:postgresql9][:version]}.tar.bz2"

package "libreadline-dev"

postgresql_version_installed = File.exists?("#{node[:postgresql9][:prefix]}/bin/pg_ctl") ? `#{node[:postgresql9][:prefix]}/bin/pg_ctl --version | awk '{print $3}'`.strip : nil

Chef::Log.info("Found installed PostgreSQL version #{postgresql_version_installed}") if postgresql_version_installed

postgresql_version_uptodate = lambda do
  postgresql_version_installed == node[:postgresql9][:version]
end

remote_file local_package do
  source "http://ftp.postgresql.org/pub/source/v#{node[:postgresql9][:version]}/postgresql-#{node[:postgresql9][:version]}.tar.bz2"
end

execute "tar xvfj #{local_package}" do
  cwd "/tmp"
  umask 022
  not_if &postgresql_version_uptodate
end

execute "./configure --prefix=#{node[:postgresql9][:prefix]} && make && make install" do
  cwd local_unpacked
  umask 022
  not_if &postgresql_version_uptodate
end

execute "#{node[:postgresql9][:prefix]}/bin/initdb -E #{node[:postgresql9][:encoding]} -D #{node[:postgresql9][:datadir]}" do
  umask 022
  user node[:postgresql9][:user]
  not_if { File.exists?("#{node[:postgresql9][:datadir]}/PG_VERSION") }
end

template "/etc/init.d/postgresql" do
  source "postgresql.init.erb"
  owner "root"
  group "root"
  mode "0755"
end

execute "sysctl -w kernel.shmmax=#{node[:postgresql9][:shmmax]}"

template "/etc/sysctl.conf" do
  source "sysctl.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :shmmax => node[:postgresql9][:shmmax]
end

include_recipe 'postgresql9::service'
service "postgresql" do
  action :enable
end

template "#{node[:postgresql9][:datadir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner node[:postgresql9][:user]
  group node[:postgresql9][:group]
  mode "0644"
  notifies :start, resources(:service => 'postgresql'), :immediate
end

template "/etc/monit/conf.d/postgresql.monitrc" do
  source "postgresql.monit.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :pg_group => node[:postgresql9][:group],
            :pg_data_dir => node[:postgresql9][:datadir]
end

service "postgresql" do
  action :start
end

execute %Q{#{node[:postgresql9][:prefix]}/bin/psql -c "CREATE ROLE #{node[:postgresql9][:role]} PASSWORD 'md5#{node[:postgresql9][:password]}' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;"} do
  user node[:postgresql9][:user]
  group node[:postgresql9][:group]
  not_if "sleep 10 && sudo -u #{node[:postgresql9][:user]} #{node[:postgresql9][:prefix]}/bin/psql -c 'select rolname from pg_roles' | grep #{node[:postgresql9][:role]}"
end

execute "monit reload" do
  action :run
end
