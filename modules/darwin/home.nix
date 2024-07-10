{ lib, config, ... }:
let
  cfg = config.modules.home;
in
{
  config = lib.mkIf cfg.enable {
    launchd.user.envVariables = {
      PATH = config.environment.systemPath;
    }
    // config.environment.variables
    // config.home-manager.users.${cfg.user}.home.sessionVariables;
  };
}
