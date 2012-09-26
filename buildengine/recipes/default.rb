execute 'apt-get update'

package 's3cmd' do
  only_if do
    node[:buildengine][:s3][:upload]
  end
end

node[:buildengine][:monit][:build_requirements].split.each do |pkg|
  package pkg
end

remote_file "/tmp/#{node[:buildengine][:monit][:download_package]}" do
  source "#{node[:buildengine][:monit][:download_base_url]}/#{node[:buildengine][:monit][:download_package]}"
end

execute "tar xvfz #{node[:buildengine][:monit][:download_package]}" do
  cwd '/tmp'
end

execute "./configure --prefix=#{node[:buildengine][:monit][:prefix]} #{node[:buildengine][:monit][:configure_options]}" do
  cwd "/tmp/#{node[:buildengine][:monit][:unpacked_dir]}"
end

pkgrelease = "#{node[:buildengine][:monit][:package_release]}"
if node[:buildengine][:monit].attribute?(:patchlevel)
  pkgrelease = "#{node[:buildengine][:monit][:patchlevel]}.#{node[:buildengine][:monit][:package_release]}"
end

pkglicense = ''
if node[:buildengine][:monit].attribute?(:package_license)
  pkglicense = "--pkglicense=#{node[:buildengine][:monit][:package_license]}"
end

execute "checkinstall -y -D --pkgname=#{node[:buildengine][:monit][:name]} --pkgversion=#{node[:buildengine][:monit][:version]} --pkgrelease=#{pkgrelease} --maintainer=#{node[:buildengine][:monit][:package_maintainer]} --pkggroup=#{node[:buildengine][:monit][package_group]} #{pkglicense} make all install" do
  cwd "/tmp/#{node[:buildengine][:monit][:unpacked_dir]}"
end

template "/tmp/.s3cfg" do
  source "s3cfg.erb"
  only_if do
    node[:buildengine][:s3][:upload]
  end
end

execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:buildengine][:monit][:deb]} s3://#{node[:buildengine][:s3][:bucket]}/#{node[:buildengine][:s3][:path]}/" do
  cwd "/tmp/#{node[:buildengine][:monit][:unpacked_dir]}"
  only_if do
    node[:buildengine][:s3][:upload]
  end
end

file "/tmp/.s3cfg" do
  action :delete
  backup false
end
