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
            --config config.yml

        # and write back the configured labels
        echo "$LABELS" > "$LABELS_FILE"
    fi

    sleep 2

    exec forgejo-runner daemon
  '';

  configFile = yaml.generate "runner-config.yml" {
    runner = {
      capacity = 5;
      shutdown_timeout = 0;
    };

    cache.enable = true;

    containers.enable_ipv6 = true;
  };
in
{
  options.presets.forgejo-runner = with lib; {
    enable = mkEnableOption "Enable forgejo-runner";
  };

  config = lib.mkIf (cfg.enable) {
    volumes.runner = {
      type = "ephemeral";
      acls = [ "u:1000:rwx" ];
    };

    containers = {
      runner = {
        image = "data.forgejo.org/forgejo/runner:6.4.0@sha256:e8dd2880f2fc81984d2308b93f1bc064dfb41187942300676536c09a3b30043d";

        environment = {
          DOCKER_HOST = "tcp://forgejo-podman:2375";

          NAME = osConfig.networking.hostName;
          INSTANCE = "https://${self.hosts.tide.cfg.apps.forgejo.ingresses.app.domain}";

          LABELS = builtins.concatStringsSep "," [
            "ubuntu-latest:docker://node:23-bookworm"
            "nixos-latest:docker://nixos/nix"
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
        image = "quay.io/podman/stable:v5.5.2@sha256:866bbcac26adb7ff238145405fa0ade33bd7e9c7bb77a5c05f819dce8a753063";
        user = "podman";
        extraOptions = [ "--privileged" ];
        cmd = [ "podman" "system" "service" "-t=0" "tcp://0.0.0.0:2375" ];
      };
    };
  };
}
