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
        image = "ghcr.io/viren070/aiostreams:v2.35.7@sha256:aa3bc7fce5876e208638b98546d3cdcf1ccd9dc1a8a4d5294971ef4507822dd5";

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
