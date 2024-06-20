{ lib, pkgs, ... }:
{
  imports = lib.readModules ./.;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  time.timeZone = "America/Los_Angeles";

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

  system.stateVersion = "23.05";
}
