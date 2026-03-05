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
        image = "ghcr.io/home-assistant/home-assistant:2026.3.0@sha256:4fb4ad85fad2250ccff6ec0670827bdcdc46b8bab2b9cbfb8ecdc28da7210630";

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
