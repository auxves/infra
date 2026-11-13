{ self, config, lib, pkgs, ... }:
let
  presetCfg = config.presets.apps.forgejo-runner;
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
  options.presets.apps.forgejo-runner = with lib; {
    enable = mkEnableOption "Enable forgejo-runner";
  };

  config = lib.mkIf (presetCfg.enable) {
    sops.secrets."forgejo/runner-env" = { };

    apps.forgejo = {
      volumes = {
        runner = { type = "ephemeral"; acls = [ "u:1000:rwx" ]; };
      };

      containers = {
        runner = {
          image = "data.forgejo.org/forgejo/runner:13.2.1@sha256:568cea8c15ddc01fc8f330124892f572af7db37fa28344a2c1914405793bf61d";

          environment = {
            DOCKER_HOST = "tcp://${cfg.containers.podman.fullName}:2375";

            NAME = config.networking.hostName;
            INSTANCE = "https://${self.hosts.tide.cfg.apps.forgejo.ingresses.app.domain}";

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
          image = "quay.io/podman/stable:v5.8.9@sha256:0ccbc4e7f79f9c33e7fc959be59f714abbc0f4c9cffbe14f5bceff537a014738";
          user = "root";
          extraOptions = [ "--privileged" ];
          cmd = [ "podman" "system" "service" "-t=0" "tcp://0.0.0.0:2375" ];
        };
      };
    };
  };
}
