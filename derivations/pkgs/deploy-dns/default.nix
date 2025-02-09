{ writeShellApplication
, python3
, octodns
, octodns-cloudflare
, octodns-config
}:
let
  env = python3.withPackages (_: [ octodns octodns-cloudflare ]);
in
writeShellApplication {
  name = "deploy-dns";
  runtimeInputs = [ env ];
  text = ''
    exec octodns-sync --config-file=${octodns-config.entries."octodns.yaml"} "$@"
  '';
}
