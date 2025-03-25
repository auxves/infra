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
        image = "ghcr.io/muchobien/pocketbase:0.26.3@sha256:0e97e1178a7e1ff0f5a03ccb43b986bb40852611172e23a04f29ec8976cd6766";

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
