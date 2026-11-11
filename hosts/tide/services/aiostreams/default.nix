{ config, ... }:
let
  cfg = config.apps.aiostreams;
in
{
  sops.secrets."aiostreams/env" = { };

  apps.aiostreams = {
    volumes = {
      data = { type = "zfs"; };
      stremthru = { type = "zfs"; };
    };

    containers = {
      aiostreams = {
        image = "ghcr.io/viren070/aiostreams:v2.37.0@sha256:bcfd8580695a50c8f464578a0e25af065f3bd17eac35ed82a733a18342ca9718";

        environment = {
          BASE_URL = "https://${cfg.ingresses.app.domain}";
          BUILTIN_STREMTHRU_URL = "http://${cfg.containers.stremthru.fullName}:8080";
          DATABASE_URI = "sqlite://./data/db.sqlite";
          SEL_SYNC_ACCESS = "all";
          REGEX_FILTER_ACCESS = "all";
        };

        environmentFiles = [ config.sops.secrets."aiostreams/env".path ];

        volumes = [
          "${cfg.volumes.data.path}:/app/data"
        ];
      };

      stremthru = {
        image = "muniftanjim/stremthru:0.105.4@sha256:947cfcb2601c67f2f21eb11bd1ea1e555889cec9e0b347cefd0c63754b9c641a";

        environment = {
          STREMTHRU_BASE_URL = "http://${cfg.containers.stremthru.fullName}:8080";
          STREMTHRU_DATA_DIR = "/data";
          STREMTHRU_STORE_TUNNEL = "*:false";
          STREMTHRU_STORE_CONTENT_PROXY = "*:false";
        };

        volumes = [
          "${cfg.volumes.stremthru.path}:/data"
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
