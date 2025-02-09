{ lib
, python3Packages
, fetchFromGitHub
, octodns
}:
let
  inherit (python3Packages) buildPythonPackage requests setuptools;
in
buildPythonPackage rec {
  pname = "octodns-cloudflare";
  version = "0.0.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "octodns";
    repo = "octodns-cloudflare";
    tag = "v${version}";
    hash = "sha256-GbZbmfAaku+IJwmxKm6f5Qj/Dam+CRax6z49uMerOlA=";
  };

  patches = [ ./keyerror-fix.patch ];

  build-system = [
    setuptools
  ];

  dependencies = [
    octodns
    requests
  ];

  env.OCTODNS_RELEASE = 1;

  doCheck = false;

  meta = with lib; {
    description = "Cloudflare API provider for octoDNS";
    homepage = "https://github.com/octodns/octodns-cloudflare/";
    changelog = "https://github.com/octodns/octodns-cloudflare/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = [ ];
  };
}
