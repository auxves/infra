{ ... }: {
  apps.promtail = {
    containers = {
      promtail = {
        image = "grafana/promtail:3.3.2@sha256:cb4990801ec58975c5e231057c2bcf204c85fac428eec65ad66e0016c64b9608";
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
