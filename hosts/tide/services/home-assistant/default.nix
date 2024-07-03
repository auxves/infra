{ ... }: {
  disko.devices.zpool.storage.datasets."services/home-assistant".type = "zfs_fs";

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.7.0@sha256:4c2400f34d42c5fed9e2443a5a41db01316323b0564701f3336411bcd2ff9c88";

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
