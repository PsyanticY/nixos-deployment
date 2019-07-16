{ region ? "us-east-1"
, zone ? "us-east-1a"
, account ? "ops"
, vpcId ? "vpc-xxxxxxx"
, subnetId ? "subnet-xxxxxx"
, sharedSecurityGroup ? "sg-xxxxxxx"
, instanceType ? "m5.large"
, rootVolumeSize ? 20
, hostName ? "dovah.kin.com"
, description ? "ftp server"
, spotInstancePrice ? 0
, category ? "Production"
, ...
}:
{
  ftp =
  { lib, pkgs, config, resources, ... }:
  {   
     require = [ ./network.nix ];
     deployment.targetEnv = "ec2";
     deployment.ec2.accessKeyId = account;
     deployment.ec2.region = region;
     deployment.ec2.subnetId = subnetId;
     deployment.ec2.instanceProfile = resources.iamRoles.role.name;
     deployment.ec2.spotInstancePrice = lib.mkDefault spotInstancePrice;
     deployment.ec2.spotInstanceRequestType = "persistent";
     deployment.ec2.spotInstanceInterruptionBehavior = "stop";
     deployment.ec2.instanceType = instanceType;
     deployment.ec2.keyPair = resources.ec2KeyPairs.kp;
     deployment.ec2.ebsInitialRootDiskSize = rootVolumeSize;
     deployment.ec2.securityGroupIds = [ sharedSecurityGroup resources.ec2SecurityGroups.sg.name ];
     deployment.ec2.tags.Name = "${hostName}";
     deployment.ec2.tags.Owner = "dovah@kin.com";
     deployment.ec2.tags.Category = category;
     deployment.ec2.associatePublicIpAddress = true;
     deployment.ec2.elasticIPv4 = resources.elasticIPs.ftpIp;
     networking.hostName = hostName;

     fileSystems."/home" =
       { autoFormat = true;
         fsType = "xfs";
         device = "/dev/mapper/nvme1n1";
         ec2.size = 50;
         ec2.volumeType = "gp2";
         ec2.encrypt = true;
         ec2.disk = resources.ebsVolumes.ebs;
     };
  };

  resources.route53RecordSets.ftpdns = 
   {resources, ...}:
   {
    accessKeyId = account;
    zoneName = "kin.com.";
    domainName = "${hostName}.";
    routingPolicy = "simple";
    recordType = "A";
    recordValues = [resources.machines.ftp];
  };

  resources.iamRoles.role =
  {
    accessKeyId = account;
    policy = builtins.toJSON {
      Statement = [
        {
          Action =
            [ 
              "ses:SendEmail"
              "ses:SendRawEmail"
            ];
          Effect = "Allow";
          Resource = "*";
        }
        {
          "Effect" = "Allow";
          "Action" = ["cloudwatch:PutMetricData"];
          "Resource" = "*" ;
        }
      ];
    };
  };

  network.description = "ftp server network";

  resources.elasticIPs.ftpIp = { inherit region; accessKeyId = account; vpc = true; };
  
  resources.ec2SecurityGroups.sg =
     { config, resources, ... }:
    let 
      entry = ip:
        {
          fromPort = 22;
          toPort = 22;
          sourceIp = if builtins.isString ip then "${ip}" else ip;
        } ;
      ips =  [ "0.0.0.0/0" ];
    in
      {
        inherit region vpcId;
        accessKeyId = account;
        description = "Security group for ftp server";
        rules = map entry ips;
        name = "ftp-security-group";
      };

  resources.ebsVolumes.ebs =
  {  region = region;
     accessKeyId = account;
     size = 500;
     volumeType = "gp2";
     zone = zone;
  };
 
  resources.ec2KeyPairs.kp =
    { inherit region; accessKeyId = account; };
}
