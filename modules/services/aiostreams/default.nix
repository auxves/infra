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

          trakt-addon = {
            user = "root:root";
            image = "ghcr.io/auxves/aiostreams-trakt-addon:v0.3.0@sha256:a2a1e994be3f2290be4fa1df05104b503a13f9e9c0980fa183210f1265fb9968";

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
    }
  ;
}
