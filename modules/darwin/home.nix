{ lib, config, ... }:
let
  cfg = config.presets.home;
in
{
  config = lib.mkIf cfg.enable {
    launchd.user.envVariables = {
      PATH = lib.replaceAll
        {
          "$HOME" = config.home-manager.users.${cfg.user}.home.homeDirectory;
          "$USER" = cfg.user;
        }
        config.environment.systemPath;
    }
    // config.home-manager.users.${cfg.user}.home.sessionVariables;
  };
}
