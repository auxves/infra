{ inputs, config, lib, ... }: {
  flake.dns.records."*.dev.auxves.dev" =
    let addrs = config.flake.hosts.tide.cfg.meta.addresses.internal; in
    lib.optionals (addrs.v4 != null) [
      { type = "A"; value = addrs.v4; }
    ] ++ lib.optionals (addrs.v6 != null) [
      { type = "AAAA"; value = addrs.v6; }
    ];

  flake.modules.nixos.tide = { config, lib, pkgs, ... }:
    let
      containerAddress = "10.100.0.2";
      hostAddress = "10.100.0.1";

      yaml = pkgs.formats.yaml { };

      devDynamicConfig = yaml.generate "dev.yaml" {
        http = {
          routers = {
            dev = {
              rule = "Host(`*.dev.auxves.dev`)";
              entryPoints = [ "internal" ];
              service = "dev";
              tls = {
                certResolver = "letsencrypt";
                domains = [
                  {
                    main = "*.dev.auxves.dev";
                    sans = [ "dev.auxves.dev" ];
                  }
                ];
              };
            };
          };

          services = {
            dev = {
              loadBalancer = {
                servers = [{ url = "http://${config.containers.dev.localAddress}:80"; }];
              };
            };
          };
        };
      };
    in
    {
      networking.nat = {
        enable = true;
        externalInterface = "lan";
        internalInterfaces = [ "ve-dev" ];
      };

      containers.dev = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = hostAddress;
        localAddress = containerAddress;

        privateUsers = "pick";

        forwardPorts = [
          { protocol = "tcp"; hostPort = 44622; containerPort = 22; }
        ];

        config = { lib, pkgs, ... }: {
          system.stateVersion = "26.05";

          networking.useDHCP = false;
          networking.defaultGateway = hostAddress;
          networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
          networking.useHostResolvConf = lib.mkForce false;
          networking.firewall.allowedTCPPorts = [ 22 80 ];

          networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 5353 ];

          virtualisation.podman = {
            enable = true;
            dockerCompat = true;
            dockerSocket.enable = true;

            autoPrune = {
              enable = true;
              dates = "daily";
              flags = [ "--all" ];
            };

            defaultNetwork.settings.dns_enabled = true;
          };

          virtualisation.oci-containers = {
            backend = "podman";
            containers.traefik = {
              image = "traefik:v3.8.0@sha256:00c9734983e74ae35a1fc18eaee9e9da13f3dde95c4e45b3b8c3b60e0dbd2d17";
              ports = [ "80:80/tcp" ];
              volumes = [ "/run/podman/podman.sock:/var/run/docker.sock:ro" ];
              cmd = [
                "--providers.docker=true"
                "--providers.docker.exposedByDefault=false"
                "--entryPoints.web.address=:80"
              ];
            };
          };

          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "prohibit-password";
          };

          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE auxves"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBdVybiJ58SJHLY7wRVLwjAX675PBbRCzNjJ60ui5wFw dev-agent"
          ];

          environment.systemPackages = with pkgs; [
            curl
            openssl
            iproute2
            neovim

            docker-client
            podman-compose
          ];
        };
      };

      systemd.services."container@dev".serviceConfig = {
        MemoryMax = "16G";
        CPUQuota = "200%";
      };

      # Fix issue with networkd messing up host networking
      systemd.network.networks."20-container-ve-dev" = {
        matchConfig.Name = "ve-dev";
        linkConfig.Unmanaged = true;
      };

      traefik.dynamicConfigs = [ devDynamicConfig ];
    };

  perSystem = { pkgs, lib, ... }: {
    checks.system-dev-container =
      let
        drv = inputs.self.hosts.tide.cfg.containers.dev.config.system.build.toplevel;
        drvPath = builtins.unsafeDiscardStringContext drv.drvPath;
      in
      pkgs.runCommand "system-dev-container-evaluates" { } ''
        echo ${drvPath} > $out
      '';
  };
}
