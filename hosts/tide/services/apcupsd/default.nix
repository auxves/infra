{ ... }: {
  apps.apcupsd = {
    containers = {
      daemon = {
        image = "gregewing/apcupsd:latest@sha256:67c34d6b993f60f5d953e385b07d8db6276050c9237c092d357964f9fd702ee9";

        extraOptions = [ "--device=/dev/usb/hiddev0" ];

        volumes = [
          "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket"
        ];
      };

      exporter = {
        image = "sfudeus/apcupsd_exporter:latest@sha256:5138b68329b3543101eb8bb3841104304ef4a004b2591175760b1ac8b71e86d0";
        cmd = [ "-apcupsd.addr=apcupsd-daemon:3551" ];
        metrics.port = 9162;
      };
    };
  };
}
