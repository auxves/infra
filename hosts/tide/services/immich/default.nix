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
        image = "ghcr.io/immich-app/immich-server:v1.131.3@sha256:7e5b6729b12b5e5cc5d98bcc6f7c27f723fabae4ee77696855808ebd5200bbf8";

        volumes = [
          "${cfg.volumes.immich.path}:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];

        environmentFiles = [ config.sops.secrets."immich/env".path ];

        environment = {
          DB_HOSTNAME = "immich-postgres";
          DB_USERNAME = "immich";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich-redis";
        };

        extraOptions = [ "--device=/dev/dri" ];

        dependsOn = [ "immich-redis" "immich-postgres" ];
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

    ingress = {
      container = "immich";
      domain = "immich.auxves.dev";
      port = 2283;
    };
  };

  monitoring.checks = [{
    name = "immich";
    group = "services";
    url = "https://${cfg.ingress.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
