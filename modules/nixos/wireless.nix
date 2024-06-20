{ lib, config, ... }:
let
  cfg = config.modules.wireless;
in
{
  options.modules.wireless = with lib; {
    enable = mkEnableOption "Enable wireless networking";

    module = mkOption {
      type = types.enum [ "iwd" "networkmanager" ];
      default = "iwd";
      description = "The wireless networking system to use";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (cfg.module == "iwd") {
      networking.wireless.iwd = {
        enable = true;
        settings = {
          General.EnableNetworkConfiguration = true;
          Network.NameResolvingService = "systemd";
        };
      };
    })

    (lib.mkIf (cfg.module == "networkmanager") {
      networking.networkmanager.enable = true;
    })
  ]);
}
