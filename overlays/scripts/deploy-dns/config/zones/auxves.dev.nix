{ hosts, ... }: {
  "*.dev" = [
    { type = "A"; value = hosts.tide.cfg.meta.addresses.internal.v4; }
    { type = "AAAA"; value = hosts.tide.cfg.meta.addresses.internal.v6; }
  ];

  "_minecraft._tcp.mc" = [{
    type = "SRV";
    value = {
      priority = 0;
      weight = 100;
      port = 25565;
      target = "tide.auxves.dev.";
    };
  }];
}
