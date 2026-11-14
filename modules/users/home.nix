{ inputs, ... }: {
  flake.modules.generic.home = { lib, config, ... }:
    let
      cfg = config.presets.home;
    in
    {
      options.presets.home = with lib; {
        enable = mkEnableOption "Enable home-manager";

        user = mkOption {
          type = types.str;
          default = "arno";
        };

        modules = mkOption {
          type = types.listOf types.anything;
          default = [ ];
        };
      };

      config = lib.mkIf cfg.enable {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.users.${cfg.user}.imports = [ inputs.self.modules.homeManager.home ] ++ cfg.modules;

        users.users.${cfg.user} = {
          openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
        };
      };
    };

  flake.modules.nixos.home = { lib, config, ... }:
    let
      cfg = config.presets.home;
    in
    {
      imports = [
        inputs.self.modules.generic.home
        inputs.home-manager.nixosModules.home-manager
      ];

      config = lib.mkIf cfg.enable {
        users.users.${cfg.user} = {
          home = "/home/${cfg.user}";
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      };
    };

  flake.modules.darwin.home = { lib, config, ... }:
    let
      cfg = config.presets.home;
    in
    {
      imports = [
        inputs.self.modules.generic.home
        inputs.home-manager.darwinModules.home-manager
      ];

      config = lib.mkIf cfg.enable {
        users.users.${cfg.user} = {
          home = "/Users/${cfg.user}";
        };

        system.primaryUser = cfg.user;

        launchd.user.envVariables = {
          PATH = inputs.self.lib.internal.replaceAll
            {
              "$HOME" = config.home-manager.users.${cfg.user}.home.homeDirectory;
              "$USER" = cfg.user;
            }
            config.environment.systemPath;
        }
        // config.home-manager.users.${cfg.user}.home.sessionVariables;
      };
    };
}
