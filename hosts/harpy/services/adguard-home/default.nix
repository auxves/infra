{ config, ... }:
let
  cfg = config.apps.adguard-home;
in
{
  apps.adguard-home = {
    volumes = {
      config = { type = "ephemeral"; };
      state = { type = "ephemeral"; };
    };

    containers = {
      adguard-home = {
        image = "adguard/adguardhome:v0.107.66@sha256:cc8757742e547c722bb0bd9a3b11fce22771a75a5b0e07ce9a789ad62a2bfd37";

        volumes = [
          "${cfg.volumes.config.path}:/opt/adguardhome/conf"
          "${cfg.volumes.state.path}:/opt/adguardhome/work"
        ];

        extraOptions = [ "--net=host" ];
      };
    };

    ingresses = {
      app = {
        domain = "dns.auxves.dev";
        container = "adguard-home";
        port = 3000;
      };
    };
  };

  networking.firewall.interfaces."podman+".allowedTCPPorts = [
    cfg.ingresses.app.port # for traefik
  ];

  monitoring.checks = [{
    name = "adguard-home";
    group = "infra";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
