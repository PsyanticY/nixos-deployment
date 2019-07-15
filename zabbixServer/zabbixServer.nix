{ config, lib,  pkgs, resources, ... }:
{
  environment.systemPackages = [ pkgs.zabbix.server pkgs.zabbix.agent ];

  services.zabbixWeb.enable = true;
  services.zabbixWeb.database.type = "mysql";
  services.zabbixWeb.virtualHost = {
    hostName = "zabbix";
    enableSSL = false;
    adminAddr = "webmaster@localhost";
  };

  services.zabbixServer.enable = true;
  services.zabbixServer.package = pkgs.zabbix.server-mysql;
  services.zabbixServer.database.type=  "mysql";
  services.zabbixServer.database.createLocally = true;

  services.zabbixServer.openFirewall = true; 
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
