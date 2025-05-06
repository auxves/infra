{ config, ... }:
let
  cfg = config.apps.zitadel;
in
{
  sops.secrets."zitadel/env" = { };
  sops.secrets."zitadel/postgres/env" = { };

  apps.zitadel = {
    volumes = {
      zitadel = { type = "zfs"; };
      postgres = { type = "zfs"; };
    };

    containers = {
      zitadel = {
        image = "ghcr.io/zitadel/zitadel:v3.0.0@sha256:fe5371eac4f49695ad9488367809bba7b3bba389c218836acfca39ec49701872";

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

      postgres = {
        image = "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065";

        volumes = [
          "${cfg.volumes.postgres.path}:/var/lib/postgresql/data"
        ];

        environmentFiles = [ config.sops.secrets."zitadel/postgres/env".path ];

        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "zitadel";
        };
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
