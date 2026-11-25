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

      dockerRoot = "/storage/services/dev-docker";

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
                servers = [{ url = "https://${config.containers.dev.localAddress}:443"; }];
              };
            };
          };
        };
      };
    in
    {
      # Docker inside the container cannot load kernel modules, so the host
      # preloads the modules dockerd needs.
      boot.kernelModules = [ "bridge" "veth" "br_netfilter" "xt_nat" "overlay" ];

      networking.nat = {
        enable = true;
        externalInterface = "lan";
        internalInterfaces = [ "ve-dev" ];
      };

      networking.firewall.trustedInterfaces = [ "ve-dev" ];

      fileSystems."${dockerRoot}" = {
        device = "/dev/zvol/storage/services/dev-docker";
        fsType = "ext4";
      };

      system.activationScripts.ensure-dev-storage.text = ''
        if ! ${pkgs.zfs}/bin/zfs list -H -o name storage/services/dev >/dev/null 2>&1; then
          ${pkgs.zfs}/bin/zfs create -p -o mountpoint=/var/lib/nixos-containers/dev storage/services/dev
        fi
        if ! ${pkgs.zfs}/bin/zfs list -H -o name -t volume storage/services/dev-docker >/dev/null 2>&1; then
          ${pkgs.zfs}/bin/zfs create -V 30G storage/services/dev-docker
        fi
        if ! ${pkgs.util-linux}/bin/blkid -o value -s TYPE /dev/zvol/storage/services/dev-docker >/dev/null 2>&1; then
          ${pkgs.e2fsprogs}/bin/mkfs.ext4 -q /dev/zvol/storage/services/dev-docker
        fi
      '';

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

        bindMounts = {
          docker-data = {
            hostPath = dockerRoot;
            mountPoint = "/var/lib/docker";
            isReadOnly = false;
          };
        };

        config = { lib, pkgs, ... }: {
          system.stateVersion = "26.05";

          networking.useNetworkd = true;
          networking.useDHCP = false;
          networking.defaultGateway = hostAddress;
          networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
          networking.firewall.allowedTCPPorts = [ 22 443 ];

          # The docker module loads its kernel modules here; the host
          # preloads them instead, so nothing is left to load inside.
          boot.kernelModules = lib.mkForce [ ];

          virtualisation.docker = {
            enable = true;
            storageDriver = "overlay2";
            daemon.settings = {
              default-address-pools = [
                { base = "10.200.0.0/16"; size = 24; }
              ];
            };
          };

          # Prod Traefik forwards *.dev to :443; this routes by label to the test apps.
          virtualisation.oci-containers = {
            backend = "docker";
            containers.traefik = {
              image = "traefik:v3.8.0@sha256:00c9734983e74ae35a1fc18eaee9e9da13f3dde95c4e45b3b8c3b60e0dbd2d17";
              ports = [ "443:443/tcp" ];
              volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
              cmd = [
                "--providers.docker=true"
                "--providers.docker.exposedByDefault=false"
                "--entryPoints.websecure.address=:443"
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
