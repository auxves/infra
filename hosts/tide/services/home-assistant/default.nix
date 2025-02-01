{ pkgs, config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };
  storage.paths."services/home-assistant/matter" = { };

  networking.firewall.interfaces.podman0.allowedTCPPorts = [ 5580 ];
  networking.firewall.allowedUDPPorts = [ 5353 ]; # needed for mDNS

  apps.home-assistant = {
    containers = {
      app = {
        image = "ghcr.io/home-assistant/home-assistant:2025.1.4@sha256:a8aab945aec2f43eb1b1fde4d19e25ef952fab9c10f49e40d3b3ce7d24cedc19";

        volumes = [
          "${paths."services/home-assistant".path}:/config"
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
        image = "ghcr.io/home-assistant-libs/python-matter-server:7.0.1@sha256:828c1cd3f957bb0287a099a439505457a25f5d65ed34281acf19cfbf537fe346";

        volumes = [
          "${paths."services/home-assistant/matter".path}:/data"
        ];

        extraOptions = [ "--network=host" ];
      };
    };

    ingress = {
      container = "app";
      host = "home.x.auxves.dev";
      port = 8123;
    };
  };

  monitoring.checks = [{
    name = "home-assistant";
    group = "services";
    url = "https://${config.apps.home-assistant.ingress.host}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
