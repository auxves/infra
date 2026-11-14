{ inputs, ... }: {
  flake.services.home-assistant.domain = "home.auxves.dev";
  flake.services.home-assistant.mcpDomain = "mcp.home.auxves.dev";

  flake.modules.nixos.tide = { pkgs, config, ... }:
    let
      cfg = config.apps.home-assistant;
    in
    {
      apps.home-assistant = {
        volumes = {
          home-assistant = { type = "zfs"; };
        };

        containers = {
          home-assistant = {
            image = "ghcr.io/home-assistant/home-assistant:2026.11.1@sha256:6785d1eca68747a524c156faae1b139ed415c07357386ae6fe17291986e59e82";

            volumes = [
              "${cfg.volumes.home-assistant.path}:/config"
              "${pkgs.writeText ".dockerenv" ""}:/.dockerenv"
            ];

            extraOptions = [
              "--device=/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20240123082922-if00:/dev/ttyUSB0"
              "--cap-add=CAP_NET_RAW"
            ];

            metrics = {
              path = "/api/prometheus";
              port = 8123;
            };
          };
        };

        ingresses = {
          app = {
            domain = inputs.self.services.home-assistant.domain;
            container = "home-assistant";
            port = 8123;
          };

          mcp = {
            type = "public";
            domain = inputs.self.services.home-assistant.mcpDomain;
            container = "home-assistant";
            port = 9584;
          };
        };
      };

      monitoring.checks = [{
        name = "home-assistant";
        group = "services";
        url = "https://${cfg.ingresses.app.domain}";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[STATUS] == 200"
        ];
      }];
    };
}
