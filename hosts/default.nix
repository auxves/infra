{ lib, ... }:
let
  buildHost = name: { system, variant }:
    let
      host = rec {
        inherit name system variant;
        platform = lib.internal.platformOf system;
        configuration = lib.internal.variants.${variant} host;
        cfg = configuration.config;
      };
    in
    host;
in
lib.mapAttrs buildHost {
  blaze = { system = "aarch64-darwin"; variant = "darwin"; };
  tide = { system = "x86_64-linux"; variant = "nixos"; };
  harpy = { system = "aarch64-linux"; variant = "nixos"; };
}
