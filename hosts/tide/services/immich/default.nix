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
        image = "ghcr.io/immich-app/immich-server:v1.130.3@sha256:eb5e28de53461e9c328d86fdccfddde579cf9b10ebb3105a2a194115b79ad8a9";

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
        image = "ghcr.io/immich-app/immich-machine-learning:v1.130.3@sha256:454a6a361d473e699bbccebee488b3886048eed91e2058657b9ba398ce917a77";
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
