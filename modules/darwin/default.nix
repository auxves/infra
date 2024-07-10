{ lib, ... }:
{
  imports = lib.readModules ./.;

  programs.fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.local/bin $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin";

  services.nix-daemon.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  nix.settings.sandbox = lib.mkForce false;

  system.stateVersion = 4;
}
