{ lib, config, pkgs, ... }:
let
  cfg = config.presets.graphical;
in
{
  options.presets.graphical = with lib; {
    enable = mkEnableOption "Enable graphical environment";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Fonts
      inter
      fira-code
    ];

    fonts.fontconfig.enable = true;
  };
}
