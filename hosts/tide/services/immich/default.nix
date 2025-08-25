{ config, ... }:
let
  cfg = config.apps.immich;
in
{
  apps.immich = { lib', ... }: {
    volumes = {
      immich = { type = "zfs"; };
      postgres = { type = "zfs"; };
      ml = { type = "ephemeral"; };
    };

    containers = {
      immich = {
        image = "ghcr.io/immich-app/immich-server:v1.139.3@sha256:9cea00524e723d8aa28b2a807b449aee1ebcb6f0052b7cd7e43b905a1c9f87df";

        volumes = [
          "${cfg.volumes.immich.path}:/usr/src/app/upload"
        ];

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
        image = "ghcr.io/immich-app/immich-machine-learning:v1.139.3@sha256:11fb28355bfb78eae9549692faac178da1c2df46af3e533f4c9145c5e2f1600c";
        volumes = [ "${cfg.volumes.ml.path}:/cache" ];
      };

      redis = {
        image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";
      };

      postgres = lib'.mkPostgres {
        image = "ghcr.io/immich-app/postgres:16-vectorchord0.3.0@sha256:7ac7fc515326587697ca149a352cbb88ce19a904cd110c6b1d42af67c72603eb";
        data = cfg.volumes.postgres.path;
        db = "immich";
        user = "immich";
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
