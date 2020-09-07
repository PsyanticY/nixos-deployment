{ config, lib,  pkgs, resources, name, ... }:
{
 environment.systemPackages = with pkgs; [ vim tree docker-compose git awscli terraform nodejs ];
 virtualisation.docker.enable = true;
}
