{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.scion.apps.webapp;
in
{
  options.services.scion.apps.webapp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the scion-app webapp
      '';
    };
  };

  config = mkIf cfg.enable {
    services.scion.apps.enable = true;

    systemd.services.scion-webapp = {
      after = [ "network-online.target" "scion-dispatcher.service" ];
      wants = [ "network-online.target" ];
      partOf = [ "scionlab.target" ];
      wantedBy = [ "scionlab.target" ];

      description = "SCION Web App";
      documentation = [ "https://www.scionlab.org" ];
      path = with pkgs; [
        bash gawk gnused coreutils curl gnugrep
        (python3.withPackages (p: with p; [ supervisor ]))
        procps nettools which
        scion scion-apps
      ];

      serviceConfig = {
        Type = "simple";
        User = "scion";
        Group = "scion";

        WorkingDirectory = "/var/lib/scion";
        Environment = "SCION_ROOT=${pkgs.scion}";

        RestartSec = 10;
        Restart = "on-failure";
        RemainAfterExit = false;
        KillMode = "control-group";
      };

      script = ''
        cp -rf --no-preserve=all ${pkgs.scion-apps}/share/scion-webapp .
        mkdir -p scion-webapp/data

        ${pkgs.scion-apps}/bin/scion-webapp -r /var/lib/scion/scion-webapp/data \
          -sgen /etc/scion -sgenc /var/lib/scion/gen-cache \
          -srvroot /var/lib/scion/scion-webapp
      '';
    };
  };
}
