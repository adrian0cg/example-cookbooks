execute "apt-get update"

package 'ruby-enterprise' do
  action :purge
end

directory '/usr/local/lib/ruby' do
  action :delete
  recursive true
end

package "s3cmd" do
  only_if do
    node[:rubybuild][:s3][:upload]
  end
end

package "checkinstall"
package "libffi-dev"
package 'libreadline-dev'

remote_file "/tmp/#{node[:rubybuild][:basename]}.tar.bz2" do
  source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
end

execute "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2" do
  cwd "/tmp"
end

execute "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]}" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "make all install" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "checkinstall -y -D --pkgname=ruby1.9 --pkgversion=#{node[:rubybuild][:version]} --pkgrelease=#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]} --maintainer=mathias.meyer@scalarium.com --pkggroup=ruby --pkglicense='Ruby License' --install=no make all install" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "ar x #{node[:rubybuild][:deb]}" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute 'tar xfz data.tar.gz' do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "mkdir -p usr/local/include/#{node[:rubybuild][:basename]}" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "cp *.h *.inc usr/local/include/#{node[:rubybuild][:basename]}" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "cp -r /usr/local/include/ruby-1.9.1 usr/local/include/" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "cp -r /usr/local/lib/ruby /usr/local/lib/libruby.so.1.9.1 /usr/local/lib/libruby-static.a usr/local/lib/" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "cp -r /usr/local/bin/ruby usr/local/bin/" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "tar cfz data.tar.gz usr/" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "ar r #{node[:rubybuild][:deb]} debian-binary control.tar.gz data.tar.gz" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

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
