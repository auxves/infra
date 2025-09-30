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
        image = "adguard/adguardhome:v0.107.67@sha256:927dc14b3e3cbd359e84658914590270a77d54446a6565e9498bef3444c286a4";

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
