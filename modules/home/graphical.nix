{ lib, config, pkgs, ... }:
let
  cfg = config.modules.graphical;
in
{
  options.modules.graphical = with lib; {
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
