execute "apt-get update"

package "s3cmd" do
  only_if do
    node[:rubybuild][:s3][:upload]
  end
end

package "checkinstall"
package "libffi-dev"
package 'libreadline-dev'
package 'libyaml-dev'

def perform(cmd, dir = "/tmp/#{node[:rubybuild][:basename]}")
  execute cmd do
    cwd dir
  end
end

#perform('git clone git://github.com/sstephenson/ruby-build.git', '/tmp')
#perform('env PREFIX=/tmp ./install.sh', '/tmp/ruby-build')

remote_file "/tmp/#{node[:rubybuild][:basename]}.tar.bz2" do
  source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
end

execute "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2" do
  cwd "/tmp"
end

perform "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]}"
perform 'make all install'
perform "checkinstall -y -D --pkgname=ruby1.9 --pkgversion=#{node[:rubybuild][:version]} --pkgrelease=#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]} --maintainer=mathias.meyer@scalarium.com --pkggroup=ruby --pkglicense='Ruby License' --install=no make all install"

#perform('rm -rf /usr/local')
#perform("/tmp/bin/ruby-build #{node[:rubybuild][:version]}-#{node[:rubybuild][:patch]} /usr/local")

#perform("ar x #{node[:rubybuild][:deb]}")
#perform('tar xfz data.tar.gz')
#perform('cp -r /usr/local/* usr/local/')
#perform("tar cfz data.tar.gz usr/")
#perform("ar r #{node[:rubybuild][:deb]} debian-binary control.tar.gz data.tar.gz")

template "/tmp/.s3cfg" do
  source "s3cfg.erb"
  only_if do
    node[:rubybuild][:s3][:upload]
  end
end

execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:rubybuild][:deb]} s3://#{node[:rubybuild][:s3][:bucket]}/#{node[:rubybuild][:s3][:path]}/" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
  only_if do
    node[:rubybuild][:s3][:upload]
  end
end

file "/tmp/.s3cfg" do
  action :delete
  backup false
end
