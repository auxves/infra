{ ... }: {
  virtualisation.oci-containers.containers.apcupsd = {
    image = "gregewing/apcupsd:latest@sha256:9d1deddc7a543fc9cfd7a0213f3bbc8d37ece3ee23069e2db45d9cb9baf36c81";

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
