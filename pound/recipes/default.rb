package "pound"

template "/etc/default/pound" do
  source "default.erb"
  mode "644"
end

template "/etc/pound/ssl.pem" do
  source "ssl.pem.erb"
  mode "0400"
end

include_recipe "pound::service"

template "/etc/pound/pound.cfg" do
  source "pound.cfg.erb"
  mode "644"
  notifies :restart, resources(:service => "pound")
end

service "pound" do
  action [ :enable, :start ]
end