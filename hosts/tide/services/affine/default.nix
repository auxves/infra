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
        image = "ghcr.io/toeverything/affine-graphql:stable@sha256:9ef30354f6471b512905a793e7c28359ca78d80ff3301c9b5f4ab9a6c8d98874";

        volumes = [
          "${cfg.volumes.data.path}:/root/.affine"
        ];

        environment = {
          AFFINE_SERVER_EXTERNAL_URL = "https://${cfg.ingresses.app.domain}";
          REDIS_SERVER_HOST = cfg.containers.redis.fullName;
          DATABASE_URL = "postgresql://postgres@${cfg.containers.postgres.fullName}:5432/affine";
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

      postgres = lib'.mkPostgres {
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
