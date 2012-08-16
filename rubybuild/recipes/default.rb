execute "apt-get update"

package "checkinstall"
package "libffi-dev"
package 'libreadline-dev'
package 'libyaml-dev'

$run_as = 'testo'
$run_as_home = '/tmp'

maintainer = 'development@scalarium.com'

def manage_test_user(action)
        user $run_as do
          comment "User to run build tests"
          gid "scalarium"
          home $run_as_home
          shell "/bin/bash"
        end.run_action( action )
end

def current_time
  Time.now.strftime("%Y%m%dT%H%M%S")
end

def perform(cmd, dir = "/tmp/#{node[:rubybuild][:basename]}", impersonate = $run_as)
  execute cmd do
    cwd dir
    unless impersonate == 'root'
      # it's not enough to set the right user.
      environment ({'HOME' => $run_as_home})
      user impersonate
    end
  end
end

manage_test_user(:create)

remote_file "/tmp/#{node[:rubybuild][:basename]}.tar.bz2" do
  source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
  owner $run_as
end

perform "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2", "/tmp"
perform "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]}"
perform "make -j #{node["cpu"]["total"]} all > /tmp/build_#{current_time} 2>&1"
perform "make -j #{node["cpu"]["total"]} install > /tmp/build_#{current_time} 2>&1", "/tmp/#{node[:rubybuild][:basename]}", "root"
perform "make -j #{node["cpu"]["total"]} check > /tmp/test_#{current_time} 2>&1"

manage_test_user(:remove)

perform "checkinstall -y -D --pkgname=ruby1.9 --pkgversion=#{node[:rubybuild][:version]} \
                      --pkgrelease=#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]} \
                      --maintainer=#{maintainer} --pkggroup=ruby --pkglicense='Ruby License' \
                      --include=./.installed.list \
                      --install=no \
                      make install",
                      "/tmp/#{node[:rubybuild][:basename]}",
                      "root"

if node[:rubybuild][:s3][:upload]
  package "s3cmd"

  template "/tmp/.s3cfg" do
    source "s3cfg.erb"
  end

  execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:rubybuild][:deb]} s3://#{node[:rubybuild][:s3][:bucket]}/#{node[:rubybuild][:s3][:path]}/" do
    cwd "/tmp/#{node[:rubybuild][:basename]}"
  end

  file "/tmp/.s3cfg" do
    action :delete
    backup false
  end
end
