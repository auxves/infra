{ lib, ... }: {
  imports = lib.internal.readModules ./.;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.git.enable = true;

  home.stateVersion = "23.05";
}
