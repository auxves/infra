{ lib, ... }: {
  imports = lib.readModules ./.;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fish.enable = true;
  programs.git.enable = true;

  home.stateVersion = "23.05";
}
