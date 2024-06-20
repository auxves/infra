{ self, lib, config, host, pkgs, ... }:
{
  imports = lib.readModules ./.;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@admin" "@wheel" ];
      auto-optimise-store = true;
      sandbox = true;
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };

    extraOptions = ''
      flake-registry = /global-registry-i-dont-think-so
    '';

    registry = lib.mapAttrs (_: value: { flake = value; }) (self.inputs // { inherit self; });
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
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
