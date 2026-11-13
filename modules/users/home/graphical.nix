{ lib, config, host, pkgs, ... }:
let
  cfg = config.presets.graphical;
in
{
  options.presets.graphical = with lib; {
    enable = mkEnableOption "Enable graphical environment";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = with pkgs; [
        # Fonts
        inter
        fira-code
      ];

      fonts.fontconfig.enable = true;
    }

    (lib.mkIf (host.platform == "darwin") {
      services.yabai.enable = true;
      services.skhd.enable = true;
    })
  ]);
}
