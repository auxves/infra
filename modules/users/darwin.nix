{ lib, config, ... }:
let
  cfg = config.presets.home;
in
{
  config = lib.mkIf cfg.enable {
    system.primaryUser = cfg.user;

    launchd.user.envVariables = {
      PATH = lib.internal.replaceAll
        {
          "$HOME" = config.home-manager.users.${cfg.user}.home.homeDirectory;
          "$USER" = cfg.user;
        }
        config.environment.systemPath;
    }
    // config.home-manager.users.${cfg.user}.home.sessionVariables;
  };
}
