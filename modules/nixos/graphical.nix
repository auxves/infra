{ lib, config, pkgs, ... }:
let
  cfg = config.presets.graphical;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kitty
    ];

    programs.hyprland.enable = true;
  };
}
