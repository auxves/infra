{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/immich" = { };
  sops.secrets."immich/env" = { };

  virtualisation.oci-containers.containers.immich = {
    image = "ghcr.io/immich-app/immich-server:v1.112.1@sha256:c4e817f0eadbd9a6c2699cc884d5e7070428daec813c17db77d31fcca5b78ca6";

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
      "traefik.http.services.immich.loadbalancer.server.port" = "3001";
    };
  };

  storage.paths."var/cache/immich-ml" = {
    backend = "none";
  };

  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:v1.112.1@sha256:9600eff5a66ae426293f00b171711bc1647c85cf966d759ee08ab2d05e0580b5";

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
      "--health-cmd=pg_isready"
      "--health-on-failure=stop"
    ];
  };
}
