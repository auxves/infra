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
        image = "ghcr.io/home-assistant/home-assistant:2025.3.1@sha256:304e6999282c5512939db671e5fcbaa923a1f7c9a6e3990cb5baff7abcb9ac4b";

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
