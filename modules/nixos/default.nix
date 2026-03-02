{ lib, pkgs, ... }: {
  imports = lib.internal.readModules ./.;

  nix.settings = {
    experimental-features = [ "cgroups" ];
    use-cgroups = true;
  };

  users.defaultUserShell = pkgs.fish;

  environment.defaultPackages = [ ];

  programs.nix-ld.enable = true;
  programs.command-not-found.enable = false;

  services.openssh.enable = lib.mkDefault true;
  services.openssh.settings = {
    PasswordAuthentication = lib.mkDefault false;
  };

  services.openssh.extraConfig = ''
    Include /etc/ssh/sshd_config.d/*
  '';

  programs.ssh.extraConfig = ''
    Include /etc/ssh/ssh_config.d/*
  '';

  security.pam.sshAgentAuth.enable = lib.mkDefault true;

  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
  };
}
