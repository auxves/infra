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
        image = "ghcr.io/zitadel/zitadel:v2.71.3@sha256:8314337e206f9f7a8bba7a301a87c55d269bcda2ac39c9bae62ed8fce0d100f1";

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
          ZITADEL_EXTERNALDOMAIN = cfg.ingress.domain;
          ZITADEL_EXTERNALPORT = "443";
        };

        cmd = [ "start-from-init" "--masterkeyFromEnv" "--tlsMode=external" ];

        dependsOn = [ "zitadel-postgres" ];
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

    ingress = {
      container = "zitadel";
      domain = "auth.auxves.dev";
      type = "public";
      port = 8080;
    };
  };

  monitoring.checks = [{
    name = "zitadel";
    group = "services";
    url = "https://${cfg.ingress.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
