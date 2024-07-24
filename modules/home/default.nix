{ lib, pkgs, ... }: {
  imports = lib.readModules ./.;

  home.packages = with pkgs; [
    uutils-coreutils-noprefix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fish.enable = true;

  home.stateVersion = "23.05";
}
