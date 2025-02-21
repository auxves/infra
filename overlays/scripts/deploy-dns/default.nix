{ writeShellApplication
, python3
, octodns
, config
}:
let
  env = python3.withPackages (ps: with ps; [ octodns octodns-cloudflare ]);
in
writeShellApplication {
  name = "deploy-dns";
  runtimeInputs = [ env ];
  text = ''
    exec octodns-sync --config-file=${config.entries."octodns.yaml"} "$@"
  '';
}
