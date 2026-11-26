{ inputs, ... }: {
  flake.modules.nixos.forgejo-runner = { config, lib, pkgs, ... }:
    let
      cfg = config.apps.forgejo;

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
      config = {
        sops.secrets."forgejo/runner-env" = { };

        apps.forgejo = {
          volumes = {
            runner = { type = "ephemeral"; acls = [ "u:1000:rwx" ]; };
          };

          containers = {
            runner = {
              image = "data.forgejo.org/forgejo/runner:13.2.2@sha256:a8543a45fe62bebef0534d5c223cf485d3294e6dd2e42a82dbcbfd40c54a6a22";

              environment = {
                DOCKER_HOST = "tcp://${cfg.containers.podman.fullName}:2375";

                NAME = config.networking.hostName;
                INSTANCE = "https://${inputs.self.hosts.tide.cfg.apps.forgejo.ingresses.app.domain}";

                LABELS = builtins.concatStringsSep "," [
                  "ubuntu-latest:docker://forge.auxves.dev/actions/runner-base:latest"
                ];
              };

              environmentFiles = [ config.sops.secrets."forgejo/runner-env".path ];

              volumes = [
                "${cfg.volumes.runner.path}:/data"
                "${initScript}:/init-runner.sh"
                "${configFile}:/data/config.yml"
              ];

              cmd = [ "/init-runner.sh" ];

              dependsOn = [ cfg.containers.podman.fullName ];
            };

            podman = {
              image = "quay.io/podman/stable:v6.2.0";
              user = "root";
              extraOptions = [ "--privileged" ];
              cmd = [ "podman" "system" "service" "-t=0" "tcp://0.0.0.0:2375" ];
            };
          };
        };
      };
    };
}
