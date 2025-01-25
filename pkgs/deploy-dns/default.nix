{ writeShellApplication, python3, octodns, octodns-cloudflare }:
let
  env = python3.withPackages (_: [ octodns octodns-cloudflare ]);
in
writeShellApplication {
  name = "deploy-dns";
  runtimeInputs = [ env ];
  text = ''
    exec octodns-sync --config-file=${../../octodns.yaml} "$@"
  '';
}
