{ ... }: {
  services.apcupsd = {
    enable = true;

    configText = ''
      UPSNAME be600m1
      UPSCABLE usb
      UPSTYPE usb
      DEVICE

      BATTERYLEVEL 40
      MINUTES 5
      TIMEOUT 0 # disabled

      NOLOGON disable
    '';
  };

  systemd.services.apcupsd.serviceConfig.LogExtraFields = [
    "ALLOY_ENABLE=true"
  ];

  # Allow the exporter to access the apcupsd service
  networking.firewall.interfaces.podman0.allowedTCPPorts = [ 3551 ];

  apps.apcupsd = {
    containers = {
      exporter = {
        image = "sfudeus/apcupsd_exporter:latest@sha256:944f53d0fd288931686fe01ad850b2274f7d661c646934da4daaff3644e38010";
        cmd = [ "-apcupsd.addr=host.containers.internal:3551" ];
        metrics.port = 9162;

        service.requires = [ "apcupsd.service" ];
      };
    };
  };
}
