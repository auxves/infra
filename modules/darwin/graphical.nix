{ lib, config, ... }:
let
  cfg = config.presets.graphical;
in
{
  config = lib.mkIf cfg.enable {
    services.yabai.enable = true;
    services.skhd.enable = true;
  };
}
