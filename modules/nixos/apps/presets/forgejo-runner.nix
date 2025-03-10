{ self, name, config, osConfig, lib, pkgs, ... }:
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
        image = "data.forgejo.org/forgejo/runner:6.2.2@sha256:fe4f55e1842a50ffa321324f80128987bef3722dce1a911f963eecfd740309e7";

        environment = {
          DOCKER_HOST = "tcp://forgejo-podman:2375";

          NAME = osConfig.networking.hostName;
          INSTANCE = "https://${self.hosts.tide.cfg.apps.forgejo.ingress.domain}";

          LABELS = builtins.concatStringsSep "," [
            "ubuntu-latest:docker://node:23-bookworm"
            "nixos-latest:docker://nixos/nix"
          ];
        };

        environmentFiles = [ osConfig.sops.secrets."forgejo/runner-env".path ];

        volumes = [
          "${config.volumes.runner.path}:/data"
          "${initScript}:/init-runner.sh:ro"
          "${configFile}:/data/config.yml:ro"
        ];

        cmd = [ "/init-runner.sh" ];

        dependsOn = [ "${name}-podman" ];
      };

      podman = {
        image = "quay.io/podman/stable:v5.4.0@sha256:431d4c23c8651e7517a443ee8d5a8da14955a6ddb77f896ee344f29b63508e41";
        user = "podman";
        extraOptions = [ "--privileged" ];
        cmd = [ "podman" "system" "service" "-t=0" "tcp://0.0.0.0:2375" ];
      };
    };
  };
}
