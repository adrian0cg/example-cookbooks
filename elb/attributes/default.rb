default[:elb][:dir] = "/opt/elb"
default[:elb][:home] = "/opt/elb/ElasticLoadBalancing"
default[:elb][:prefix] = "/opt/elb/ElasticLoadBalancing/bin"
default[:elb][:credential_file] = "/opt/elb/credetials"
default[:elb][:java_home] = "/usr/lib/jvm/java-6-openjdk/"

default[:elb][:ec2_url] = "https://eu-west-1.ec2.amazonaws.com"
default[:elb][:ec2_region] = "eu-west-1"
default[:elb][:access_key] = "AKIAJUGXLRT4A4X6V7QA"
default[:elb][:secret_key] = "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"

default[:elb][:instance_to_register] = scalarium[:instance][:aws_instance_id]

# to set by the user
default[:elb][:names] = ['elb-name1', 'elb-foo-bert']