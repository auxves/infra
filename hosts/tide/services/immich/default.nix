{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/immich" = { };
  sops.secrets."immich/env" = { };

  virtualisation.oci-containers.containers.immich = {
    image = "ghcr.io/immich-app/immich-server:v1.118.2@sha256:f158810c90f80162f9b08729bbaec963731f12662960be38ff93093b78a0bbdf";

    volumes = [
      "${paths."services/immich".path}:/usr/src/app/upload"
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

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.immich.rule" = "Host(`immich.x.auxves.dev`)";
      "traefik.http.services.immich.loadbalancer.server.port" = "2283";
    };
  };

  storage.paths."var/cache/immich-ml" = {
    backend = "local";
  };

  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:v1.118.2@sha256:4d89a309fd08a93649f1ae4a7572ae98f09d66b4c1dfb7916b71d31dec7eda38";

    volumes = [
      "${paths."var/cache/immich-ml".path}:/cache"
    ];
  };

  virtualisation.oci-containers.containers.immich-redis = {
    image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";

    extraOptions = [
      "--health-cmd=redis-cli ping"
      "--health-on-failure=stop"
    ];
  };

  storage.paths."services/immich/postgres" = { };
  sops.secrets."immich/postgres/env" = { };

  virtualisation.oci-containers.containers.immich-postgres = {
    image = "tensorchord/pgvecto-rs:pg16-v0.2.1@sha256:ff2288833f32aa863ba46f4c6f5b5c143f526a2d27f4cca913c232f917a66602";

    volumes = [
      "${paths."services/immich/postgres".path}:/var/lib/postgresql/data"
    ];

    environmentFiles = [ config.sops.secrets."immich/postgres/env".path ];

    environment = {
      POSTGRES_USER = "immich";
      POSTGRES_DB = "immich";
      POSTGRES_INITDB_ARGS = "--data-checksums";
    };

    extraOptions = [
      "--health-cmd=pg_isready -d \${POSTGRES_USER} -U \${POSTGRES_DB}"
      "--health-on-failure=stop"
    ];
  };
}
