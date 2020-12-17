{ config, lib,  pkgs, resources, name, ... }:
let
  gurobi-bin = with pkgs; stdenv.mkDerivation rec {
    pname = "gurobi";
    version = "9.0.0";

    src = with stdenv.lib; fetchurl {
      url = "http://packages.gurobi.com/${versions.majorMinor version}/gurobi${version}_linux64.tar.gz";
      sha256 = "07c48fe0f18097ddca6ddc6f5a276e1548a37b31016d0b8575bb12ec8f44546e";
    };

    sourceRoot = "gurobi${builtins.replaceStrings ["."] [""] version}/linux64";

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ (python.withPackages (ps: [ ps.gurobipy ])) ];

    buildPhase = ''
      cd src/build
      make
      cd ../..
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp bin/* $out/bin/
      rm $out/bin/gurobi.env
      rm $out/bin/gurobi.sh
      rm $out/bin/python3.7
      cp lib/gurobi.py $out/bin/gurobi.sh
      mkdir -p $out/include
      cp include/gurobi*.h $out/include/
      mkdir -p $out/lib
      cp lib/*.jar $out/lib/
      cp lib/libGurobiJni*.so $out/lib/
      cp lib/libgurobi*.so* $out/lib/
      cp lib/libgurobi*.a $out/lib/
      cp src/build/*.a $out/lib/
      mkdir -p $out/share/java
      ln -s $out/lib/gurobi.jar $out/share/java/
      ln -s $out/lib/gurobi-javadoc.jar $out/share/java/
    '';

    #passthru.libSuffix = lib.replaceStrings ["."] [""] majorVersion;
  };
in
{
  environment.variables.GRB_LICENSE_FILE = "/run/keys/gurobi.lic";
  environment.systemPackages = with pkgs; [ vim tree git awscli gurobi-bin];
  deployment.keys."gurobi.lic".text = builtins.readFile <creds/gurobi.lic>;
  nixpkgs.config.allowUnfree = true;
  systemd.services.gurobi = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment.GRB_LICENSE_FILE = "/run/keys/gurobi.lic";
    serviceConfig = {
      ExecStart = "${gurobi-bin}/bin/grb_ts";
      Restart = "always";
      Type = "forking";
      TimeoutStartSec = "infinity";
    };
    path = [ gurobi-bin ];
  };
}
