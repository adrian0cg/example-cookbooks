package_to_build = :monit

execute 'apt-get update -qy'
execute 'apt-get upgrade -qy'

package 's3cmd' do
  only_if do
    node[:buildengine][:s3][:upload]
  end
end

node[:buildengine][package_to_build][:build_requirements].split.each do |pkg|
  package pkg
end

def manage_test_user (action, cwd=nil)
  user node[:buildengine][package_to_build][:user] do
    comment 'user for running build tests'
    home cwd unless cwd.nil? || cwd.empty?
    shell '/bin/bash'
  end.run_action(action)
end

def perform (cmd, options={})
  options = {
    :cwd => '/tmp',
    :user => node[:buildengine][package_to_build][:user]
  }.update(options)

  execute cmd do
    cwd options[:cwd]
    unless options[:user] == 'root'
      environment ({'HOME' => options[:cwd]})
      user options[:user]
    end
  end
end

Dir.mktmpdir do |build_base_dir|
  manage_test_user(:create, build_base_dir)

  directory build_base_dir do
    owner node[:buildengine][package_to_build][:user]
    action :create
  end

  remote_file "#{build_base_dir}/#{node[:buildengine][package_to_build][:download_package]}" do
    source "#{node[:buildengine][package_to_build][:download_base_url]}/#{node[:buildengine][:monit][:download_package]}"
    owner node[:buildengine][package_to_build][:user]
  end

  perform "tar xvfz #{node[:buildengine][package_to_build][:download_package]}",
          :cwd => build_base_dir

  build_dir = "#{build_base_dir}/#{node[:buildengine][package_to_build][:unpacked_dir]}
  perform "./configure --prefix=#{node[:buildengine][:package_to_build][:prefix]} \
                       #{node[:buildengine][package_to_build][:configure_options]}",
           :cwd => build_dir

  perform "make -j #{node['cpu']['total']}", :cwd => build_dir

  pkgrelease = "#{node[:buildengine][package_to_build][:package_release]}"
  if node[:buildengine][package_to_build].attribute?(:patchlevel)
    pkgrelease = "#{node[:buildengine][package_to_build][:patchlevel]}.#{node[:buildengine][package_to_build][:package_release]}"
  end

  pkglicense = ''
  if node[:buildengine][package_to_build].attribute?(:package_license)
    pkglicense = "--pkglicense=#{node[:buildengine][package_to_build][:package_license]}"
  end

  perform "checkinstall -y -D --pkgname=#{node[:buildengine][package_to_build][:name]} \
                        --pkgversion=#{node[:buildengine][package_to_build][:version]} \
                        --pkgrelease=#{pkgrelease} \
                        --maintainer=#{node[:buildengine][package_to_build][:package_maintainer]} \
                        --pkggroup=#{node[:buildengine][package_to_build][package_group]} \
                        #{pkglicense} make all install", :cwd => build_dir

  template "#{build_base_dir}/.s3cfg" do
    source "s3cfg.erb"
    only_if do
      node[:buildengine][:s3][:upload]
    end
  end

  execute "s3cmd -c #{build_base_dir}/.s3cfg put --acl-public \
                 --guess-mime-type #{node[:buildengine][packe_to_build][:deb]} \
                 s3://#{node[:buildengine][:s3][:bucket]}/#{node[:buildengine][:s3][:path]}/" do
    cwd build_dir
    only_if do
      node[:buildengine][:s3][:upload]
    end
  end

  file "#{build_base_dir}/.s3cfg" do
    action :delete
    backup false
  end

  directory build_base_dir do
    recursive true
    action :delete
    only_if do
      node[:buildengine][:cleanup]
    end
  end
end

manage_test_user(:remove) if node[:buildengine][:cleanup]
