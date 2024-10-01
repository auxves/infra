{ self, lib, config, host, pkgs, ... }:
{
  imports = lib.readModules ./. ++ [
    self.inputs.lix.nixosModules.default
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "auto-allocate-uids" ];
      trusted-users = [ "@admin" "@wheel" ];
      auto-allocate-uids = true;
      auto-optimise-store = host.platform != "darwin";
      accept-flake-config = true;
      sandbox = true;
      warn-dirty = false;

      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.lix.systems"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      ];
    };

    registry = lib.mapAttrs (_: value: { flake = value; }) (self.inputs // { infra = self; });
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  networking.hostName = host.name;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
  ];

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  environment.shells = with pkgs; [ fish ];
}
