{ inputs, ... }: {
  flake.modules.nixos.harpy = { lib, config, ... }: {
    imports = [ inputs.self.modules.nixos.traefik ];

    apps.traefik = {
      containers = {
        traefik = {
          ports = lib.optionals (config.meta.addresses.public.v6 != null) [
            # Public
            "[${config.meta.addresses.public.v6}]:443:8443/tcp"
            "[${config.meta.addresses.public.v6}]:443:8443/udp"
          ] ++ lib.optionals (config.meta.addresses.public.v4 != null) [
            # Public
            "${config.meta.addresses.public.v4}:443:8443/tcp"
            "${config.meta.addresses.public.v4}:443:8443/udp"
          ];
        };
      };
    };
  }
  ;
}
