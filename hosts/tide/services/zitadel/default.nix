{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/zitadel" = { };
  sops.secrets."zitadel/env" = { };

  storage.paths."services/zitadel/postgres" = { };
  sops.secrets."zitadel/postgres/env" = { };

  apps.zitadel = {
    containers = {
      app = {
        image = "ghcr.io/zitadel/zitadel:v2.68.1@sha256:74344030df8414add04f429b1748af89e1e1b2ff4de78c7d7dd5a2f76ba00074";

        environmentFiles = [ config.sops.secrets."zitadel/env".path ];

        environment = {
          ZITADEL_DATABASE_POSTGRES_HOST = "zitadel-postgres";
          ZITADEL_DATABASE_POSTGRES_PORT = "5432";
          ZITADEL_DATABASE_POSTGRES_DATABASE = "zitadel";
          ZITADEL_DATABASE_POSTGRES_USER_USERNAME = "zitadel";
          ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE = "disable";
          ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME = "postgres";
          ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE = "disable";
          ZITADEL_EXTERNALSECURE = "true";
          ZITADEL_EXTERNALDOMAIN = config.apps.zitadel.ingress.host;
          ZITADEL_EXTERNALPORT = "443";
        };

        cmd = [ "start-from-init" "--masterkeyFromEnv" "--tlsMode=external" ];

        dependsOn = [ "zitadel-postgres" ];
      };

      postgres = {
        image = "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065";

        volumes = [
          "${paths."services/zitadel/postgres".path}:/var/lib/postgresql/data"
        ];

        environmentFiles = [ config.sops.secrets."zitadel/postgres/env".path ];

        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "zitadel";
        };

        extraOptions = [
          "--health-cmd=pg_isready -d \${POSTGRES_USER} -U \${POSTGRES_DB}"
          "--health-on-failure=stop"
        ];
      };
    };

    ingress = {
      container = "app";
      host = "auth.auxves.dev";
      type = "public";
      port = 8080;
    };
  };

  monitoring.checks = [{
    name = "zitadel";
    group = "services";
    url = "https://${config.apps.zitadel.ingress.host}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
