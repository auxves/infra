{ self, config, osConfig, lib, ... }:
let
  cfg = config.presets.alloy;
in
{
  options.presets.alloy = with lib; {
    enable = mkEnableOption "Enable Grafana alloy";
  };

  config = lib.mkIf (cfg.enable) {
    volumes = {
      alloy = { type = "ephemeral"; };
    };

    containers = {
      alloy = {
        image = "grafana/alloy:v1.7.0@sha256:afcc9d32975dd567b2e7c87f0c2f0e4ebf9385ecc36e1c0d44ba42de6dcf291c";
        user = "root:root";

        environment = {
          HOSTNAME = osConfig.networking.hostName;
          PROMETHEUS_DOMAIN = self.hosts.tide.cfg.apps.prometheus.ingress.domain;
          LOKI_DOMAIN = self.hosts.tide.cfg.apps.loki.ingress.domain;
        };

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${config.volumes.alloy.path}:/data"
          "${./config}:/etc/alloy"
        ];

        cmd = [
          "run"
          "--storage.path=/data"
          "--server.http.listen-addr=0.0.0.0:12345"
          "/etc/alloy"
        ];
      };
    };

    ingress = {
      container = "alloy";
      port = 12345;
    };
  };
}
