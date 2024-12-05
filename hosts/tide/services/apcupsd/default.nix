{ ... }: {
  virtualisation.oci-containers.containers.apcupsd = {
    image = "gregewing/apcupsd:latest@sha256:bd956e86c174b1b652d3ffd5fe7540d5d640d3dd3f9b1ebe37970650812f9096";

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
