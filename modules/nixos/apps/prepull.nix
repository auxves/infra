{ lib, config, pkgs, ... }:
let
  images = lib.internal.containerImagesForHost { cfg = config; };

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

      results=$(mktemp -d)
      trap 'rm -rf "$results"' EXIT

      pull_one() {
        local image result
        image=$1
        result=$2

        if podman image exists "$image"; then
          printf '%s\n' present > "$result"
          return 0
        fi

        if timeout 600 podman pull "$image"; then
          printf '%s\n' pulled > "$result"
          echo "prepull: pulled $image"
        else
          printf '%s\n' failed > "$result"
          echo "prepull: pull failed $image"
        fi
      }

      deadline=$((SECONDS + 1200))
      running=0
      result_index=0
      for image in "''${images[@]}"; do
        if [ "$SECONDS" -ge "$deadline" ]; then
          echo "prepull: time budget spent, remaining images pull at unit start"
          break
        fi

        result_index=$((result_index + 1))
        pull_one "$image" "$results/$result_index" &
        running=$((running + 1))

        if [ "$running" -ge 4 ]; then
          wait -n || true
          running=$((running - 1))
        fi
      done

      wait || true

      present=0
      pulled=0
      failed=0
      for result in "$results"/*; do
        [ -e "$result" ] || continue

        case "$(< "$result")" in
          present) present=$((present + 1)) ;;
          pulled) pulled=$((pulled + 1)) ;;
          failed) failed=$((failed + 1)) ;;
        esac
      done

      echo "prepull: summary present $present, pulled $pulled, failed $failed"
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
