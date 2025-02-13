{ ... }: {
  apps.promtail = {
    containers = {
      promtail = {
        image = "grafana/promtail:3.4.1@sha256:8b2aa61745bc4a9343cc47bd391fb935a80e7da0793c7566d5985c75858ba3f8";
        user = "root:root";

        volumes = [
          # "/var/log:/var/log:ro" # journal scraping
          # "/etc/machine-id:/etc/machine-id:ro"
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro" # container scraping
          "${./promtail.yaml}:/etc/promtail/config.yml:ro"
        ];
      };
    };
  };
}
