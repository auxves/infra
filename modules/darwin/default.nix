{ self, lib, ... }: {
  imports = lib.internal.readModules ./. ++ [
    self.inputs.sops.darwinModules.sops
  ];

  # https://github.com/nix-darwin/nix-darwin/issues/1392
  users.knownUsers = lib.mkForce [ ];
  users.knownGroups = lib.mkForce [ ];

  programs.fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.local/bin $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin";

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 4;
}
