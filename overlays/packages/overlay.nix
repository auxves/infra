final: prev: {
  auxves.checks = prev.auxves.checks or { } // final.lib.prefixAttrs "packages" {
    inherit (final) resty-kv;
  };

  resty-kv = final.callPackage ./resty-kv { };
}
