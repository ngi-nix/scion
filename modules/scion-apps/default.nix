{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.scion.apps;
in
{
  options.services.scion.apps = {
    enable = mkOption {
      type = types.bool;
      default = false;
      internal = true;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enable -> config.services.scionlab.enable;
        message = "Using scion-apps requires a SCION AS";
      }
    ];

    environment.systemPackages = with pkgs; [ scion-apps ];
  };
}
