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
        image = "grafana/alloy:v1.7.1@sha256:da938bc7dc6a96be31d3c93badc445aed115ca39357734de7a338f78fa342cf7";
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
