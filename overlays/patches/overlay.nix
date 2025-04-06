final: prev: {
  auxves.checks = prev.auxves.checks or { } // prev.lib.internal.prefixAttrs "patches" {
    inherit (final) podman sanoid;
  };

  podman = prev.podman.overrideAttrs (old: {
    patches = (old.patches or [ ])
      ++ [ ./podman/rfc3339nano-logs.patch ];
  });

  sanoid = prev.sanoid.overrideAttrs (old: {
    version = "unstable";
    src = prev.fetchFromGitHub {
      owner = "jimsalterjrs";
      repo = old.pname;
      rev = "826d4d1c075e3310ec3c1d0297905d986e9470c2";
      hash = "sha256-RXfOX3UJeoUub+/Xq4UnPEPJQq36aqQZNuIlor93xE4=";
    };

    meta = old.meta // {
      platforms = prev.lib.platforms.linux;
    };
  });
}
