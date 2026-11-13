{ lib, config, ... }:
let
  cfg = config.presets.development;
in
{
  options.presets.development = with lib; {
    enable = mkEnableOption "Enable development environment";
  };

  config = lib.mkIf cfg.enable {
    presets.home.modules = [{ presets.development.enable = true; }];
  };
}
