{ config, pkgs, lib, ... }:
{
  services.openssh.passwordAuthentication = true;
  services.openssh.challengeResponseAuthentication = false;
  services.openssh.allowSFTP = false;
  services.openssh.logLevel = "VERBOSE";
  services.openssh.extraConfig = lib.mkOrder 50000000 ''
   Subsystem sftp internal-sftp   
   Match Group sftponly
   X11Forwarding no
   AllowTcpForwarding no
   ForceCommand internal-sftp
   ChrootDirectory /home/%u
  '';
}
