{ pkgs, config, ... }:
let
  cfg = config.apps.home-assistant;
in
{
  networking.firewall.interfaces.podman0.allowedTCPPorts = [ 5580 ];
  networking.firewall.allowedUDPPorts = [ 5353 ]; # needed for mDNS

  apps.home-assistant = {
    volumes = {
      home-assistant = { type = "zfs"; };
      matter = { type = "zfs"; };
    };

    containers = {
      home-assistant = {
        image = "ghcr.io/home-assistant/home-assistant:2025.5.1@sha256:249d5c20ae2ab973bc2ca54c05764e67e2230f14ac5ca5a7d45e228efbb62e67";

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

      matter-server = {
        image = "ghcr.io/home-assistant-libs/python-matter-server:8.0.0@sha256:8fd1ea29ab5eca1c5e87cb983c9797b469ad315f6667c73a28b2c4c23a75923c";

        volumes = [
          "${cfg.volumes.matter.path}:/data"
        ];

        extraOptions = [ "--network=host" ];
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
