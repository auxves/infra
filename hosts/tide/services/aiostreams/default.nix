{ config, ... }:
let
  cfg = config.apps.aiostreams;
in
{
  sops.secrets."aiostreams/env" = { };

  apps.aiostreams = {
    volumes = {
      data = { type = "zfs"; };
    };

    containers = {
      aiostreams = {
        image = "ghcr.io/viren070/aiostreams:v2.30.6@sha256:dcebb1374b355e320e10ee08642b011072cef7da3523fb99bd59451c5ad5ee99";

        environment = {
          BASE_URL = "https://${cfg.ingresses.app.domain}";
          DATABASE_URI = "sqlite://./data/db.sqlite";
          SEL_SYNC_ACCESS = "all";
          REGEX_FILTER_ACCESS = "all";
        };

        environmentFiles = [ config.sops.secrets."aiostreams/env".path ];

        volumes = [
          "${cfg.volumes.data.path}:/app/data"
        ];
      };
    };

    ingresses = {
      app = {
        type = "public";
        domain = "aiostreams.auxves.dev";
        container = "aiostreams";
        port = 3000;
      };
    };
  };

  monitoring.checks = [{
    name = "aiostreams";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
