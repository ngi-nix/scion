{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.rains;
in
{
  options.services.rains = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable RAINS, Another Internet Naming Service
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ rains ];

    systemd.services.rains = {};
  };
}
