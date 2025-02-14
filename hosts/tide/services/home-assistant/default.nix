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
        image = "ghcr.io/home-assistant/home-assistant:2025.2.4@sha256:dae013e0bd935bf8dc500adef771604a3fd03dc5f2ca13b9566f51a094e3f8bf";

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
        image = "ghcr.io/home-assistant-libs/python-matter-server:7.0.1@sha256:828c1cd3f957bb0287a099a439505457a25f5d65ed34281acf19cfbf537fe346";

        volumes = [
          "${cfg.volumes.matter.path}:/data"
        ];

        extraOptions = [ "--network=host" ];
      };
    };

    ingress = {
      container = "home-assistant";
      domain = "home.auxves.dev";
      port = 8123;
    };
  };

  monitoring.checks = [{
    name = "home-assistant";
    group = "services";
    url = "https://${cfg.ingress.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
