case node[:platform]
when "debian","ubuntu"
  execute "apt-get update"
  package "checkinstall"
when "centos","redhat","scientific","oracle","amazon","fedora"
  gem_package "fpm"
end

package "s3cmd" do
  only_if do
    node[:nodejsbuild][:s3][:upload]
  end
end

case node[:platform]
when "ubuntu","debian"
  %w{build-essential binutils-doc}.each do |pkg|
    package pkg do
      action :install
    end
  end
when "centos"
  package "gcc" do
    action :install
  end
end

package "autoconf" do
  action :install
end

package "flex" do
  action :install
end

package "bison" do
  action :install
end

case node[:platform]
  when "centos","redhat","fedora"
    package "openssl-devel"
  when "debian","ubuntu"
    package "libssl-dev"
end

('0.4.0' .. '0.4.7').each do |version|
  node[:nodejsbuild][:version] = version
  node[:nodejsbuild][:basename] = "nodejs-#{node[:nodejsbuild][:version]}"
  node[:nodejsbuild][:deb] = "nodejs_#{node[:nodejsbuild][:version]}-#{node[:nodejsbuild][:pkgrelease]}_#{node[:nodejsbuild][:arch]}.deb"
  node[:nodejsbuild][:rpm] = "nodejs-#{node[:nodejsbuild][:version]}-#{node[:nodejsbuild][:pkgrelease]}.#{node[:kernel][:machine]}.rpm"

  remote_file "/tmp/#{node[:nodejsbuild][:basename]}.tar.gz" do
    source "http://nodejs.org/dist/node-v#{node[:nodejsbuild][:version]}.tar.gz"
  end

  execute "tar xvfz #{node[:nodejsbuild][:basename]}.tar.gz" do
    cwd "/tmp"
  end

  execute "./configure --prefix=#{node[:nodejsbuild][:prefix]}" do
    cwd "/tmp/node-v#{node[:nodejsbuild][:version]}"
  end

  case node[:platform]
  when "debian","ubuntu"
    execute "checkinstall -y -D --pkgname=nodejs --pkgversion=#{node[:nodejsbuild][:version]} --pkgrelease=#{node[:nodejsbuild][:pkgrelease]} --maintainer=daniel.huesch@scalarium.com --pkglicense='node.js License' make all install" do
      cwd "/tmp/node-v#{node[:nodejsbuild][:version]}"
    end
  when "centos","redhat","amazon","scientific","oracle","fedora"
    bash "build and package nodejs #{node[:nodejsbuild][:version]}" do
      cwd "/tmp/node-v#{node[:nodejsbuild][:version]}"
      code <<-EOH
        mkdir /tmp/nodejs-install-dir
        make all install DESTDIR=/tmp/nodejs-install-dir
        fpm -s dir -t rpm -n nodejs -v #{node[:rubybuild][:version]}.#{node[:rubybuild][:pkgrelease]} -C /tmp/nodejs-install-dir -p #{node[:nodejsbuild][:rpm]} usr
        rm -rf /tmp/nodejs-install-dir
      EOH
    end
  end

  template "/tmp/.s3cfg" do
    source "s3cfg.erb"
    only_if do
      node[:nodejsbuild][:s3][:upload]
    end
  end

  case node[:platform]
  when "debian","ubuntu"
    execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:nodejsbuild][:deb]} s3://#{node[:nodejsbuild][:s3][:bucket]}/#{node[:nodejsbuild][:s3][:path]}/" do
      cwd "/tmp/node-v#{node[:nodejsbuild][:version]}"
      only_if do
        node[:nodejsbuild][:s3][:upload]
      end
    end
  when "centos","redhat","amazon","scientific","oracle","fedora"
    execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:nodejsbuild][:rpm]} s3://#{node[:nodejsbuild][:s3][:bucket]}/#{node[:nodejsbuild][:s3][:path]}/" do
      cwd "/tmp/node-v#{node[:nodejsbuild][:version]}"
      only_if do
        node[:nodejsbuild][:s3][:upload]
      end
    end
  end

  file "/tmp/.s3cfg" do
    action :delete
    backup false
  end
end
