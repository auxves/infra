{ ... }: {
  apps.promtail = {
    containers = {
      promtail = {
        image = "grafana/promtail:3.4.0@sha256:5a9c3491f52675913905b466c966eaee26bb40c3a4d5ff0aee848f4834ac1997";
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
