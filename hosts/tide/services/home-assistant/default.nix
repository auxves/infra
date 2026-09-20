{ pkgs, config, ... }:
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
        image = "ghcr.io/home-assistant/home-assistant:2026.9.3@sha256:d8922685169707fd91e8b9729902d975f06157d005e422874d201e0261dda196";

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
        domain = "home.auxves.dev";
        container = "home-assistant";
        port = 8123;
      };

      mcp = {
        type = "public";
        domain = "mcp.home.auxves.dev";
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
}
