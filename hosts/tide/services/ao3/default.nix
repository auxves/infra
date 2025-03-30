{ config, ... }:
let
  cfg = config.apps.ao3;
in
{
  apps.ao3 = {
    volumes = {
      pocketbase = { type = "zfs"; path = "/storage/services/ao3/pocketbase"; };
    };

    containers = {
      pocketbase = {
        image = "ghcr.io/muchobien/pocketbase:0.26.6@sha256:adb625bbcf260a8d2a596a3ae4b32ac87f2ecb2a03096ba084db1c3fde7eaa04";

        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.ao3-pocketbase.rule" = "Host(`pocketbase.ao3.${config.networking.hostName}.x.auxves.dev`)";
          "traefik.http.services.ao3-pocketbase.loadbalancer.server.port" = "8090";
        };

        volumes = [
          "${cfg.volumes.pocketbase.path}:/pb_data"
        ];
      };
    };
  };
}
