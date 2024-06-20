{ lib, config, ... }:
let
  cfg = config.modules.graphical;
in
{
  options.modules.graphical = with lib; {
    enable = mkEnableOption "Enable graphical environment";
  };

  config = lib.mkIf cfg.enable {
    modules.home.modules = [{ modules.graphical.enable = true; }];
  };
}
