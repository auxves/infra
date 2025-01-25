{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "immich.x.auxves.dev";
in
{
  storage.paths."services/immich" = { };
  sops.secrets."immich/env" = { };

  virtualisation.oci-containers.containers.immich = {
    image = "ghcr.io/immich-app/immich-server:v1.125.2@sha256:b7464b8799ab31c192d9b51a59d73426fc2deb39db6166a2f5073ae304c1131d";

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
      "traefik.http.routers.immich.rule" = "Host(`${hostname}`)";
      "traefik.http.services.immich.loadbalancer.server.port" = "2283";
    };
  };

  monitoring.checks = [{
    name = "immich";
    group = "services";
    url = "https://${hostname}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];

  storage.paths."var/cache/immich-ml" = {
    backend = "local";
  };

  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:v1.125.2@sha256:3049673142acc7d655127c3751dafaf2e6a4c37d74ed3fdfb45d01fe0140f617";

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
