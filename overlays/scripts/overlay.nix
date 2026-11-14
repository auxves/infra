final: prev: {
  auxves.checks = prev.auxves.checks or { } // prev.lib.internal.prefixAttrs "scripts" {
    inherit (final.scripts) deploy-dns;
  };

  scripts = {
    deploy-dns = final.callPackage ./deploy-dns { };
  };
}
