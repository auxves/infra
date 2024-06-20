{ lib, config, pkgs, ... }:
let
  cfg = config.modules.graphical;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      skhd
    ];

    services.yabai = let cfg = import ../../config/yabai.nix; in {
      enable = true;
      config = cfg.config;
      extraConfig = cfg.extra;
    };

    services.skhd = {
      enable = true;
      skhdConfig = import ../../config/skhd.nix;
    };
  };
}
