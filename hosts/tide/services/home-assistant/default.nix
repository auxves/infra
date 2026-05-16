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
        image = "ghcr.io/home-assistant/home-assistant:2026.5.2@sha256:f0baa7922ecec7790c40c41baf08ab218b6ab8db5f96dc03b03a0ae33d987c3d";

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
