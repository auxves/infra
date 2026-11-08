{ lib
, runCommand
, cacert
, jq
, skopeo
, writeText
}:
let
  hosts = lib.internal.filterHosts (host: host.variant == "nixos");

  ociPlatforms = {
    "x86_64-linux" = "linux/amd64";
    "aarch64-linux" = "linux/arm64";
  };

  platformForHost = host:
    let
      system = host.cfg.nixpkgs.hostPlatform.system;
    in
    ociPlatforms.${system}
      or (throw "docker-images: no OCI platform mapping for system ${system}");

  pairsForHost = host:
    map
      (image: { inherit image; platform = platformForHost host; })
      (lib.internal.containerImagesForHost host);

  grouped = lib.groupBy (pair: pair.image)
    (lib.concatMap pairsForHost hosts);

  entries = lib.sort (a: b: a.image < b.image)
    (lib.mapAttrsToList
      (image: pairs: {
        inherit image;
        platforms = lib.sort builtins.lessThan
          (lib.unique (map (pair: pair.platform) pairs));
      })
      grouped);

  lines = lib.concatMap
    (entry: map (platform: "${entry.image} ${platform}") entry.platforms)
    entries;

  imageList = writeText "docker-images.txt" (lib.concatStringsSep "\n" lines);
in
runCommand "docker-images"
{
  nativeBuildInputs = [ jq skopeo ];

  __noChroot = true;

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  meta.platforms = lib.platforms.linux;
} ''
  bash ${./check.sh} ${imageList}
  touch $out
''
