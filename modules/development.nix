{ lib, config, ... }:
let
  cfg = config.modules.development;
in
{
  options.modules.development = with lib; {
    enable = mkEnableOption "Enable development environment";
  };

  config = lib.mkIf cfg.enable {
    modules.home.modules = [{ modules.development.enable = true; }];
  };
}
