{ self, lib, pkgs, ... }: {
  imports = lib.internal.readModules ./. ++ [
    self.inputs.lanzaboote.nixosModules.lanzaboote
    self.inputs.disko.nixosModules.disko
    self.inputs.comin.nixosModules.comin
    self.inputs.sops.nixosModules.sops
  ];

  nix.settings = {
    experimental-features = [ "cgroups" ];
    use-cgroups = true;
  };

  systemd.network.enable = lib.mkDefault true;
  networking.useNetworkd = lib.mkDefault true;

  users.defaultUserShell = pkgs.fish;

  environment.defaultPackages = [ ];

  programs.nix-ld.enable = true;
  programs.command-not-found.enable = false;

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
  };

  services.openssh.extraConfig = ''
    Include /etc/ssh/sshd_config.d/*
  '';

  programs.ssh.extraConfig = ''
    Include /etc/ssh/ssh_config.d/*
  '';

  security.pam.sshAgentAuth.enable = true;

  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
  };

  system.stateVersion = "23.05";
}
