{ pkgs, config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2025.1.2@sha256:871f84a00db8d05856a70ee3761b138a8e91eb108d61f2fa176e7eeadb5eda03";

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
