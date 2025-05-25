{ config, ... }:
let
  cfg = config.apps.zitadel;
in
{
  sops.secrets."zitadel/env" = { };

  apps.zitadel = { lib', ... }: {
    volumes = {
      zitadel = { type = "zfs"; };
      postgres = { type = "zfs"; };
    };

    containers = {
      zitadel = {
        image = "ghcr.io/zitadel/zitadel:v3.2.0@sha256:6b1bd27a2374cb797c0d47cadbffb2037d70b375fc4b3ce368194ce1ba95c966";

        environmentFiles = [ config.sops.secrets."zitadel/env".path ];

        environment = {
          ZITADEL_DATABASE_POSTGRES_HOST = cfg.containers.postgres.fullName;
          ZITADEL_DATABASE_POSTGRES_PORT = "5432";
          ZITADEL_DATABASE_POSTGRES_DATABASE = "zitadel";
          ZITADEL_DATABASE_POSTGRES_USER_USERNAME = "zitadel";
          ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE = "disable";
          ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME = "postgres";
          ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE = "disable";
          ZITADEL_EXTERNALSECURE = "true";
          ZITADEL_EXTERNALDOMAIN = cfg.ingresses.app.domain;
          ZITADEL_EXTERNALPORT = "443";
        };

        cmd = [ "start-from-init" "--masterkeyFromEnv" "--tlsMode=external" ];

        dependsOn = [ cfg.containers.postgres.fullName ];
      };

      postgres = lib'.mkPostgres {
        data = cfg.volumes.postgres.path;
        db = "zitadel";
      };
    };

    ingresses = {
      app = {
        type = "public";
        domain = "auth.auxves.dev";
        container = "zitadel";
        port = 8080;
      };
    };
  };

  monitoring.checks = [{
    name = "zitadel";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
