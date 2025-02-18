{ self, lib, ... }: {
  imports = lib.readModules ./. ++ [
    self.inputs.sops.darwinModules.sops
  ];

  programs.fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.local/bin $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin";

  services.nix-daemon.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  system.stateVersion = 4;
}
