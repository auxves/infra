{ ... }: {
  disko.devices.zpool.storage.datasets."services/home-assistant".type = "zfs_fs";

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.6.4@sha256:17d159928122e6f374bd39b0e75904522bc7d7c2a64e88b248948734e4c4d444";
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
