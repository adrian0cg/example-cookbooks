default[:nodejsbuild] = {}
default[:nodejsbuild][:version] = '0.4.4'
default[:nodejsbuild][:basename] = "nodejs-#{node[:nodejsbuild][:version]}"
default[:nodejsbuild][:pkgrelease] = '1'
default[:nodejsbuild][:prefix] = '/usr/local'
default[:nodejsbuild][:arch] = node[:kernel][:machine] == 'x86_64' ? 'amd64' : 'i386'
default[:nodejsbuild][:deb] = "nodejs_#{node[:nodejsbuild][:version]}-#{node[:nodejsbuild][:pkgrelease]}_#{node[:nodejsbuild][:arch]}.deb"
default[:nodejsbuild][:s3] = {}
default[:nodejsbuild][:s3][:upload] = false
default[:nodejsbuild][:s3][:bucket] = ''
default[:nodejsbuild][:s3][:path] = "#{node[:platform]}/#{node[:platform_version]}"
default[:nodejsbuild][:s3][:aws_access_key] = ""
default[:nodejsbuild][:s3][:aws_secret_access_key] = ""

default[:nodejsbuild][:versions_to_build] = [
  '0.4.0',
  '0.4.1',
  '0.4.2',
  '0.4.3',
  '0.4.4',
  '0.4.5',
  '0.4.6',
  '0.4.7',
  '0.6.1'
]
