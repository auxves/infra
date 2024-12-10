{ ... }: {
  virtualisation.oci-containers.containers.apcupsd = {
    image = "gregewing/apcupsd:latest@sha256:6cf8749a999862d5b076e77caeac0e0c1009a744e7cf7887ea549175c5391dc3";

    extraOptions = [ "--device=/dev/usb/hiddev0" ];

    volumes = [
      "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket"
    ];
  };

  virtualisation.oci-containers.containers.apcupsd-exporter = {
    image = "sfudeus/apcupsd_exporter:latest@sha256:944f53d0fd288931686fe01ad850b2274f7d661c646934da4daaff3644e38010";

    cmd = [ "-apcupsd.addr=apcupsd:3551" ];
  };
}
