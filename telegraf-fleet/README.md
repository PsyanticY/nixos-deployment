# telegraf fleet

These nix expressions were used to stress test an influxdb database hosted on an aws efs fileshare.

The idea was to use the ec2-fleet resource with the launch template nixops resource to create a fleet of instances that runs telegraf to sends metrics to a influxdb database on an EFS.

We made use of user-data in the launch template to automate the configuration of the nixos instances.

