include_recipe "common_build"

gem_package "fpm"

%w{rpm-build libffi-devel readline-devel openssl-devel libyaml-devel}.each do |pkg|
  package pkg
end

remote_file "/tmp/#{node[:reebuild][:basename]}.tar.gz" do
  source "http://rubyenterpriseedition.googlecode.com/files/#{node[:reebuild][:basename]}.tar.gz"
end

execute "tar xvzf #{node[:reebuild][:basename]}.tar.gz" do
  cwd "/tmp"
end

bash "make temp directory and compile" do
  cwd "/tmp/#{node[:reebuild][:basename]}"
  code <<-EOH
    mkdir /tmp/ree-install-dir
    ./installer --auto #{node[:reebuild][:prefix]} --dont-install-useful-gems --no-dev-docs --destdir /tmp/ree-install-dir
    fpm -s dir -t rpm -n ruby-enterprise -v #{node[:reebuild][:version]} --iteration #{node[:reebuild][:pkgrelease]} -C /tmp/ree-install-dir -p #{node[:reebuild][:rpm]} -m "<daniel.huesch@scalarium.com>" -a "#{node[:kernel][:machine]}" usr
    cp *.rpm #{node[:common_build][:directory]}
    rm -rf /tmp/ree-install-dir
  EOH
  not_if do
    File.exists?("/tmp/#{node[:reebuild][:basename]}/#{node[:reebuild][:rpm]}")
  end
end
