{ config, lib,  pkgs, resources, name, ... }:
{
 environment.systemPackages = with pkgs; [ vim tree docker-compose ];
 virtualisation.docker.enable = true;
}