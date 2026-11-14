{ inputs, ... }: {
  flake.modules.generic.meta = { lib, ... }: {
    options.meta = with lib; {
      addresses.public.v4 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The public IPv4 address of this node";
      };

      addresses.public.v6 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The public IPv6 address of this node";
      };

      addresses.internal.v4 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The internal IPv4 address of this node";
      };

      addresses.internal.v6 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The internal IPv6 address of this node";
      };
    };
  };

  flake.modules.nixos.meta = {
    imports = [ inputs.self.modules.generic.meta ];
  };

  flake.modules.darwin.meta = {
    imports = [ inputs.self.modules.generic.meta ];
  };
}
