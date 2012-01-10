default[:rubybuild] = {}
default[:rubybuild][:version] = '1.9.3'
default[:rubybuild][:patch] = 'p0'
default[:rubybuild][:basename] = "ruby-#{node[:rubybuild][:version]}-#{node[:rubybuild][:patch]}"
default[:rubybuild][:pkgrelease] = '3'
default[:rubybuild][:prefix] = '/root/scalarium-agent/vendor/ruby'
default[:rubybuild][:configure] = '--disable-shared --disable-install-doc'
default[:rubybuild][:arch] = node[:kernel][:machine] == 'x86_64' ? 'amd64' : 'i386'
default[:rubybuild][:deb] = "ruby1.9_#{node[:rubybuild][:version]}-#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]}_#{node[:rubybuild][:arch]}.deb"
default[:rubybuild][:tbz2] = "ruby1.9_static_#{node[:rubybuild][:version]}-#{node[:rubybuild][:patch]}.#{node[:rubybuild][:pkgrelease]}_#{node[:rubybuild][:arch]}.tbz2"
default[:rubybuild][:s3] = {}
default[:rubybuild][:s3][:upload] = false
default[:rubybuild][:s3][:bucket] = ''
default[:rubybuild][:s3][:path] = "#{node[:platform]}/#{node[:platform_version]}"
default[:rubybuild][:s3][:aws_access_key] = ""
default[:rubybuild][:s3][:aws_secret_access_key] = ""
