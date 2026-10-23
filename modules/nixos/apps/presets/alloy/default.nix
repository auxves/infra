{ self, config, lib, ... }:
let
  presetCfg = config.presets.apps.alloy;
  cfg = config.apps.alloy;
in
{
  options.presets.apps.alloy = with lib; {
    enable = mkEnableOption "Enable Grafana alloy";
  };

  config = lib.mkIf (presetCfg.enable) {
    sops.secrets."alloy/env" = {
      sopsFile = "${self}/hosts/secrets.yaml";
    };

    apps.alloy = {
      volumes = {
        alloy = { type = "ephemeral"; };
      };

      containers = {
        alloy = {
          image = "grafana/alloy:v1.21.2@sha256:89a5a320168387336b9ac3c850609c3ba7757eadd4ae5f1d819deb35e9854b18";
          user = "root:root";

          environment = {
            HOSTNAME = config.networking.hostName;
            PROMETHEUS_DOMAIN = self.hosts.tide.cfg.apps.prometheus.ingresses.app.domain;
            LOKI_DOMAIN = self.hosts.tide.cfg.apps.loki.ingresses.app.domain;
          };

          environmentFiles = [ config.sops.secrets."alloy/env".path ];

          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "/var/log/journal:/var/log/journal:ro"
            "${cfg.volumes.alloy.path}:/data"
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
  };
}
