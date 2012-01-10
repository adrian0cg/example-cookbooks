execute "apt-get update"

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

execute "sed -i 's/#option nodynamic/option nodynamic/' ext/Setup" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "make" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "make install" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

execute "tar cfj #{node[:rubybuild][:tbz2]} #{node[:rubybuild][:prefix]}" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
end

template "/tmp/.s3cfg" do
  source "s3cfg.erb"
  only_if do
    node[:rubybuild][:s3][:upload]
  end
end

execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:rubybuild][:tbz2]} s3://#{node[:rubybuild][:s3][:bucket]}/#{node[:rubybuild][:s3][:path]}/" do
  cwd "/tmp/#{node[:rubybuild][:basename]}"
  only_if do
    node[:rubybuild][:s3][:upload]
  end
end

file "/tmp/.s3cfg" do
  action :delete
  backup false
end
