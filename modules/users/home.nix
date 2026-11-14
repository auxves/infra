{ inputs, ... }: {
  flake.modules =
    let
      home = variant: { lib, config, ... }:
        let
          cfg = config.presets.home;
        in
        {
          imports = [ inputs.home-manager."${variant}Modules".home-manager ];

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

          config = lib.mkIf cfg.enable (lib.mkMerge [
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.${cfg.user}.imports = [ inputs.self.modules.homeManager.home ] ++ cfg.modules;

              users.users.${cfg.user} = {
                openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
              } // lib.optionalAttrs (variant == "nixos") {
                home = "/home/${cfg.user}";
                isNormalUser = true;
                extraGroups = [ "wheel" ];
              } // lib.optionalAttrs (variant == "darwin") {
                home = "/Users/${cfg.user}";
              };
            }

            (lib.optionalAttrs (variant == "darwin") {
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
            })
          ]);
        };
    in
    {
      nixos.home = home "nixos";
      darwin.home = home "darwin";
    };
}
