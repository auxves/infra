{ self, lib, ... }: {
  imports = lib.internal.readModules ./. ++ [
    self.inputs.sops.darwinModules.sops
  ];

  # https://github.com/nix-darwin/nix-darwin/issues/1392
  users.knownUsers = lib.mkForce [ ];
  users.knownGroups = lib.mkForce [ ];

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 4;
}
