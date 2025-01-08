{ pkgs, config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2025.1.1@sha256:dda88779889b09d5465b8bf0c69ba2a62f81b01ee74d943ebe31e3474ea7cbea";

    volumes = [
      "${paths."services/home-assistant".path}:/config"
      "${pkgs.writeText ".dockerenv" ""}:/.dockerenv"
    ];

    extraOptions = [
      "--device=/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20240123082922-if00:/dev/ttyUSB0"
      "--cap-add=CAP_NET_RAW"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.home-assistant.rule" = "Host(`home.x.auxves.dev`)";
      "traefik.http.services.home-assistant.loadbalancer.server.port" = "8123";
    };
  };

  storage.paths."services/home-assistant/matter" = { };

  networking.firewall.interfaces.podman0.allowedTCPPorts = [ 5580 ];
  networking.firewall.allowedUDPPorts = [ 5353 ]; # needed for mDNS

  virtualisation.oci-containers.containers.matter-server = {
    image = "ghcr.io/home-assistant-libs/python-matter-server:stable@sha256:2057a36093e8a0e5a9d6c391a2be64401944783a6263e26c992b7790033304b5";

    volumes = [
      "${paths."services/home-assistant/matter".path}:/data"
    ];

    extraOptions = [ "--network=host" ];
  };
}
