{ lib, config, ... }:
let
  cfg = config.modules.home;
in
{
  config = lib.mkIf cfg.enable {
    modules.home.modules = [{
      programs.fish.loginShellInit = ''
        /opt/homebrew/bin/brew shellenv | source
      '';
    }];

    launchd.user.envVariables = {
      PATH = config.environment.systemPath;
    }
    // config.environment.variables
    // config.home-manager.users.${cfg.user}.home.sessionVariables;
  };
}
