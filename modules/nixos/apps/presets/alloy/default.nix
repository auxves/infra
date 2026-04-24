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
        image = "grafana/alloy:v1.16.0@sha256:6e00cf7c5a692ff5f24844529416ed017d76fce922f8199004e73d5eca46b6b8";
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
