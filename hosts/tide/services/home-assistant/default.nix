{ pkgs, config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.12.5@sha256:132ef461504be5c5ebd6e34e5d3fb3d7958bb6758a5136107eea9f84c299254a";

    volumes = [
      "${paths."services/home-assistant".path}:/config"
      "${pkgs.writeText ".dockerenv" ""}:/.dockerenv"
    ];

    extraOptions = [
      "--device=/dev/ttyACM0"
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
