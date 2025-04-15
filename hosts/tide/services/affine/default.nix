{ config, ... }:
let
  cfg = config.apps.affine;
in
{
  sops.secrets."affine/env" = { };
  sops.secrets."affine/postgres/env" = { };

  apps.affine = {
    volumes = {
      data = { type = "zfs"; };
      postgres = { type = "zfs"; };
    };

    containers = {
      affine = {
        image = "ghcr.io/toeverything/affine-graphql:stable@sha256:396f81415c2394c9718f25f9f39d0fdc07389cb24548a482c103017730e4d742";

        volumes = [
          "${cfg.volumes.data.path}:/root/.affine"
        ];

        environmentFiles = [ config.sops.secrets."affine/env".path ];

        environment = {
          AFFINE_SERVER_EXTERNAL_URL = "https://${cfg.ingresses.app.domain}";
          REDIS_SERVER_HOST = cfg.containers.redis.fullName;

          OAUTH_OIDC_SCOPE = "openid email profile offline_access";
          OAUTH_OIDC_CLAIM_MAP_ID = "preferred_username";
          OAUTH_OIDC_CLAIM_MAP_EMAIL = "email";
        };

        cmd = [
          "sh"
          "-c"
          "node ./scripts/self-host-predeploy.js && node --import ./scripts/register.js ./dist/index.js"
        ];

        dependsOn = [
          cfg.containers.redis.fullName
          cfg.containers.postgres.fullName
        ];
      };

      redis = {
        image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";
      };

      postgres = {
        image = "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065";

        volumes = [
          "${cfg.volumes.postgres.path}:/var/lib/postgresql/data"
        ];

        environmentFiles = [ config.sops.secrets."affine/postgres/env".path ];

        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "affine";
        };
      };
    };

    ingresses = {
      app = {
        domain = "affine.auxves.dev";
        container = "affine";
        port = 3010;
      };
    };
  };

  monitoring.checks = [{
    name = "affine";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
