packages_to_build = node[:buildengine][:packages_to_build]

unless packages_to_build.nil? or packages_to_build.empty?
  execute 'apt-get update -qy'
  execute 'apt-get upgrade -qy'

  package 's3cmd' do
    only_if do
      node[:buildengine][:s3][:upload]
    end
  end

  packages_to_build.each do |pkg_to_build|
    if node[:buildengine].has_key? :packages and
       node[:buildengine][:packages].has_key? pkg_to_build
      node_pkg = node[:buildengine][:packages][pkg_to_build]

      node_pkg[:build_requirements].each do |required_pkg|
        package required_pkg
      end

      build_base_dir = Dir.mktmpdir

      username = node_pkg[:user]

      user username do
        comment 'user for running build tests'
        home build_base_dir
        shell '/bin/bash'
      end

      directory build_base_dir do
        owner username
        action :create
      end

      remote_file "#{build_base_dir}/#{node_pkg[:download_package]}" do
        source "#{node_pkg[:download_base_url]}/#{node_pkg[:download_package]}"
        owner username
      end

      execute "#{node_pkg[:unpack_cmd]} #{node_pkg[:download_package]}" do
        user username
        cwd build_base_dir
      end

      build_dir = "#{build_base_dir}/#{node_pkg[:unpacked_dir]}"

      [:configure_cmd, :compile_cmd, :test_cmd].each do |cmd_to_run|
        execute node_pkg[cmd_to_run] do
          user username
          cwd build_dir
          only_if do
            node_pkg[cmd_to_run]
          end
        end
      end

      pkgrelease = node_pkg.attribute?(:patchlevel) ? \
        "#{node_pkg[:patchlevel]}.#{node_pkg[:package_release]}" : \
        "#{node_pkg[:package_release]}"

      pkglicense = node_pkg.attribute?(:package_license) ? \
        pkglicense = "--pkglicense=#{node_pkg[:package_license]}" : ''

      deb_package_name = "#{node_pkg[:name]}_#{node_pkg[:version]}-#{pkgrelease}_#{node[:buildengine][:arch]}.deb"

      execute "checkinstall -y -D --pkgname=#{node_pkg[:name]} \
                            --pkgversion=#{node_pkg[:version]} \
                            --pkgrelease=#{pkgrelease} \
                            --maintainer=#{node_pkg[:package_maintainer]} \
                            --pkggroup=#{node_pkg[:package_group]} \
                            --pakdir=#{node_pkg[:package_store_dir]} \
                            --install=no \
                            #{pkglicense} #{node_pkg[:install_cmd]}" do
        user 'root'
        cwd build_dir
      end

      template "#{build_base_dir}/.s3cfg" do
        source 's3cfg.erb'
        only_if do
          node[:buildengine][:s3][:upload]
        end
      end

      execute "s3cmd -c #{build_base_dir}/.s3cfg put --acl-public \
                     --guess-mime-type #{deb_package_name} \
                     s3://#{node[:buildengine][:s3][:bucket]}/#{node[:buildengine][:s3][:path]}/" do
        cwd node_pkg[:package_store_dir]
        only_if do
          node[:buildengine][:s3][:upload]
        end
      end

      file "#{build_base_dir}/.s3cfg" do
        action :delete
        backup false
      end

      directory build_base_dir do
        recursive true
        action :delete
        only_if do
          node[:buildengine][:cleanup]
        end
      end

      user username do
        action :remove
        only_if do
          node[:buildengine][:cleanup]
        end
      end

      file "#{node_pkg[:package_store_dir]}/#{deb_package_name}" do
        action :delete
        backup false
        only_if do
          node[:buildengine][:cleanup]
        end
      end
    end
  end
end
