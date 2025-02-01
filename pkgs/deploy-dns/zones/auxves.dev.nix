{ hosts, ... }:
let
  tide = hosts.tide.cfg.meta.addresses;
  harpy = hosts.harpy.cfg.meta.addresses;
in
{
  "*.tide" = [
    { type = "A"; value = tide.public.v4; }
    { type = "AAAA"; value = tide.public.v6; }
  ];

  "*.tide.x" = [
    { type = "A"; value = tide.internal.v4; }
    { type = "AAAA"; value = tide.internal.v6; }
  ];

  "*.harpy.x" = [
    { type = "A"; value = harpy.internal.v4; }
    { type = "AAAA"; value = harpy.internal.v6; }
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
