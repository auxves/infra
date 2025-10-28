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
        image = "grafana/alloy:v1.11.3@sha256:8c7256f412feb9f5f48f9f6f9394dc97ca887f63dea9304f347970ecc1787669";
        user = "root:root";

        environment = {
          HOSTNAME = osConfig.networking.hostName;
          PROMETHEUS_DOMAIN = self.hosts.tide.cfg.apps.prometheus.ingresses.app.domain;
          LOKI_DOMAIN = self.hosts.tide.cfg.apps.loki.ingresses.app.domain;
        };

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${config.volumes.alloy.path}:/data"
          "${./config}:/etc/alloy"
        ];

        cmd = [
          "run"
          "--storage.path=/data"
          "--server.http.listen-addr=0.0.0.0:12345"
          "--disable-reporting"
          "/etc/alloy"
        ];
      };
    };

    ingresses = {
      app = {
        container = "alloy";
        port = 12345;
      };
    };
  };
}
