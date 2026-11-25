{ config, lib, ... }: {
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
              rule = "HostRegexp(`^[^.]+\\.dev\\.auxves\\.dev$`)";
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
      # Podman inside the container cannot load kernel modules, so the host
      # preloads the modules it needs.
      boot.kernelModules = [ "bridge" "veth" "br_netfilter" "xt_nat" "overlay" ];

      networking.nat = {
        enable = true;
        externalInterface = "lan";
        internalInterfaces = [ "ve-dev" ];
      };

      networking.firewall.trustedInterfaces = [ "ve-dev" ];

      containers.dev = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = hostAddress;
        localAddress = containerAddress;

        extraFlags = [
          "--system-call-filter=keyctl"
          "--system-call-filter=bpf"
          "--system-call-filter=add_key"
        ];

        config = { lib, pkgs, ... }: {
          system.stateVersion = "26.05";

          networking.useNetworkd = true;
          networking.useDHCP = false;
          networking.defaultGateway = hostAddress;
          networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
          networking.firewall.allowedTCPPorts = [ 22 80 ];

          # The container cannot load kernel modules; the host
          # preloads them instead, so nothing is left to load inside.
          boot.kernelModules = lib.mkForce [ ];

          virtualisation.podman = {
            enable = true;
          };

          # Prod Traefik forwards *.dev to :80; this routes by label to the test apps.
          # Traefik v3.8 has no native Podman provider, so the Docker provider
          # reads Podman's Docker-compatible API through the Podman socket.
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
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBdVybiJ58SJHLY7wRVLwjAX675PBbRCzNjJ60ui5wFw dev-agent"
          ];

          environment.systemPackages = [ pkgs.curl pkgs.openssl pkgs.iproute2 ];
        };
      };

      traefik.dynamicConfigs = [ devDynamicConfig ];
    };
}
