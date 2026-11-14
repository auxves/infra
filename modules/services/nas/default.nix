{ ... }: {
  flake.modules.nixos.tide = { config, ... }: {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "socket options" = "IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072";
          "getwd cache" = "true";
          "strict sync" = "no";
          "sync always" = "no";
          "use sendfile" = "true";
          "deadtime" = "30";
          "min receivefile size" = "16384";
        };

        storage = {
          path = config.disko.devices.zpool.storage.mountpoint;
          browseable = true;
          "read only" = false;
        };
      };
    };
  };
}
