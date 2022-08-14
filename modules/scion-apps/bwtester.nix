{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.scion.apps.bwtester;
in
{
  options.services.scion.apps.bwtester = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the scion-app bwtester
      '';
    };

    port = mkOption {
      type = types.int;
      default = 30100;
      description = ''
        Port to pass to scion-bwtestserver
      '';
    };
  };

  config = mkIf cfg.enable {
    services.scion.apps.enable = true;

    systemd.services.scion-bwtester = {
      after = [ "network-online.target" "scion-dispatcher.service" ];
      wants = [ "network-online.target" ];
      partOf = [ "scionlab.target" ];
      wantedBy = [ "scionlab.target" ];

      description = "SCION Bandwidth Tester";
      documentation = [ "https://www.scionlab.org" ];

      serviceConfig = {
        Type = "simple";
        User = "scion";
        Group = "scion";

        WorkingDirectory = "/var/lib/scion";

        RestartSec = 10;
        Restart = "on-failure";
        RemainAfterExit = false;
        KillMode = "control-group";

        ExecStart = "${pkgs.scion-apps}/bin/scion-bwtestserver --listen=:${toString cfg.port}";
      };
    };
  };
}
