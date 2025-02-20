{ stdenv, unstable, pup }:

{ name
, src
, doCheck ? true
}:
stdenv.mkDerivation {
  inherit name src doCheck;

  buildInputs = [ pup ];

  installPhase = ''
    mkdir -p $out/lib
    cp -r ${name} $out/lib
  '';

  checkPhase = ''
    ${unstable.nushell}/bin/nu ${./test.nu}
  '';

  passthru.nuModule = true;
}
