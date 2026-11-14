{ inputs, ... }: {
  flake.modules.nixos.harpy = {
    imports = with inputs.self.modules.nixos; [
      default

      tailscale
      gitops
      emulation
    ];

    networking.hostId = "c2079aa6";

    systemd.network.enable = true;
    networking.useNetworkd = true;

    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = ./secrets.yaml;
    };

    meta.addresses = {
      internal.v4 = "100.79.148.31";
      internal.v6 = "fd7a:115c:a1e0::1333:941f";
    };

    system.stateVersion = "23.05";
  };
}
