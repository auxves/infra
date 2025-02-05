{ ... }: {
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
