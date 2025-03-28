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
        image = "ghcr.io/muchobien/pocketbase:0.26.5@sha256:54c6a73429b95a3aa05ab2668533999ba235eadf947a623d84dcaf2fbcb5f85a";

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
