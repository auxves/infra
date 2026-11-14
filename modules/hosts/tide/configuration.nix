{ inputs, ... }: {
  flake.modules.nixos.tide = { config, ... }: {
    imports = with inputs.self.modules.nixos; [
      default

      tailscale
      gitops
      emulation
      builders-worker
      users-arno
    ];

    home-manager.users.arno.imports = [
      inputs.self.modules.homeManager.tide
    ];

    builders.worker = {
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUNWcC8vMlNYcHY1bWdQT0dxZ2NSUnVYMXRrS1VQN2dRNVk2SWRKb0YxTHAgcm9vdEB0aWRlCg==";
    };

    networking.hostId = "c2079ac5";

    systemd.network.enable = true;
    networking.useNetworkd = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    # Host connectivity checks due to history of firewall rule issues
    monitoring.checks = [
      {
        name = "tide-ipv4";
        group = "hosts";
        url = "tcp://v4.tide.auxves.dev:443";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[CONNECTED] == true"
        ];
      }
      {
        name = "tide-ipv6";
        group = "hosts";
        url = "tcp://v6.tide.auxves.dev:443";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[CONNECTED] == true"
        ];
      }
    ];

    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = ./secrets.yaml;
    };

    meta.addresses = {
      public.v4 = "162.196.81.91";
      public.v6 = "2600:1700:78c0:130f:2e0:4cff:fe88:9afa";
      internal.v4 = "100.126.20.86";
      internal.v6 = "fd7a:115c:a1e0::3901:1456";
    };

    system.stateVersion = "23.05";
  };

  flake.modules.homeManager.tide = { config, ... }: { };
}
