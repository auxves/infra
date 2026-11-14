{ config, lib, ... }: {
  options.flake.hosts = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.hosts =
    let
      toHost = variant: name: configuration: {
        inherit name variant;
        cfg = configuration.config;
      };
    in
    lib.mapAttrs (toHost "nixos") config.flake.nixosConfigurations
    // lib.mapAttrs (toHost "darwin") config.flake.darwinConfigurations;
}
