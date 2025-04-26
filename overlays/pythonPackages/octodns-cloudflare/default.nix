{ lib
, fetchFromGitHub
, buildPythonPackage
, octodns
, requests
, setuptools
}:
buildPythonPackage rec {
  pname = "octodns-cloudflare";
  version = "0.0.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "octodns";
    repo = "octodns-cloudflare";
    tag = "v${version}";
    hash = "sha256-VHmi/ClCZCruz0wSSZC81nhN7i31vK29TsYzyrRJNTY=";
  };

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
