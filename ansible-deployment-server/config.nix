{ config, lib,  pkgs, resources, name, ... }:
{
  environment.systemPackages = with pkgs; [ vim tree stress awscli ansible_2_9 ansible-lint ];
  deployment.keys."id_rsa.pub".text = builtins.readFile <creds/playground/id_rsa.pub>;
  deployment.keys."id_rsa".text = builtins.readFile <creds/playground/id_rsa>;
  systemd.services."ssh-keys" =
    { description = "SSH keys";
      wantedBy = [ "multi-user.target" ];
      script =
        ''
        mkdir -p /data/home/ansible/.ssh
        cp /run/keys/id_rsa /data/home/ansible/.ssh/
        cp /run/keys/id_rsa.pub /data/home/ansible/.ssh/
        chmod 700 /data/home/ansible/.ssh
        chmod 600 /data/home/ansible/.ssh/id_rsa
        chmod 600 /data/home/ansible/.ssh/id_rsa.pub
        chown -R ansible:ansible /data/home/ansible/.ssh
        '';
      unitConfig.RequiresMountsFor = [ "/data" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
    # to do: 
    # add .ansible.cfg to home folder of ansible
    # change the inventory location and create it somewhere accessible by ansible user
}
