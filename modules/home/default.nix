{ lib, ... }:
{
  imports = lib.readModules ./.;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
  };

  home.stateVersion = "23.05";
}
