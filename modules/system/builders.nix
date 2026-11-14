{ inputs, ... }:
let
  user = "nixremote";
  clientPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKg1i4JIbVH0d+srl6f8dcplkz9b7zhpirmepuU2m/Wd builder";

  client = { lib, config, ... }:
    let
      isBuilder = h:
        h.name != config.networking.hostName
        && lib.hasAttrByPath [ "builders" "worker" ] h.cfg;

      toMachine = host:
        let b = host.cfg.builders.worker; in {
          hostName = host.name;
          protocol = "ssh";
          sshUser = user;
          sshKey = config.sops.secrets."builders/key".path;
          inherit (b) publicHostKey systems maxJobs speedFactor supportedFeatures;
        };
    in
    {
      sops.secrets."builders/key".sopsFile = "${inputs.self}/modules/hosts/secrets.yaml";

      nix = {
        buildMachines = map toMachine (inputs.self.lib.internal.filterHosts isBuilder);
        distributedBuilds = true;
        settings.builders-use-substitutes = true;
      };
    };

  worker = { lib, config, pkgs, ... }: {
    options.builders.worker = with lib; {
      publicHostKey = mkOption {
        type = types.str;
        description = "The result of running base64 -w0 on the host public key";
      };

      systems = mkOption {
        type = types.listOf types.str;
        default = [ config.nixpkgs.hostPlatform.system ]
          ++ optionals pkgs.stdenv.isLinux config.boot.binfmt.emulatedSystems;
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

    config = {
      nix.settings.trusted-users = [ user ];
      users.users.${user} = {
        openssh.authorizedKeys.keys = [ clientPublicKey ];
      } // lib.optionalAttrs pkgs.stdenv.isLinux {
        isNormalUser = true;
        home = "/var/lib/${user}";
      };
    };
  };
in
{
  flake.modules.nixos.builders-client = client;
  flake.modules.nixos.builders-worker = worker;

  flake.modules.darwin.builders-client = client;
  flake.modules.darwin.builders-worker = worker;
}
