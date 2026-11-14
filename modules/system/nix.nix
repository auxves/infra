{ inputs, ... }: {
  flake.modules =
    let
      nix = { lib, config, pkgs, ... }: {
        nix = {
          settings = {
            experimental-features = [ "nix-command" "flakes" "auto-allocate-uids" ];
            trusted-users = [ "@admin" "@wheel" ];
            auto-allocate-uids = true;
            auto-optimise-store = !pkgs.stdenv.isDarwin;
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
      nixos.nix = nix;
      darwin.nix = nix;
    };
}
