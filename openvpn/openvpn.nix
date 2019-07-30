{ config, lib,  pkgs, resources, name, ... }:
let
  inherit (pkgs) openvpn;
  vpnConfig = pkgs.writeText "openvpn-config-${name}" 
    ''
      # Certs

      ca /run/openvpn/ca.crt
      cert /run/openvpn/vpn.crt
      key /run/openvpn/vpn.key
      dh /run/openvpn/dh.pem
      crl-verify /run/openvpn/crl.pem

      # Network configuration
      ## "dev tun" will create a routed IP tunnel
      dev tun
      port 1194
      proto tcp
      server 10.0.2.0 255.255.255.0
      
      keepalive 10 120
      comp-lzo
      persist-key
      persist-tun
      
      # Logging
      log-append /var/log/openvpn/openvpn.log
      verb 4
      mute 5
      
      # Security Config
      ## Use AES-256-CBC (Cipher Block Chaining) for data encryption
      cipher AES-256-CBC
      ## Use SHA512 to authenticate encrypted data
      auth SHA512
      ## Use at least the version 1.2 of TLS (which is the only truly secure version atm)
      ## Maximum number of output packets queued before TCP (default=64)
      tcp-queue-limit 512
      bcast-buffers 4096
      ## Ldap auth
      plugin ${openvpn}/lib/openvpn/plugins/openvpn-plugin-auth-pam.so vpn
      client-cert-not-required
      username-as-common-name
      
      # Push configuration
      #VPN internal
      push "dhcp-option DOMAIN dovah.kin ";
      push "dhcp-option DNS 8.8.8.8 ";
      push "route  10.0.2.0 255.255.255.0 ";
      #AWS
      ### ...
      push "route 52.80.0.0 255.248.0.0 ";
      push "route 99.80.0.0 255.54.0.0 ";

    '';
    
in
{
  environment.systemPackages = [ openvpn ];

  boot.kernelModules = [ "tun" ];
  
  systemd.services.openvpn = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    preStart = ''
      if test ! -d /var/log/openvpn
      then
        mkdir -p /var/log/openvpn -m 0750
      fi
    '';
    serviceConfig = {
      ExecStart = "@${openvpn}/sbin/openvpn openvpn --suppress-timestamps --config ${vpnConfig}";
      Restart = "on-failure";
      TimeoutStartSec = "infinity";
    };
    path = [ pkgs.iptables pkgs.iproute pkgs.nettools ];
  };
  networking.firewall.allowedTCPPorts = [ 1194 ];
  deployment.keys = {
    "ca.crt".text = builtins.readFile <creds/openvpn/ca.crt>;
    "dh.pem".text = builtins.readFile <creds/openvpn/dh.pem>;
    "crl.pem".text = builtins.readFile <creds/openvpn/crl.pem>;
    "vpn.key".text = builtins.readFile <creds/openvpn/vpn.key>;
    "vpn.crt".text = builtins.readFile <creds/openvpn/vpn.crt>;
    "dh.pem".destDir = "/run/openvpn";
    "ca.crt".destDir = "/run/openvpn";
    "crl.pem".destDir = "/run/openvpn";
    "vpn.key".destDir = "/run/openvpn";
    "vpn.crt".destDir = "/run/openvpn";
    "ldap.crt".text = builtins.readFile <creds/ldap/ca.crt>;
    "ldap.key".text = builtins.readFile <creds/ldap/ldap_tls.key>;
    "ldap.pem".text = builtins.readFile <creds/ldap/ldap_tls.pem>;
    };

  security.pam.services.vpn.text = ''
    auth        sufficient    ${pkgs.sssd}/lib/security/pam_sss.so forward_pass
    auth        required      pam_deny.so
    
    account     [default=bad success=ok user_unknown=ignore] ${pkgs.sssd}/lib/security/pam_sss.so
    account     required      pam_permit.so
    
    password    sufficient    ${pkgs.sssd}/lib/security/pam_sss.so use_authtok
    password    required      pam_deny.so
    
    session     required      pam_unix.so
    session     sufficent      ${pkgs.sssd}/lib/security/pam_sss.so
  '';
  services.sssd.enable = true;
  services.sssd.config = ''
    [domain/default]
    cache_credentials = False
    ldap_search_base = dc=dovah,dc=kin
    ldap_uri = ldaps://lolz.dovah.kin
    ldap_user_search_base = cn=users,cn=accounts,dc=dovah,dc=kin
    id_provider = ldap
    auth_provider = ldap
    chpass_provider = ldap
    ldap_user_ssh_public_key = ipaSshPubKey
    # change those if you want to use another path to the keys
    ldap_tls_cert = /run/keys/ldap.pem
    ldap_tls_key = /run/keys/ldap.key
    ldap_tls_cacert = /run/keys/ldap.crt
    ldap_id_use_start_tls = True
    override_shell = /run/current-system/sw/bin/bash
    [sssd]
    config_file_version = 2
    services = nss, pam, ssh
    domains = default
    [nss]
    memcache_timeout = 2
    homedir_substring = /home
    [pam]
    [ssh]
  '';
  
}

