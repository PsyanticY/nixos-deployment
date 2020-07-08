{ accountsFile  ? ./programmatic-users.nix
, usersInfoFile ? ./normal-users.nix
, ...
}:
{
  defaults = { lib, ... }:

  let
    # todo maybe:
    # Add a function to create admin users

    # import accounts and users set
    accounts = import accountsFile;
    usersInfo = import usersInfoFile;
    # function that will be used to create user's accounts
    CreateAccountUser = user: accountExtraGroups:
    let
      account = builtins.getAttr user accounts;
    in {
      uid = account.uid;
      group = account.group;
      useDefaultShell = true;
      createHome = false; # use false if you are going to create the users home manually on /data
      home = "/home/${user}";
      extraGroups = accountExtraGroups; # Should be a list
    };

    # function that will be used to create users
    CreateUser = user: extraGroups:
      let
        userInfo = builtins.getAttr user usersInfo; # check if we can create it like the account users
      in {
        uid = userInfo.uid;
        group = userInfo.group;
        openssh.authorizedKeys.keys = [ userInfo.publicKey ];
        useDefaultShell = true;
        createHome = true;
        home = "/home/${user}";
        extraGroups = extraGroups;
      };

      # Get user mapping from programmatic users
      getUsers = lib.unique (lib.concatMap (n: (builtins.getAttr n accounts).mapping) (builtins.attrNames accounts));

      getGroups = lib.unique (
        lib.concatMap (n: lib.singleton ((builtins.getAttr n usersInfo).group)) (builtins.attrNames usersInfo)
        ++ lib.concatMap (n: lib.singleton ((builtins.getAttr n accounts).group)) (builtins.attrNames accounts)
        );
      # get for each user the list of accounts he is part of so he can be part of that group
      getAccountsForUser = u:
        lib.concatMap (n: if lib.elem u (builtins.getAttr n accounts).mapping then [ n ] else []) (builtins.attrNames accounts);

      # Create a group for each account

      createAccountsGroup = group:
        {
        };

  in
  {
    # Create user accounts and the normal users mapped to each account.
    users.users =
      with lib;
      listToAttrs (
        map (n: nameValuePair n (CreateAccountUser n [ "wheel" ])) (builtins.attrNames accounts)
        ++ map (u: nameValuePair u (CreateUser u (getAccountsForUser u))) getUsers
      );

    # Create groups, based on the mapping file.
    users.groups = lib.listToAttrs (
      map (n: lib.nameValuePair n (createAccountsGroup n)) (builtins.attrNames accounts)
      ++ map (n: lib.nameValuePair n (createAccountsGroup n)) getGroups
      );
    # Allow user of programmatic users group to run 'sudo su - programmatic', to switch to the corresponding programmatic user.
    security.sudo.configFile = ''
      # Allow users of programmatic groups to sudo to corresponding user.
      ${lib.concatMapStrings (u: ''
        %${u} ALL=(ALL) NOPASSWD:/run/wrappers/bin/su - ${u}
      '') (builtins.attrNames accounts)}
    '';

    # Create home dirs on /data. this is Needed as this should happen on the encrypted disk. or we can just mount the /data to /home instead
    systemd.services.create-home-dirs =
      { description = "Create home dirs for programmatic users.";
        wantedBy = [ "multi-user.target" ];
        script = lib.concatMapStrings (du: ''
          if [[ ! -d /data/home/${du} ]]; then
            mkdir -p -m 0700 /data/home/${du}/.ssh
            touch /data/home/${du}/.ssh/known_hosts
            chmod 0600 /data/home/${du}/.ssh/known_hosts
            chown -R ${du}:${du} /data/home/${du}
          fi
          ln -sfn /data/home/${du} /home/${du}
          if [[ ! -d /data/home/${du}/.nixops ]]; then
            mkdir -p 0700 /data/home/${du}/.nixops
            chown -R ${du}:${du} /data/home/${du}/.nixops
          fi
        '') (builtins.attrNames accounts);

        unitConfig.RequiresMountsFor = [ "/data" ];
      };
  };
}
