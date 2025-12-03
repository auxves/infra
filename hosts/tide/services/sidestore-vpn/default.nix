{ config, ... }:
let
  cfg = config.apps.sidestore-vpn;
in
{
  sops.secrets."sidestore-vpn/tailscale-env" = { };

  apps.sidestore-vpn = {
    volumes = {
      tailscale = { type = "ephemeral"; };
    };

    containers = {
      sidestore-vpn = {
        image = "forge.auxves.dev/arno/sidestore-vpn:latest@sha256:f4dd8747e5a064b4843c411dbccf01ec529a95181db3739d7be6711f7453fcc4";
        dependsOn = [ cfg.containers.tailscale.fullName ];
        extraOptions = [
          "--device=/dev/net/tun"
          "--cap-add=NET_ADMIN"
          "--net=container:${cfg.containers.tailscale.fullName}"
        ];
      };

      tailscale = {
        image = "ghcr.io/tailscale/tailscale:v1.90.9@sha256:9975353aae933e8fbd1a81226d092a9225b9a0f98b173d365a9d525eca1cc298";

        volumes = [ "${cfg.volumes.tailscale.path}:/var/lib/tailscale" ];

        environmentFiles = [ config.sops.secrets."sidestore-vpn/tailscale-env".path ];

        environment = {
          TS_HOSTNAME = "sidestore-vpn";
          TS_AUTH_ONCE = "true";
          TS_EXTRA_ARGS = "--advertise-tags=tag:infra";
          TS_ROUTES = "10.7.0.1/32";
          TS_USERSPACE = "false";
          TS_STATE_DIR = "/var/lib/tailscale";
        };

        extraOptions = [
          "--device=/dev/net/tun"
          "--cap-add=NET_ADMIN"
        ];
      };
    };
  };
}
