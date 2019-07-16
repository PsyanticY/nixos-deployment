{ pkgs, lib, ... }:
  let
    sftpUsersInfo = import ./sftp-user-info.nix;

    mkSftpUser = user:
    let
      account = builtins.getAttr user sftpUsersInfo;
    in {
      uid = account.uid;
      group = "sftponly";
      hashedPassword = account.hashedPassword;
      createHome = false;
      useDefaultShell = true;
      home = "/home/${user}";
    };

  in
  {
    users.users =
      with lib;
      listToAttrs (
        map (u: nameValuePair u (mkSftpUser u )) (builtins.attrNames sftpUsersInfo)
      );

    users.groups."sftponly" = {};
    #users.mutableUsers = lib.mkOverride 5 false;
    systemd.services.create-home-dirs =
     { description = "Create home dirs for sftp users.";
       wantedBy = [ "multi-user.target" ];
       script = lib.concatMapStrings (u: ''
         if [[ ! -d /home/${u} ]]; then
           mkdir -p -m 0700 /home/${u}/.ssh
           touch /home/${u}/.ssh/known_hosts
           chmod 0600 /home/${u}/.ssh/known_hosts
           chown root:root /home/${u}
           mkdir -p /home/${u}/toPDX
           mkdir -p /home/${u}/fromPDX
           chown ${u}:sftponly /home/${u}/toPDX
           chown ${u}:sftponly /home/${u}/fromPDX
         fi
       '') (builtins.attrNames sftpUsersInfo);
       unitConfig.RequiresMountsFor = [ "/home" ];
     };
  }