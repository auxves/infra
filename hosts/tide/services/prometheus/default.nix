{ ... }: {
  disko.devices.zpool.storage.datasets."services/prometheus".type = "zfs_fs";

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:v2.45.6@sha256:15ccbb1cec5fad2cd9f20f574ba5a4dd4160e8472213c76faac17f6481cb6a75";
    user = "root:root";

    volumes = [
      "/storage/services/prometheus:/prometheus"
      "${./prometheus.yaml}:/etc/prometheus/prometheus.yml:ro"
    ];
  };

  virtualisation.oci-containers.containers.node-exporter = {
    image = "quay.io/prometheus/node-exporter:v1.8.1@sha256:fa7fa12a57eff607176d5c363d8bb08dfbf636b36ac3cb5613a202f3c61a6631";

    extraOptions = [
      "--pid=host"
    ];

    volumes = [ "/:/host:ro,rslave" ];

    cmd = [ "--path.rootfs=/host" ];
  };

  virtualisation.oci-containers.containers.cadvisor = {
    image = "gcr.io/cadvisor/cadvisor:v0.49.1@sha256:3cde6faf0791ebf7b41d6f8ae7145466fed712ea6f252c935294d2608b1af388";

    ports = [ "8080:8080" ];

    extraOptions = [
      "--privileged"
    ];

    volumes = [
      "/:/rootfs:ro"
      "/var/run:/var/run:ro"
      "/sys:/sys:ro"
      "/var/lib/containers:/var/lib/containers:ro"
      "/dev/disk/:/dev/disk:ro"
    ];
  };
}
