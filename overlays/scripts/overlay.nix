final: prev: {
  auxves.checks = prev.auxves.checks or { } // prev.lib.internal.prefixAttrs "scripts" {
    inherit (final.scripts) deploy-dns;
  };

  scripts = {
    deploy-dns =
      let
        config = final.callPackage ./deploy-dns/config { };
      in
      final.callPackage ./deploy-dns { inherit config; } // {
        inherit config;
      };
  };
}
