node[:deploy].each do |application, deploy|
  set[:deploy][application][:shell] = '/bin/bash'
end
