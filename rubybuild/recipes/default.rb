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

# compile agains latest libraries
execute "apt-get update -qy"
execute "apt-get upgrade -qy"

package "checkinstall"
package "libffi-dev"
package 'libreadline-dev'
package 'libyaml-dev'

def manage_test_user(action, cwd)
  user node[:rubybuild][:user] do
    comment "User to run build tests"
    gid "scalarium"
    home cwd
    shell "/bin/bash"
  end.run_action( action )
end

def current_time
  Time.now.strftime("%Y%m%dT%H%M%S")
end

def perform(cmd, options = {})
  options = {
          :cwd => "/#{$run_as_home}/#{node[:rubybuild][:basename]}",
          :user => node[:rubybuild][:user]
        }.update(options)

  execute cmd do
    cwd options[:cwd]
    unless options[:user] == 'root'
      environment ({'HOME' => $run_as_home})
      user options[:user]
    end
  end
end


# the whole build happens in a temp directory to avoid collitions with other builds
Dir.mktmpdir do |build_dir|

  >>>>> Methoden Param  >>>>>>>>>>   $run_as_home = build_dir

  manage_test_user(:create, build_dir)

  directory $run_as_home do
    owner node[:rubybuild][:user]
    action :create
  end

  remote_file "#{$run_as_home}/#{node[:rubybuild][:basename]}.tar.bz2" do
    source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
    owner node[:rubybuild][:user]
  end

  # if this runs as root, we're going to have problems during testing
  perform "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2", {:dir => $run_as_home}
  perform "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]} > /tmp/configure_#{current_time} 2>&1"
  perform "make -j #{node["cpu"]["total"]} > /tmp/make_#{current_time} 2>&1"

  # this must run as root
  perform "make -j #{node["cpu"]["total"]} install > /tmp/install_#{current_time} 2>&1", {:user => "root"}

  # this must NOT run as root
#  perform "make -j #{node["cpu"]["total"]} check > /tmp/test_#{current_time} 2>&1"

  perform "checkinstall -y -D --pkgname=ruby1.9 --pkgversion=#{node[:rubybuild][:version]} \
                        --pkgrelease=#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]} \
                        --maintainer=#{node[:rubybuild][:maintainer]} --pkggroup=ruby --pkglicense='Ruby License' \
                        --include=./.installed.list \
                        --install=no \
                        make install",
                        {:user => "root"}

  perform "cp -f *.deb /tmp/ ", {:user => "root"}

  if node[:rubybuild][:s3][:upload]
    package "s3cmd"

    template "/tmp/.s3cfg" do
      source "s3cfg.erb"
    end

    execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:rubybuild][:deb]} s3://#{node[:rubybuild][:s3][:bucket]}/#{node[:rubybuild][:s3][:path]}/" do
      cwd "#{$run_as_home}/#{node[:rubybuild][:basename]}"
    end

    file "/tmp/.s3cfg" do
      action :delete
      backup false
    end
  end

  directory $run_as_home do
    recursive true
    action :delete
    only_if do
      node[:rubybuild][:cleanup]
  end
end

end

manage_test_user(:remove) if node[:rubybuild][:cleanup]
