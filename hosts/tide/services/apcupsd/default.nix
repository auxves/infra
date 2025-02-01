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
        image = "sfudeus/apcupsd_exporter:latest@sha256:944f53d0fd288931686fe01ad850b2274f7d661c646934da4daaff3644e38010";
        cmd = [ "-apcupsd.addr=apcupsd-daemon:3551" ];
        metrics.port = 9162;
      };
    };
  };
}
