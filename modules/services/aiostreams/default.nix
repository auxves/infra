{ ... }: {
  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.aiostreams;
    in
    {
      sops.secrets."aiostreams/env" = { };
      sops.secrets."aiostreams/trakt-addon/env" = { };

      apps.aiostreams = {
        volumes = {
          data = { type = "zfs"; };
          stremthru = { type = "zfs"; };
          trakt-addon = { type = "zfs"; };
        };

        containers = {
          aiostreams = {
            image = "ghcr.io/viren070/aiostreams:v2.38.1@sha256:1b90bc2fda70f365dff2ce98fc311a24708cca9841efe09aefe309cd4da1fb2c";

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

          trakt-addon = {
            user = "root:root";
            image = "ghcr.io/auxves/aiostreams-trakt-addon:v0.4.0@sha256:d467e974260c63b6ea7d9f6179be0c33ed6a0f0a608a1d872a2ce85b6d4b92fb";

            volumes = [
              "${cfg.volumes.trakt-addon.path}:/data"
            ];

            environment = {
              DATA_DIR = "/data";
              PORT = "8787";
            };

            environmentFiles = [ config.sops.secrets."aiostreams/trakt-addon/env".path ];
          };
        };

        ingresses = {
          app = {
            type = "public";
            domain = "aiostreams.auxves.dev";
            container = "aiostreams";
            port = 3000;
          };

          trakt-addon = {
            container = "trakt-addon";
            port = 8787;
          };
        };
      };

      monitoring.checks = [
        {
          name = "aiostreams";
          group = "services";
          url = "https://${cfg.ingresses.app.domain}";
          interval = "1m";
          alerts = [{ type = "discord"; }];
          conditions = [
            "[STATUS] == 200"
          ];
        }
        {
          name = "aiostreams-trakt-addon";
          group = "services";
          url = "https://${cfg.ingresses.trakt-addon.domain}/healthz";
          interval = "1m";
          alerts = [{ type = "discord"; }];
          conditions = [
            "[STATUS] == 200"
            "[BODY].needsReconnect == 0"
            "[BODY].shapeDrift == false"
          ];
        }
      ];
    };
}
