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
  systemd.services."ansible-setup" =
    { description = "setting up some stuff for ansible";
      wantedBy = [ "multi-user.target" ];
      script =
        ''
           if [ ! -e /home/ansible/.ansible.cfg ]; then
             echo "hello"
             mkdir -p /data/home/ansible/.ansible
             chown ansible:ansible /data/home/ansible/.ansible
             curl https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg --output /tmp/.ansible.cfg
             temp_checksum=$(sha256sum /tmp/.ansible.cfg | cut -d " " -f 1 )
             if [ "f186f1018832fd926722c7dc4138dbcba7bb7398a361e826a641bd9312789d70" == "$temp_checksum" ]; then
               cp /tmp/.ansible.cfg /home/ansible/.ansible.cfg
               sed -i 's/#inventory       = \/etc\/ansible\/hosts/inventory       = \/home\/ansible\/.ansible\/hosts/g' /home/ansible/.ansible.cfg
               chown ansible:ansible /data/home/ansible/.ansible.cfg
               chmod 600 /data/home/ansible/.ansible.cfg
             else
               rm -rf /tmp/.ansible.cfg
               echo "WARNING: cheksum do not match"
               exit 1
             fi
             touch /home/ansible/.ansible/hosts
             chmod 600 /home/ansible/.ansible/hosts
             chown ansible:ansible /home/ansible/.ansible/hosts
             echo "INFO: Ansible setup is done" 
           fi
        '';
      unitConfig.RequiresMountsFor = [ "/data" ];
      path = with pkgs; [ curl ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
}
