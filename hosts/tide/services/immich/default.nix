{ config, ... }:
let
  cfg = config.apps.immich;
in
{
  sops.secrets."immich/env" = { };
  sops.secrets."immich/postgres/env" = { };

  apps.immich = {
    volumes = {
      immich = { type = "zfs"; };
      postgres = { type = "zfs"; };
      ml = { type = "ephemeral"; };
    };

    containers = {
      immich = {
        image = "ghcr.io/immich-app/immich-server:v1.133.0@sha256:4d667c5fd6ffac0395c429fc8a335c607272587643f29fb2ddd9bfe16f1f874e";

        volumes = [
          "${cfg.volumes.immich.path}:/usr/src/app/upload"
        ];

        environmentFiles = [ config.sops.secrets."immich/env".path ];

        environment = {
          REDIS_HOSTNAME = cfg.containers.redis.fullName;
          DB_HOSTNAME = cfg.containers.postgres.fullName;
          DB_USERNAME = "immich";
          DB_DATABASE_NAME = "immich";
        };

        extraOptions = [ "--device=/dev/dri" ];

        dependsOn = [
          cfg.containers.redis.fullName
          cfg.containers.postgres.fullName
        ];
      };

      machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.131.2@sha256:29836cf73146057ac388546021fff3e00c923e22a28587cceb5108a5e537987d";
        volumes = [ "${cfg.volumes.ml.path}:/cache" ];
      };

      redis = {
        image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";
      };

      postgres = {
        image = "tensorchord/pgvecto-rs:pg16-v0.2.1@sha256:ff2288833f32aa863ba46f4c6f5b5c143f526a2d27f4cca913c232f917a66602";

        volumes = [
          "${cfg.volumes.postgres.path}:/var/lib/postgresql/data"
        ];

        environmentFiles = [ config.sops.secrets."immich/postgres/env".path ];

        environment = {
          POSTGRES_USER = "immich";
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
        };
      };
    };

    ingresses = {
      app = {
        domain = "immich.auxves.dev";
        container = "immich";
        port = 2283;
      };
    };
  };

  monitoring.checks = [{
    name = "immich";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
