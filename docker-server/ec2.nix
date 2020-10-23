{ region ? "ca-central-1"
, account ? "ops"
, az ? "ca-central-1b"
, vpcId ? "vpc-xxxxxxx"
, subnetId ? "subnet-xxxxxx"
, sharedSecurityGroup ? "sg-0xxxxxx"
, instanceType ? "m4.large"
, rootVolumeSize ? 60
, description ? "testing"
, account_id ? "xxxxxxx"
, ...
}:
with import <nixpkgs/lib>;
{
  master =
  { lib, pkgs, name, config, resources, ... }:
  {
     require = [ ./config.nix ];
     deployment.targetEnv = "ec2";
     deployment.ec2.accessKeyId = account;
     deployment.ec2.ami = "ami-0788e19d09a02414f";
     deployment.ec2.region = region;
     deployment.ec2.subnetId = subnetId;
     deployment.ec2.spotInstancePrice = 999;
     deployment.ec2.instanceType = instanceType;
     deployment.ec2.keyPair = resources.ec2KeyPairs.kp;
     deployment.ec2.ebsInitialRootDiskSize = rootVolumeSize;
     deployment.ec2.securityGroupIds = [ sharedSecurityGroup ];
     deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
     deployment.ec2.tags.owner = "ridha.zorgui@infor.com";
     deployment.ec2.associatePublicIpAddress = true;
     deployment.ec2.elasticIPv4 = resources.elasticIPs.elastic;
     networking.hostName = "${config.deployment.name}.${name}";
     nixops.enableDeprecatedAutoLuks = true;
  
     fileSystems."/data" =
       { autoFormat = true;
         fsType = "xfs";
         device = "/dev/mapper/xvdf";
         ec2.size = 20;
         ec2.disk = resources.ebsVolumes.ssd;
         ec2.volumeType = "gp2";
         ec2.encrypt = true;
       };
  };
  
  resources.elasticIPs.elastic = { inherit region; accessKeyId = account; vpc = true; };

  resources.ec2KeyPairs.kp =
    { inherit region; accessKeyId = account; };
}
