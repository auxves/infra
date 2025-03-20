{ ... }: {
  apps.apcupsd = {
    containers = {
      daemon = {
        image = "gregewing/apcupsd:latest@sha256:69b3edfbe66305d5ebcffc17f7a7f40b92a537a4f1bcc5b466da9c109d0b2075";

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
