final: prev: {
  auxves.checks = prev.auxves.checks or { } // prev.lib.internal.prefixAttrs "checks" {
    docker-images = final.callPackage ./docker-images { };
  };
}
