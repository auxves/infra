{ lib, fetchFromGitea, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "resty-kv";
  version = "0.1.0";

  src = fetchFromGitea {
    domain = "forge.auxves.dev";
    owner = "arno";
    repo = pname;
    rev = "714c1207cec50b5ea5b73ac1739b6949f18020ab";
    hash = "sha256-rAEm2PoWC4SLNrJg5tIRkGd9aks2XQzKmDRJlyBmtTA=";
  };

  cargoHash = "sha256-ItkXqk5dOkbY0Y8euTE+uDoGkQ1zfG+ZCni0OqN2aT8=";

  meta = with lib; {
    description = "A simple key-value store based on Sqlite with an HTTP API";
    homepage = "https://github.com/auxves/resty-kv";
    license = licenses.gpl3;
  };
}
