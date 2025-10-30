{ config, ... }:
let
  cfg = config.apps.affine;
in
{
  apps.affine = { lib', ... }: {
    volumes = {
      data = { type = "zfs"; };
      postgres = { type = "zfs"; };
    };

    containers = {
      affine = {
        image = "ghcr.io/toeverything/affine:0.25.2@sha256:551be827a25f6907077569b616645fcc7747ece42c608b2259913ffcc9a8dfd0";

        volumes = [
          "${cfg.volumes.data.path}:/root/.affine"
        ];

        environment = {
          AFFINE_SERVER_EXTERNAL_URL = "https://${cfg.ingresses.app.domain}";
          REDIS_SERVER_HOST = cfg.containers.redis.fullName;
          DATABASE_URL = "postgresql://postgres@${cfg.containers.postgres.fullName}:5432/affine";
          AFFINE_INDEXER_ENABLED = "false";
        };

        cmd = [
          "sh"
          "-c"
          "node ./scripts/self-host-predeploy.js && node ./dist/main.js"
        ];

        dependsOn = [
          cfg.containers.redis.fullName
          cfg.containers.postgres.fullName
        ];
      };

      redis = {
        image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";
      };

      postgres = lib'.mkPostgres {
        image = "pgvector/pgvector:pg16@sha256:5f411947f0bc83fbdfdde1459098ceead166c6908eadd08da8a6b7e2177e225d";
        data = cfg.volumes.postgres.path;
        db = "affine";
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
