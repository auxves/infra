{ config, ... }:
let
  cfg = config.apps.aiostreams-trakt-addon;
in
{
  sops.secrets."aiostreams-trakt-addon/env" = { };

  apps.aiostreams-trakt-addon = {
    volumes = {
      data = { type = "zfs"; };
    };

    containers = {
      aiostreams-trakt-addon = {
        image = "ghcr.io/auxves/aiostreams-trakt-addon:pr-1@sha256:59420937934b63e5b25ccb0d966cceddb472ac59bb121eb4f4a783c6620305c6";

        volumes = [
          "${cfg.volumes.data.path}:/data"
        ];

        environment = {
          BASE_URL = "https://${cfg.ingresses.app.domain}";
          DATA_DIR = "/data";
          PORT = "8787";
        };

        environmentFiles = [ config.sops.secrets."aiostreams-trakt-addon/env".path ];
      };
    };

    ingresses = {
      app = {
        container = "aiostreams-trakt-addon";
        port = 8787;
      };
    };
  };

  monitoring.checks = [{
    name = "aiostreams-trakt-addon";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}/healthz";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
