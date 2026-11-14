{ writeShellApplication
, octodns
, callPackage
}:
let
  octodns-with-providers = octodns.withProviders (ps: [ octodns.providers.cloudflare ]);
  config = callPackage ./config { };
in
writeShellApplication {
  name = "deploy-dns";
  text = ''
    exec ${octodns-with-providers}/bin/octodns-sync --config-file=${config.entries."octodns.yaml"} "$@"
  '';

  passthru.config = config;
}
