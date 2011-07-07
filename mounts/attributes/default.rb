default[:elasticsearch][:data_dir] = '/var/lib/elasticsearch'
set[:scalarium_initial_setup][:bind_mounts][:mounts] = scalarium_initial_setup[:bind_mounts][:mounts].update({
  '/var/log/elasticsearch' => '/mnt/var/log/elasticsearch',
  elasticsearch[:data_dir] => "/mnt#{elasticsearch[:data_dir]}"
})
