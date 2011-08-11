package "unzip"

directory "#{node[:elb][:dir]}" do
  action :create
  recursive true
end

remote_file "#{node[:elb][:dir]}/ElasticLoadBalancing.zip" do
  source "ElasticLoadBalancing.zip"
  not_if do
    File.exists?("#{node[:elb][:dir]}/ElasticLoadBalancing.zip")
  end
end

execute "Unpack ELB Tools" do
  cwd node[:elb][:dir]
  command "unzip ElasticLoadBalancing.zip"
  not_if do
    File.exists?("#{node[:elb][:dir]}/ElasticLoadBalancing")
  end
end

template "#{node[:elb][:dir]}/update-elb" do
  backup false
  mode 0755
  source "update-elb.rb.erb"
end

template "#{node[:elb][:credential_file]}" do
  backup false
  mode 0644
  source "credentials.erb"
end

execute "Update ELB Information" do
  command "#{node[:elb][:dir]}/update-elb"
end