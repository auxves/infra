results=$(mktemp -d)

docker_ref() {
  local image=$1
  local first=${image%%/*}

  if [ "$first" = "$image" ]; then
    printf 'docker.io/library/%s\n' "$image"
    return
  fi

  case "$first" in
    *.* | *:* | localhost)
      printf '%s\n' "$image"
      ;;
    *)
      local rest=${image#*/}
      case "$rest" in
        */*) printf 'docker.io/%s\n' "$image" ;;
        *) printf 'docker.io/library/%s\n' "$rest" ;;
      esac
      ;;
  esac
}

check_image() {
  local image=$1
  local ref=$(docker_ref "$image")
  local key=$(printf %s "$image" | md5sum | cut -d ' ' -f 1)

  local pin=""
  case "$ref" in
    *@sha256:*) pin=${ref##*@} ;;
  esac

  local digest
  for _ in 1 2; do
    if digest=$(timeout 60 skopeo manifest-digest "docker://$ref" 2>"$results/$key.err"); then
      if [ -n "$pin" ] && [ "$digest" != "$pin" ]; then
        printf 'invalid image: %s (registry serves manifest %s, config pins %s)\n' \
          "$image" "$digest" "$pin" >"$results/$key.fail"
        return
      fi
      printf 'valid image: %s\n' "$image"
      return
    fi
    sleep 2
  done

  printf 'invalid image: %s (%s)\n' "$image" "$(tail -n 1 "$results/$key.err")" >"$results/$key.fail"
}

export results
export -f docker_ref check_image

count=$(grep -c . "$1" || true)
if [ "$count" -eq 0 ]; then
  printf 'error: the flake collected no container images\n' >&2
  exit 1
fi
printf 'checking %s container images\n' "$count"

grep -v '^$' "$1" | xargs -d '\n' -P 8 -n 1 bash -c 'check_image "$1"' _

failed=0
for file in "$results"/*.fail; do
  [ -e "$file" ] || continue
  cat "$file"
  failed=1
done
exit "$failed"
