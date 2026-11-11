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
        image = "ghcr.io/auxves/aiostreams-trakt-addon:pr-1@sha256:cd4e38640c1f867f0580fa5fd3aad56f5c99c7aa5a976e36f6b9665f2cb1ed74";

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
