{ self, config, osConfig, lib, pkgs, ... }:
let
  cfg = config.presets.forgejo-runner;

  yaml = pkgs.formats.yaml { };

  initScript = pkgs.writeScript "init-runner.sh" ''
    #!/usr/bin/env sh

    export LABELS_FILE=".labels"
    export LABELS_CURRENT="$(cat $LABELS_FILE 2>/dev/null || echo 0)"

    if [ ! -e ".runner" ] || [ "$LABELS" != "$LABELS_CURRENT" ]; then
        # remove existing registration file, so that changing the labels forces a re-registration
        rm -f ".runner"

        # perform the registration
        forgejo-runner register --no-interactive \
            --instance "$INSTANCE" \
            --token "$TOKEN" \
            --name "$NAME" \
            --labels "$LABELS" \
            --config /data/config.yml

        # and write back the configured labels
        echo "$LABELS" > "$LABELS_FILE"
    fi

    sleep 2

    exec forgejo-runner -c /data/config.yml daemon
  '';

  configFile = yaml.generate "runner-config.yml" {
    runner = {
      capacity = 5;
    };

    container = {
      enable_ipv6 = true;
      force_pull = true;
    };
  };
in
{
  options.presets.forgejo-runner = with lib; {
    enable = mkEnableOption "Enable forgejo-runner";
  };

  config = lib.mkIf (cfg.enable) {
    volumes = {
      runner = { type = "ephemeral"; acls = [ "u:1000:rwx" ]; };
    };

    containers = {
      runner = {
        image = "data.forgejo.org/forgejo/runner:11.1.2@sha256:b39a6d5cea3f2a70ceca16c026789d566e11795ff112e699df6af7c12386df0e";

        environment = {
          DOCKER_HOST = "tcp://${config.containers.podman.fullName}:2375";

          NAME = osConfig.networking.hostName;
          INSTANCE = "https://${self.hosts.tide.cfg.apps.forgejo.ingresses.app.domain}";

          LABELS = builtins.concatStringsSep "," [
            "ubuntu-latest:docker://forge.auxves.dev/actions/runner-base:latest"
          ];
        };

        environmentFiles = [ osConfig.sops.secrets."forgejo/runner-env".path ];

        volumes = [
          "${config.volumes.runner.path}:/data"
          "${initScript}:/init-runner.sh"
          "${configFile}:/data/config.yml"
        ];

        cmd = [ "/init-runner.sh" ];

        dependsOn = [ config.containers.podman.fullName ];
      };

      podman = {
        image = "quay.io/podman/stable:v5.6.1@sha256:e18670977ab9cf94be3dec34f6118bf309da233d3258b4623471309c7c95d31d";
        user = "root";
        extraOptions = [ "--privileged" ];
        cmd = [ "podman" "system" "service" "-t=0" "tcp://0.0.0.0:2375" ];
      };
    };
  };
}
