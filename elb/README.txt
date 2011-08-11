Registers an instance on the AWS Elastic Load Balancer.

It deregisters all other instances and then registers the instance running this recipe.

Include like "elb::default" on the setup action.

You need to set the attribute describing with ELBs configure:


  set[:elb][:names] = ['elb-name1', 'elb-foo-bert']
  
