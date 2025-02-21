final: prev: {
  auxves.checks = prev.auxves.checks or { } // final.lib.prefixAttrs "scripts" {
    inherit (final.scripts) deploy-dns sync-ao3;
  };

  scripts = {
    deploy-dns =
      let
        config = final.callPackage ./deploy-dns/config { };
      in
      final.callPackage ./deploy-dns { inherit config; } // {
        inherit config;
      };

    sync-ao3 = final.nuModules.callPackage ./sync-ao3 { };
  };
}
