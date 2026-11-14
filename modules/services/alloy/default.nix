{ inputs, ... }: {
  flake.modules.nixos.alloy = { config, lib, ... }:
    let
      cfg = config.apps.alloy;
    in
    {
      config = {
        sops.secrets."alloy/env" = {
          sopsFile = "${inputs.self}/modules/hosts/secrets.yaml";
        };

        apps.alloy = {
          volumes = {
            alloy = { type = "ephemeral"; };
          };

          containers = {
            alloy = {
              image = "grafana/alloy:v1.22.0@sha256:9acc2529bc1edb7f5b2bd801dd8334ebc80c158e3a9e5526ecd7c9a273d43189";
              user = "root:root";

              environment = {
                HOSTNAME = config.networking.hostName;
                PROMETHEUS_DOMAIN = inputs.self.hosts.tide.cfg.apps.prometheus.ingresses.app.domain;
                LOKI_DOMAIN = inputs.self.hosts.tide.cfg.apps.loki.ingresses.app.domain;
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
    };

  flake.modules.nixos.tide = {
    imports = [ inputs.self.modules.nixos.alloy ];
  };

  flake.modules.nixos.harpy = {
    imports = [ inputs.self.modules.nixos.alloy ];
  };
}
