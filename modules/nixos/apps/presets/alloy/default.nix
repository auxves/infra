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
        image = "grafana/alloy:v1.10.0@sha256:1bc130e909116a4bf950eb5187a346007d3b796f96832b529acb14a64e41230f";
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
