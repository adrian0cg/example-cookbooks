default[:buildengine] = {}
default[:buildengine][:arch] = node[:kernel][:machine] == 'x86_64' ? 'amd64' : 'i386'
default[:buildengine][:packages] = {}
default[:buildengine][:packages][:monit] = {}
default[:buildengine][:packages][:monit][:name] = 'monit'
default[:buildengine][:packages][:monit][:version] = '5.5'
#default[:buildengine][:packages][:monit][:patchlevel] = 'p999'
default[:buildengine][:packages][:monit][:download_base_url] = 'http://mmonit.com/monit/dist/'
default[:buildengine][:packages][:monit][:download_package] = 'monit-5.5.tar.gz'
default[:buildengine][:packages][:monit][:unpack_cmd] = 'tar xvfz'
default[:buildengine][:packages][:monit][:user] = 'monitbuild'
default[:buildengine][:packages][:monit][:unpacked_dir] = 'monit-5.5'
default[:buildengine][:packages][:monit][:build_requirements] = ['checkinstall', 'libpam0g-dev', 'make', 'gcc']
default[:buildengine][:packages][:monit][:configure_opts_addon] = node[:platform_version].to_f >= '11.10'.to_f ? ( node[:kernel][:machine] == 'x86_64' ? '--with-ssl-lib-dir=/lib/x86_64-linux-gnu' : '--with-ssl-lib-dir=/usr/lib/i386-linux-gnu' )  : ''
default[:buildengine][:packages][:monit][:configure_cmd] = "./configure --prefix=/usr/local --enable-optimized #{node[:buildengine][:packages][:monit][:configure_opts_addon]}"
default[:buildengine][:packages][:monit][:compile_cmd] = "make -j #{node['cpu']['total']}"
#default[:buildengine][:packages][:monit][:test_cmd] = 'make test'
default[:buildengine][:packages][:monit][:install_cmd] = 'make install'
default[:buildengine][:packages][:monit][:package_release] = '0'
default[:buildengine][:packages][:monit][:package_group] = 'admin'
default[:buildengine][:packages][:monit][:package_maintainer] = 'development@scalarium.com'
#default[:buildengine][:packages][:monit][:package_license] = 'Some Fantasy License'
default[:buildengine][:packages][:monit][:package_store_dir] = '/tmp'
default[:buildengine][:cleanup] = true
default[:buildengine][:s3] = {}
default[:buildengine][:s3][:upload] = false
default[:buildengine][:s3][:bucket] = ''
default[:buildengine][:s3][:path] = "#{node[:platform]}/#{node[:platform_version]}"
default[:buildengine][:s3][:aws_access_key] = ''
default[:buildengine][:s3][:aws_secret_access_key] = ''
