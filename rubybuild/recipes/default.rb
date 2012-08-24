#
# To run the build process you need to set the following attributes
#  per custom json
#
#  "rubybuild": {
#                "version": "1.9.3",
#                "patch": "p194",
#                "pkgrelease": "1"
#               }
#
# will build ruby1.9_1.9.3-p194.1_#{arch}.deb

# compile against latest libraries
execute "apt-get update -qy"
execute "apt-get upgrade -qy"

package "checkinstall"
package "libffi-dev"
package 'libreadline-dev'
package 'libyaml-dev'

def manage_test_user(action, cwd = nil)
  user node[:rubybuild][:user] do
    comment "User for running build tests"
    gid "scalarium"
    home cwd unless cwd.nil?
    shell "/bin/bash"
  end.run_action( action )
end

def current_time
  Time.now.strftime("%Y%m%dT%H%M%S")
end

def perform(cmd, options = {})
  options = {
              :cwd => "/tmp",
              :user => node[:rubybuild][:user]
            }.update(options)

  execute cmd do
    cwd options[:cwd]
    unless options[:user] == 'root'
      environment ({'HOME' => options[:cwd]})
      user options[:user]
    end
  end
end


# the whole build happens in a temp directory to avoid collitions with other builds
Dir.mktmpdir do |target_dir|

  manage_test_user(:create, target_dir)

  directory target_dir do
    owner node[:rubybuild][:user]
    action :create
  end

  remote_file "#{target_dir}/#{node[:rubybuild][:basename]}.tar.bz2" do
    source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
    owner node[:rubybuild][:user]
  end

  # if this runs as root, we're going to have problems during testing
  perform "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2", :cwd => target_dir

  build_dir = "#{target_dir}/#{node[:rubybuild][:basename]}"
  perform "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]} > /tmp/configure_#{current_time} 2>&1", :cwd => build_dir
  perform "make -j #{node["cpu"]["total"]} > /tmp/make_#{current_time} 2>&1", :cwd => build_dir

  # this must run as root
  perform "make -j #{node["cpu"]["total"]} install > /tmp/install_#{current_time} 2>&1", :cwd => build_dir, :user => "root"

  # this must NOT run as root
  perform "make -j #{node["cpu"]["total"]} check > /tmp/test_#{current_time} 2>&1", :cwd => build_dir

  perform "checkinstall -y -D --pkgname=ruby1.9 --pkgversion=#{node[:rubybuild][:version]} \
                        --pkgrelease=#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]} \
                        --maintainer=#{node[:rubybuild][:maintainer]} --pkggroup=ruby --pkglicense='Ruby License' \
                        --include=./.installed.list \
                        --install=no \
                        make install",
                        :cwd => build_dir,
                        :user => "root"

  if node[:rubybuild][:s3][:upload]
    package "s3cmd"

    template "/tmp/.s3cfg" do
      source "s3cfg.erb"
    end

    execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:rubybuild][:deb]} s3://#{node[:rubybuild][:s3][:bucket]}/#{node[:rubybuild][:s3][:path]}/" do
      cwd build_dir
    end

    file "/tmp/.s3cfg" do
      action :delete
      backup false
    end
  end

  directory build_dir do
    recursive true
    action :delete
    only_if do
      node[:rubybuild][:cleanup]
    end
  end
end

manage_test_user(:remove) if node[:rubybuild][:cleanup]
