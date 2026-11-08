final: prev: {
  auxves.checks = prev.auxves.checks or { } // prev.lib.internal.prefixAttrs "packages" {
    docker-images = final.callPackage ./docker-images { };
  };
}
