{ stdenv, unstable, pup }:

{ name
, src
, doCheck ? true
, buildInputs ? [ ]
}:
stdenv.mkDerivation {
  inherit name src doCheck buildInputs;

  installPhase = ''
    mkdir -p $out/lib
    cp -r ${name} $out/lib
  '';

  checkPhase = ''
    ${unstable.nushell}/bin/nu ${./test.nu}
  '';

  passthru.nuModule = true;
}
