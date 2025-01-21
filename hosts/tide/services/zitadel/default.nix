{ config, ... }:
let
  host = "auth.auxves.dev";

  paths = config.storage.paths;
in
{
  storage.paths."services/zitadel" = { };
  sops.secrets."zitadel/env" = { };

  virtualisation.oci-containers.containers.zitadel = {
    image = "ghcr.io/zitadel/zitadel:v2.68.0@sha256:9e0e672e4467fd5b1ad07acf206d61e096886e44ca1347c2deef8b65f8ace2b5";

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
}
