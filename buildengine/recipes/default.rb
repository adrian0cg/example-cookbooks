package_to_build = :monit

execute 'apt-get update -qy'
execute 'apt-get upgrade -qy'

package 's3cmd' do
  only_if do
    node[:buildengine][:s3][:upload]
  end
end

node[:buildengine][:monit][:build_requirements].split.each do |pkg|
  package pkg
end

def manage_test_user (action, cwd=nil)
  user node[:buildengine][:monit][:user] do
    comment 'user for running build tests'
    home cwd unless cwd.nil? || cwd.empty?
    shell '/bin/bash'
  end.run_action(action)
end

def perform (cmd, options={})
  options = {
    :cwd => '/tmp',
    :user => node[:buildengine][:monit][:user]
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
    owner node[:buildengine][:monit][:user]
    action :create
  end

  remote_file "#{build_base_dir}/#{node[:buildengine][:monit][:download_package]}" do
    source "#{node[:buildengine][:monit][:download_base_url]}/#{node[:buildengine][:monit][:download_package]}"
    owner node[:buildengine][:monit][:user]
  end

  perform "tar xvfz #{node[:buildengine][:monit][:download_package]}",
          :cwd => build_base_dir

  build_dir = "#{build_base_dir}/#{node[:buildengine][:monit][:unpacked_dir]}
  perform "./configure --prefix=#{node[:buildengine][::monit][:prefix]} \
                       #{node[:buildengine][:monit][:configure_options]}",
           :cwd => build_dir

  perform "make -j #{node['cpu']['total']}", :cwd => build_dir

  pkgrelease = "#{node[:buildengine][:monit][:package_release]}"
  if node[:buildengine][:monit].attribute?(:patchlevel)
    pkgrelease = "#{node[:buildengine][:monit][:patchlevel]}.#{node[:buildengine][:monit][:package_release]}"
  end

  pkglicense = ''
  if node[:buildengine][:monit].attribute?(:package_license)
    pkglicense = "--pkglicense=#{node[:buildengine][:monit][:package_license]}"
  end

  perform "checkinstall -y -D --pkgname=#{node[:buildengine][:monit][:name]} \
                        --pkgversion=#{node[:buildengine][:monit][:version]} \
                        --pkgrelease=#{pkgrelease} \
                        --maintainer=#{node[:buildengine][:monit][:package_maintainer]} \
                        --pkggroup=#{node[:buildengine][:monit][package_group]} \
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
