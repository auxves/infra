{ lib, dockerTools, buildGoModule, fetchFromGitHub }:
let
  oauth2-proxy = buildGoModule rec {
    pname = "oauth2-proxy";
    version = "7.6.0";

    src = fetchFromGitHub {
      repo = pname;
      owner = "oauth2-proxy";
      sha256 = "sha256-7DmeXl/aDVFdwUiuljM79CttgjzdTVsSeAYrETuJG0M=";
      rev = "v${version}";
    };

    vendorHash = "sha256-ihFNFtfiCGGyJqB2o4SMYleKdjGR4P5JewkynOsC1f0=";

    # Taken from https://github.com/oauth2-proxy/oauth2-proxy/blob/master/Makefile
    ldflags = [ "-X main.VERSION=${version}" ];

    patches = [ ./route-auth.patch ];

    doCheck = false;

    meta = with lib; {
      description = "A reverse proxy that provides authentication with Google, Github, or other providers";
      homepage = "https://github.com/oauth2-proxy/oauth2-proxy/";
      license = licenses.mit;
      maintainers = teams.serokell.members;
      mainProgram = "oauth2-proxy";
    };
  };
in
dockerTools.buildImage {
  name = "oauth2-proxy";
  tag = "custom";

  fromImage = dockerTools.pullImage {
    imageName = "gcr.io/distroless/static";
    imageDigest = "sha256:8dd8d3ca2cf283383304fd45a5c9c74d5f2cd9da8d3b077d720e264880077c65";
    sha256 = "sha256-nspyhQS7boQpjyIiDFgfxjfxx2ufaN3PWgmHE48IxrA=";
  };

  config = {
    Cmd = [ "${oauth2-proxy}/bin/oauth2-proxy" ];
  };
}
