{ ... }: {
  disko.devices.zpool.storage.datasets."services/grafana".type = "zfs_fs";

  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:11.1.0@sha256:079600c9517b678c10cda6006b4487d3174512fd4c6cface37df7822756ed7a5";
    user = "root:root";

    volumes = [
      "/storage/services/grafana:/var/lib/grafana"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.grafana.rule" = "Host(`grafana.x.auxves.dev`)";
      "traefik.http.services.grafana.loadbalancer.server.port" = "3000";
    };
  };
}
