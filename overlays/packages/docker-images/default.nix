{ lib
, runCommand
, cacert
, skopeo
, writeText
, images
}:
let
  imageList = writeText "docker-images.txt" (lib.concatStringsSep "\n" images);
in
runCommand "docker-images"
{
  nativeBuildInputs = [ skopeo ];

  __noChroot = true;

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  meta.platforms = lib.platforms.linux;
} ''
  bash ${./check.sh} ${imageList}
  touch $out
''
