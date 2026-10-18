{ self, ... }: {
  imports = [
    self.inputs.sops.nixosModules.sops
    ./hardware.nix
    ./services
  ];

  presets = {
    containers.enable = true;
    emulation.enable = true;
    gitops.enable = true;
  };

  networking.hostId = "c2079aa6";

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
  };

  systemd.network.enable = true;
  networking.useNetworkd = true;

  services.tailscale.enable = true;

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  meta.addresses = {
    internal.v4 = "100.79.148.31";
    internal.v6 = "fd7a:115c:a1e0::1333:941f";
  };

  system.stateVersion = "23.05";
}
