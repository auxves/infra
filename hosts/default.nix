{ lib, ... }:
let
  buildHost = name: { system, variant }:
    let
      host = rec {
        inherit name system variant;
        platform = lib.platformOf system;
        configuration = lib.variants.${variant} host;
        cfg = configuration.config;
      };
    in
    host;
in
lib.mapAttrs buildHost {
  blaze = { system = "aarch64-darwin"; variant = "darwin"; };
  tide = { system = "aarch64-linux"; variant = "nixos"; };
}
