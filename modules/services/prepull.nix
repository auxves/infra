{ inputs, ... }: {
  flake.modules.nixos.prepull = { lib, config, pkgs, ... }:
    let
      images = inputs.self.lib.internal.collectContainerImages config.apps (container: container.prepull);

      pullScript = pkgs.writeShellApplication {
        name = "prepull-container-images";
        runtimeInputs = [
          config.virtualisation.podman.package
          pkgs.coreutils
        ];
        text = ''
          images=(
            ${lib.concatMapStringsSep "\n        " lib.escapeShellArg images}
          )

          pull_one() {
            local image
            image=$1

            if podman image exists "$image" >/dev/null 2>&1; then
              return 0
            fi

            if timeout 600 podman pull "$image" >/dev/null 2>&1; then
              echo "prepull: pulled $image"
            else
              echo "prepull: pull failed $image"
            fi
          }

          deadline=$((SECONDS + 1200))
          running=0
          for image in "''${images[@]}"; do
            if [ "$SECONDS" -ge "$deadline" ]; then
              echo "prepull: time budget spent, remaining images pull at unit start"
              break
            fi

            pull_one "$image" &
            running=$((running + 1))

            if [ "$running" -ge 4 ]; then
              wait -n || true
              running=$((running - 1))
            fi
          done

          wait || true
        '';
      };
    in
    {
      config = lib.mkIf (images != [ ]) {
        system.preSwitchChecks.prepull-container-images = ''
          case "$2" in
            dry-activate | check) ;;
            *) ${lib.getExe pullScript} || true ;;
          esac
        '';
      };
    }
  ;
}
