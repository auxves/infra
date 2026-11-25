{ ... }: {
  flake.modules.nixos.tide = { config, lib, pkgs, ... }:
    let
      containerAddress = "10.100.0.2";
      hostAddress = "10.100.0.1";

      installScript = pkgs.fetchurl {
        url = "https://github.com/Dokploy/dokploy/releases/download/v0.31.2/install.sh";
        sha256 = "sha256-eSchowuniPIf6kL/165U/RWM02alASFZITgGgRIYjzI=";
      };

      yaml = pkgs.formats.yaml { };

      dynamicConfig = yaml.generate "dokploy-dynamic.yaml" {
        http = {
          routers = {
            dokploy-dev = {
              rule = "HostRegexp(`^[^.]+\\.dev\\.auxves\\.dev$`)";
              entryPoints = [ "internal" ];
              service = "dokploy-dev";
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

            dokploy-dashboard = {
              rule = "Host(`dokploy.tide.x.auxves.dev`)";
              entryPoints = [ "internal" ];
              service = "dokploy-dashboard";
              tls = {
                certResolver = "letsencrypt";
                domains = [
                  {
                    main = "tide.x.auxves.dev";
                    sans = [ "*.tide.x.auxves.dev" ];
                  }
                ];
              };
            };
          };

          services = {
            dokploy-dev = {
              loadBalancer = {
                servers = [{ url = "https://${containerAddress}:443"; }];
              };
            };

            dokploy-dashboard = {
              loadBalancer = {
                servers = [{ url = "http://${containerAddress}:3000"; }];
              };
            };
          };
        };
      };
    in
    {
      boot.kernelModules = [ "vxlan" ];

      networking.nat = {
        enable = true;
        externalInterface = "lan";
        internalInterfaces = [ "ve-dokploy-dev" ];
      };

      networking.firewall.trustedInterfaces = [ "ve-dokploy-dev" ];

      system.activationScripts.ensure-dokploy-dev-datasets.text = ''
        ${pkgs.zfs}/bin/zfs create -p storage/services/dokploy-dev/etc
        ${pkgs.zfs}/bin/zfs create -p storage/services/dokploy-dev/docker
      '';

      containers.dokploy-dev = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = hostAddress;
        localAddress = containerAddress;

        extraFlags = [
          "--system-call-filter=keyctl"
          "--system-call-filter=bpf"
        ];

        bindMounts = {
          dokploy-config = {
            hostPath = "/storage/services/dokploy-dev/etc";
            mountPoint = "/etc/dokploy";
            isReadOnly = false;
          };

          docker-data = {
            hostPath = "/storage/services/dokploy-dev/docker";
            mountPoint = "/var/lib/docker";
            isReadOnly = false;
          };
        };

        config = { pkgs, ... }: {
          system.stateVersion = "26.05";

          networking.useNetworkd = true;
          networking.useDHCP = false;
          networking.defaultGateway = hostAddress;
          networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
          networking.firewall.allowedTCPPorts = [ 80 443 3000 ];

          virtualisation.docker.enable = true;

          environment.systemPackages = [ pkgs.curl pkgs.openssl pkgs.iproute2 ];

          systemd.services.dokploy-install = {
            description = "Install Dokploy";
            after = [ "docker.service" "network-online.target" ];
            wants = [ "network-online.target" ];
            requires = [ "docker.service" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };

            script = ''
              set -euo pipefail

              if [ -e /etc/dokploy/.installed ]; then
                exit 0
              fi

              for _ in $(seq 1 30); do
                if docker info >/dev/null 2>&1; then
                  break
                fi
                sleep 2
              done

              export DOKPLOY_VERSION=v0.31.2
              export ADVERTISE_ADDR=${containerAddress}
              export ENDPOINT_MODE=dnsrr

              bash ${installScript}
              touch /etc/dokploy/.installed
            '';

            wantedBy = [ "multi-user.target" ];
          };
        };
      };

      apps.traefik.containers.traefik.volumes = [ "${dynamicConfig}:/etc/traefik/dynamic.yaml" ];
    };
}
