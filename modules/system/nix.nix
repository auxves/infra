{ inputs, ... }:
let
  nix = { lib, config, pkgs, ... }: {
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "auto-allocate-uids" ];
        auto-allocate-uids = true;
        accept-flake-config = true;
        sandbox = true;
        warn-dirty = false;

        substituters = [
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      registry = lib.mapAttrs (_: value: { flake = value; }) (inputs.self.inputs // { infra = inputs.self; });
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };
    };
  };
in
{
  flake.modules.nixos.nix = {
    imports = [ nix ];

    nix.settings = {
      trusted-users = [ "@wheel" ];
      experimental-features = [ "cgroups" ];
      use-cgroups = true;
      auto-optimise-store = true;
    };
  };

  flake.modules.darwin.nix = { lib, ... }: {
    imports = [ nix ];

    nix.settings = {
      trusted-users = [ "@admin" ];
    };

    # https://github.com/nix-darwin/nix-darwin/issues/1392
    users.knownUsers = lib.mkForce [ ];
    users.knownGroups = lib.mkForce [ ];
  };
}
