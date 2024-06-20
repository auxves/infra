{ lib, ... }:
{
  imports = lib.readModules ./.;

  programs.fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.local/bin $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /opt/homebrew/bin /nix/var/nix/profiles/default/bin";

  services.nix-daemon.enable = true;

  fonts.fontDir.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  system.stateVersion = 4;
}
