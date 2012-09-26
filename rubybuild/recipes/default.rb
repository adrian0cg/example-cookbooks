case node[:platform]
when "debian","ubuntu"
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

  remote_file "/tmp/#{node[:rubybuild][:basename]}.tar.bz2" do
    source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
  end

  execute "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2" do
    cwd "/tmp"
  end

  execute "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]}" do
    cwd "/tmp/#{node[:rubybuild][:basename]}"
  end

  execute "checkinstall -y -D --pkgname=ruby1.9 --pkgversion=#{node[:rubybuild][:version]} --pkgrelease=#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]} --maintainer=mathias.meyer@scalarium.com --pkggroup=ruby --pkglicense='Ruby License' make all install" do
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
when "centos","redhat","scientific","oracle","amazon"
  package "s3cmd" do
    only_if do
      node[:rubybuild][:s3][:upload]
    end
  end

  gem_package "fpm"

  %w{rpm-build libffi-devel readline-devel libyaml-devel}.each do |pkg|
    package pkg
  end

  remote_file "/tmp/#{node[:rubybuild][:basename]}.tar.bz2" do
    source "http://ftp.ruby-lang.org/pub/ruby/1.9/#{node[:rubybuild][:basename]}.tar.bz2"
  end

  execute "tar xvfj #{node[:rubybuild][:basename]}.tar.bz2" do
    cwd "/tmp"
  end

  execute "./configure --prefix=#{node[:rubybuild][:prefix]} #{node[:rubybuild][:configure]}" do
    cwd "/tmp/#{node[:rubybuild][:basename]}"
  end

  bash "make temp directory and compile" do
    cwd "/tmp/#{node[:rubybuild][:basename]}"
    code <<-EOH
      mkdir /tmp/ruby-install-dir
      make all install DESTDIR=/tmp/ruby-install-dir
      fpm -s dir -t rpm -n ruby19 -v #{node[:rubybuild][:version]} --iteration #{node[:rubybuild][:pkgrelease]} -C /tmp/ruby-install-dir -p #{node[:rubybuild][:rpm]} -m "<daniel.huesch@scalarium.com>" -a "#{node[:kernel][:machine]}" usr

      rm -rf /tmp/ruby-install-dir
    EOH
    not_if do
      File.exists?("/tmp/#{node[:rubybuild][:basename]}/#{node[:rubybuild][:rpm]}")
    end
  end

  #template "/tmp/.s3cfg" do
  #  source "s3cfg.erb"
  #  only_if do
  #    node[:rubybuild][:s3][:upload]
  #  end
  #end

  #execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:rubybuild][:rpm]} s3://#{node[:rubybuild][:s3][:bucket]}/#{node[:rubybuild][:s3][:path]}/" do
  #  cwd "/tmp/#{node[:rubybuild][:basename]}"
  #  only_if do
  #    node[:rubybuild][:s3][:upload]
  #  end
  #end

  #file "/tmp/.s3cfg" do
  #  action :delete
  #  backup false
  #end
end
