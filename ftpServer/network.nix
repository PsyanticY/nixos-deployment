{ config, pkgs, lib, ... }:
{
  require = [ ./ssh_config.nix ./sftp-users.nix ];

  time.timeZone = "UTC";


  # fail2ban
  services.fail2ban.enable = true;
  systemd.services.fail2ban.path = [ pkgs.fail2ban pkgs.iptables pkgs.iproute pkgs.postfix ];
  services.fail2ban.jails.ssh-iptables = lib.mkOverride 10 ''
    filter   = sshd
    action   = iptables-multiport[name=SSH, port="${lib.concatMapStringsSep "," (p: toString p) config.services.openssh.ports}", protocol=tcp]
    maxretry = 5
  '';
  # fix postifx and add this to actions
  #sendmail-whois[name=SSH, dest=dovah@kin.com, sender=noreply@kin.com]
  services.postfix.enable = true;

  environment.shellInit = ''
    export EDITOR=vim
    export HISTFILESIZE=50000
    export HISTCONTROL=erasedups
    shopt -s histappend
    export PROMPT_COMMAND="history -a"
    export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S - '
    export PYTHONDONTWRITEBYTECODE=1
  '';

  programs.bash.enableCompletion = true;


  # Globally installed packages.
  environment.systemPackages = with pkgs;
    [ cryptsetup curl lsof nmap tcpdump vim wget awscli fio gnupg jq python3 ];
    
   # Allow admin users to sudo using their SSH agent.
   security.pam.enableSSHAgentAuth = true;
}
