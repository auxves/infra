{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "resty-kv";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "auxves";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-rAEm2PoWC4SLNrJg5tIRkGd9aks2XQzKmDRJlyBmtTA=";
  };

  cargoHash = "sha256-ItkXqk5dOkbY0Y8euTE+uDoGkQ1zfG+ZCni0OqN2aT8=";

  meta = with lib; {
    description = "A simple key-value store based on Sqlite with an HTTP API";
    homepage = "https://github.com/auxves/resty-kv";
    license = licenses.gpl3;
  };
}
