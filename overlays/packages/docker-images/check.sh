results=$(mktemp -d)

docker_ref() {
  local image=$1
  local name=$image
  local digest=""

  case "$image" in
    *@*)
      digest=${image##*@}
      name=${image%@*}
      ;;
  esac

  if [ -n "$digest" ]; then
    local last=${name##*/}
    case "$last" in
      *:*)
        if [ "$last" = "$name" ]; then
          name=${last%%:*}
        else
          name=${name%/*}/${last%%:*}
        fi
        ;;
    esac
  fi

  local first=${name%%/*}
  local qualified
  if [ "$first" = "$name" ]; then
    qualified="docker.io/library/$name"
  else
    case "$first" in
      *.* | *:* | localhost) qualified=$name ;;
      *) qualified="docker.io/$name" ;;
    esac
  fi

  if [ -n "$digest" ]; then
    printf '%s@%s\n' "$qualified" "$digest"
  else
    printf '%s\n' "$qualified"
  fi
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
    if timeout 60 skopeo inspect --raw "docker://$ref" >"$results/$key.raw" 2>"$results/$key.err"; then
      digest="sha256:$(sha256sum <"$results/$key.raw" | cut -d ' ' -f 1)"
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
