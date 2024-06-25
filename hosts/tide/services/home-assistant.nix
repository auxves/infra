{ ... }: {
  disko.devices.zpool.storage.datasets."services/home-assistant".type = "zfs_fs";

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.5.3@sha256:cd3e0dc0df5b2013ae589e9f0044e1093c28c31dc653f36db3df10ba8e898dd6";
    autoStart = true;

    volumes = [
      "/storage/services/home-assistant:/config"
    ];

    extraOptions = [
      "--network=lan:ip=2600:1700:78c0:130f:abcd::6eb4"
      "--network=traefik-internal"
      "--device=/dev/ttyACM0"
    ];

    labels = {
      "traefik.http.routers.home-assistant.rule" = "Host(`home.x.auxves.dev`)";
      "traefik.http.services.home-assistant.loadbalancer.server.port" = "8123";
    };
  };
}
