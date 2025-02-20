{ lib, config, ... }: {
  sops.secrets."traefik/env" = { };

  apps.traefik = {
    presets.traefik.enable = true;

    containers = {
      traefik = {
        ports = lib.optionals (config.meta.addresses.internal.v6 != null) [
          # Internal
          "[${config.meta.addresses.internal.v6}]:443:443/tcp"
          "[${config.meta.addresses.internal.v6}]:443:443/udp"
        ] ++ lib.optionals (config.meta.addresses.internal.v4 != null) [
          # Internal
          "${config.meta.addresses.internal.v4}:443:443/tcp"
          "${config.meta.addresses.internal.v4}:443:443/udp"
        ] ++ lib.optionals (config.meta.addresses.public.v6 != null) [
          # Public
          "[${config.meta.addresses.public.v6}]:443:8443/tcp"
          "[${config.meta.addresses.public.v6}]:443:8443/udp"
        ] ++ lib.optionals (config.meta.addresses.public.v4 != null) [
          # Public
          "192.168.7.209:443:8443/tcp"
          "192.168.7.209:443:8443/udp"
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
