{ lib, ... }: {
  imports = lib.readModules ./.;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fish.enable = true;

  home.stateVersion = "23.05";
}
