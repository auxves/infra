{ ... }: {
  disko.devices.zpool.storage.datasets."services/home-assistant".type = "zfs_fs";

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.7.1@sha256:dbbb63d9e9e69cd7f0d33ecc3135bff21044f48f00e29ba96a43e0793155ba67";

    volumes = [
      "/storage/services/home-assistant:/config"
    ];

    extraOptions = [ "--device=/dev/ttyACM0" ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.home-assistant.rule" = "Host(`home.x.auxves.dev`)";
      "traefik.http.services.home-assistant.loadbalancer.server.port" = "8123";
    };
  };
}
