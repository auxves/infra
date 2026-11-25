{ ... }: {
  flake.modules.nixos.tide = { lib, pkgs, ... }:
    let
      containerAddress = "10.100.0.2";
      hostAddress = "10.100.0.1";

      dockerRoot = "/storage/services/coolify-dev-docker";
    in
    {
      # Docker inside the container cannot load kernel modules, so the host
      # preloads the modules dockerd needs.
      boot.kernelModules = [ "bridge" "veth" "br_netfilter" "xt_nat" "overlay" ];

      networking.nat = {
        enable = true;
        externalInterface = "lan";
        internalInterfaces = [ "ve-coolify-dev" ];
      };

      networking.firewall.trustedInterfaces = [ "ve-coolify-dev" ];

      fileSystems."${dockerRoot}" = {
        device = "/dev/zvol/storage/services/coolify-dev-docker";
        fsType = "ext4";
      };

      system.activationScripts.ensure-coolify-dev-storage.text = ''
        if ! ${pkgs.zfs}/bin/zfs list -H -o name storage/services/coolify-dev >/dev/null 2>&1; then
          ${pkgs.zfs}/bin/zfs create -p -o mountpoint=/var/lib/nixos-containers/coolify-dev storage/services/coolify-dev
        fi
        if ! ${pkgs.zfs}/bin/zfs list -H -o name -t volume storage/services/coolify-dev-docker >/dev/null 2>&1; then
          ${pkgs.zfs}/bin/zfs create -V 30G storage/services/coolify-dev-docker
        fi
        if ! ${pkgs.util-linux}/bin/blkid -o value -s TYPE /dev/zvol/storage/services/coolify-dev-docker >/dev/null 2>&1; then
          ${pkgs.e2fsprogs}/bin/mkfs.ext4 -q /dev/zvol/storage/services/coolify-dev-docker
        fi
      '';

      containers.coolify-dev = {
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

          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "prohibit-password";
          };

          users.users.root.openssh.authorizedKeys.keys = [ ];

          environment.systemPackages = [ pkgs.curl pkgs.openssl pkgs.iproute2 ];
        };
      };
    };
}
