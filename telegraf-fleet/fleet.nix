{ region ? "us-east-1"
, accessKeyId ? "testing"
, vpcId ? "vpc-xxxxxx"
, subnetId ? "subnet-xxxxxx"
, rootVolumeSize ? 60
, encrypt ? false
, ...
}:
{

  resources.ec2Fleet.testFleet =
    {resources, ...}:
    {
      inherit region accessKeyId;
      launchTemplateName = resources.ec2LaunchTemplate.testlaunchtemplate;
      launchTemplateVersion = resources.ec2LaunchTemplate.testlaunchtemplate;
     launchTemplateOverrides = [
        {InstanceType = "m5.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "m5.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "m5.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "m5.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "m5.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "m5.large"; SubnetId = "subnet-xxxxxxx";}

        {InstanceType = "r4.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "r4.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "r4.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "r4.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "r4.large"; SubnetId = "subnet-xxxxxxx";}
        {InstanceType = "r4.large"; SubnetId = "subnet-xxxxxxx";}
        ];
      terminateInstancesWithExpiration = true;
      fleetRequestType = "request";
      replaceUnhealthyInstances = false;
      terminateInstancesOnDeletion = true;
      spotOptions = {
          instanceInterruptionBehavior = "terminate";
          singleAvailabilityZone = false;
          minTargetCapacity = 1;
          instancePoolsToUseCount = 4;
          singleInstanceType = false;
          allocationStrategy = "diversified";
      };
      onDemandOptions = {
        singleAvailabilityZone = false;
        minTargetCapacity = 1;
        singleInstanceType = false;
        allocationStrategy = "lowestPrice";
      };
      targetCapacitySpecification = {
        totalTargetCapacity = 100;
        onDemandTargetCapacity = 0;
        spotTargetCapacity = 5;
        defaultTargetCapacityType = "spot";
      };
    };

  resources.ec2LaunchTemplate.testlaunchtemplate =
    {resources, ...}:
    {
      inherit region accessKeyId;
      templateName = "lt-with-nixops";
      description = "lt with nix";
      versionDescription = "version 1 ";
      instanceType = "m5.large";
      ami = "ami-009c9c3f1af480ff3";
      subnetId = "subnet-xxxxxxx";
      keyPair = "dovah-kin";
      ebsInitialRootDiskSize = rootVolumeSize;
      associatePublicIpAddress = true;
      userData =''
        { config, lib,  pkgs, ... }:
        {


          imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
          ec2.hvm = true;
          environment.systemPackages = with pkgs; [ vim tree telegraf];
          services.telegraf.enable = true;
          networking.firewall.allowedTCPPorts = [ 80 ];
          services.telegraf.extraConfig = {
            outputs = {
              influxdb = {
                urls = [ "https://influxdb.dovah.kin:8086" ];
                database = "test";
                username = "telegraf";
                password = "password";
                skip_database_creation = false;
                insecure_skip_verify = true;
              };
            };
            inputs = {
              cpu = {
                percpu = true;
                totalcpu = true;
                collect_cpu_time = true;
                report_active = true;
              };
              disk = {
                ignore_fs = ["tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs"];
              };
              diskio = {};
              swap = {};
              io = {};
              mem = {};
              net = {};
              system = {};
              kernel = {};
              procstat = {
                systemd_unit = "telegraf.service";
              };
            };
          };

          systemd.services.telegraf.path = with pkgs; [procps python3];
        }


       '';
      securityGroupIds = [ "my-admin-sg" ];

    };
}
