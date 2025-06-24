{ writeShellApplication
, octodns
, config
}:
let
  octodns-with-providers = octodns.withProviders (ps: [ octodns.providers.cloudflare ]);
in
writeShellApplication {
  name = "deploy-dns";
  text = ''
    exec ${octodns-with-providers}/bin/octodns-sync --config-file=${config.entries."octodns.yaml"} "$@"
  '';
}
