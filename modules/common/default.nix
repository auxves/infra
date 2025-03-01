{ self, lib, config, host, pkgs, ... }:
{
  imports = lib.readModules ./.;

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
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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

  nixpkgs.hostPlatform = host.system;
}
