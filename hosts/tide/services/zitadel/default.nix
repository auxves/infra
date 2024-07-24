{ config, ... }:
let
  host = "auth.auxves.dev";

  paths = config.storage.paths;
in
{
  storage.paths."services/zitadel" = { };
  sops.secrets."zitadel/env" = { };

  virtualisation.oci-containers.containers.zitadel = {
    image = "ghcr.io/zitadel/zitadel:v2.56.1@sha256:7ee6f49cb029a70a1d16160e6b7ee0ca027490d3892d4fa2871bd172683e64bd";

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
      ZITADEL_EXTERNALDOMAIN = host;
      ZITADEL_EXTERNALPORT = "443";
    };

    cmd = [ "start-from-init" "--masterkeyFromEnv" "--tlsMode=external" ];

    dependsOn = [ "zitadel-postgres" ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.zitadel.rule" = "Host(`${host}`)";
      "traefik.http.routers.zitadel.entrypoints" = "public";
      "traefik.http.services.zitadel.loadbalancer.server.port" = "8080";
    };
  };

  storage.paths."services/zitadel/postgres" = { };
  sops.secrets."zitadel/postgres/env" = { };

  virtualisation.oci-containers.containers.zitadel-postgres = {
    image = "postgres:16-alpine@sha256:36ed71227ae36305d26382657c0b96cbaf298427b3f1eaeb10d77a6dea3eec41";

    volumes = [
      "${paths."services/zitadel/postgres".path}:/var/lib/postgresql/data"
    ];

    environmentFiles = [ config.sops.secrets."zitadel/postgres/env".path ];

    environment = {
      POSTGRES_USER = "postgres";
      POSTGRES_DB = "zitadel";
    };

    extraOptions = [
      "--health-cmd=pg_isready"
      "--health-on-failure=stop"
    ];
  };
}
