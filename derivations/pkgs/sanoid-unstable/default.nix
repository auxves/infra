{ fetchFromGitHub, sanoid }:
sanoid.overrideAttrs (prev: {
  version = "unstable";
  src = fetchFromGitHub {
    owner = "jimsalterjrs";
    repo = prev.pname;
    rev = "826d4d1c075e3310ec3c1d0297905d986e9470c2";
    hash = "sha256-RXfOX3UJeoUub+/Xq4UnPEPJQq36aqQZNuIlor93xE4=";
  };
})
