{ ... }: {
  apps.apcupsd = {
    containers = {
      daemon = {
        image = "gregewing/apcupsd:latest@sha256:0b0ffda45942bbc5d8d6bda30a33f1c6dc4fdd16db672085aa6a757b96110467";

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
