{ inputs, ... }: {
  flake.modules =
    let
      builders = { lib, config, pkgs, ... }:
        let
          user = "nixremote";

          isVolunteer = h: h.name != config.networking.hostName && h.cfg ? presets.builders && h.cfg.presets.builders.volunteer;
          builderHosts = inputs.self.lib.internal.filterHosts isVolunteer;

          buildRemoteMachine = host: {
            hostName = host.name;
            protocol = "ssh";
            sshUser = user;
            sshKey = config.sops.secrets."builders/key".path;
          } // builtins.removeAttrs host.cfg.presets.builders [ "outsource" "volunteer" ];

          cfg = config.presets.builders;
        in
        {
          options.presets.builders = with lib; {
            outsource = mkEnableOption "Configure this machine to make use of remote builders";
            volunteer = mkEnableOption "Configure this machine to act as a remote builder";

            publicHostKey = mkOption {
              type = types.str;
              description = "The result of running `base64 -w0` on the host public key";
            };

            systems = mkOption {
              type = types.listOf types.str;
              default = [ config.nixpkgs.hostPlatform.system ]
                ++ optionals pkgs.stdenv.isLinux config.boot.binfmt.emulatedSystems
                ++ optionals (config.nixpkgs.hostPlatform.system == "aarch64-darwin") [ "x86_64-darwin" ];
              description = "Supported target systems";
            };

            maxJobs = mkOption {
              type = types.int;
              default = 8;
              description = "Maximum number of jobs to run in parallel";
            };

            speedFactor = mkOption {
              type = types.int;
              default = 1;
              description = "Speed factor for remote builds";
            };

            supportedFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ]
                ++ optionals pkgs.stdenv.isLinux config.nix.settings.system-features
                ++ optionals pkgs.stdenv.isDarwin [ "big-parallel" ];
              description = "Features to enable on remote builders";
            };
          };

          config = lib.mkMerge [
            (lib.mkIf cfg.outsource {
              sops.secrets."builders/key" = {
                sopsFile = "${inputs.self}/modules/hosts/secrets.yaml";
              };

              nix = {
                buildMachines = map buildRemoteMachine builderHosts;
                distributedBuilds = true;
                extraOptions = ''
                  builders-use-substitutes = true
                '';
              };
            })

            (lib.mkIf cfg.volunteer {
              nix.settings.trusted-users = [ user ];

              users.users.${user} = {
                openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKg1i4JIbVH0d+srl6f8dcplkz9b7zhpirmepuU2m/Wd builder" ];
              } // lib.optionalAttrs pkgs.stdenv.isLinux {
                isNormalUser = true;
                home = "/var/lib/${user}";
              };
            })
          ];
        };
    in
    {
      nixos.builders = builders;
      darwin.builders = builders;
    };
}
