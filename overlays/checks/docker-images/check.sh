results=$(mktemp -d)
trap 'rm -rf "$results"' EXIT

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

  if [ -n "$digest" ] && [[ ${name##*/} == *:* ]]; then
    name=${name%:*}
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

fail_platforms() {
  local key=$1 image=$2 reason=$3
  reason=${reason:-no error output, possibly timed out}
  local platform
  while read -r platform; do
    local slug=${platform//\//-}
    printf 'invalid image: %s (%s: %s)\n' "$image" "$platform" "$reason" \
      >"$results/$key.$slug.fail"
  done <"$results/$key.platforms"
}

check_image() {
  local platforms_file=$1
  local key=${platforms_file##*/}
  key=${key%.platforms}
  local image
  image=$(cat "$results/$key.image")
  local ref
  ref=$(docker_ref "$image")

  local pin=""
  case "$ref" in
    *@sha256:*) pin=${ref##*@} ;;
  esac

  local fetched=0
  local digest=""
  for _ in 1 2; do
    if timeout 60 skopeo inspect --raw "docker://$ref" >"$results/$key.raw" 2>"$results/$key.err"; then
      fetched=1
      digest="sha256:$(sha256sum <"$results/$key.raw" | cut -d ' ' -f 1)"
      break
    fi
    sleep 2
  done
  if [ "$fetched" -eq 0 ]; then
    fail_platforms "$key" "$image" "$(tail -n 1 "$results/$key.err")"
    return
  fi
  if [ -n "$pin" ] && [ "$digest" != "$pin" ]; then
    fail_platforms "$key" "$image" \
      "registry serves manifest $digest, config pins $pin"
    return
  fi

  local available=""
  if jq -e '.manifests | type == "array"' "$results/$key.raw" >/dev/null; then
    available=$(jq -r '.manifests[].platform // empty
      | select(.os != null and .architecture != null and .os != "unknown" and .architecture != "unknown")
      | "\(.os)/\(.architecture)"' "$results/$key.raw" | sort -u)
  else
    local repo=${ref%@*}
    if [[ ${repo##*/} == *:* ]]; then
      repo=${repo%:*}
    fi
    local config_ref="$repo@$digest"
    local ok=0
    for _ in 1 2; do
      if timeout 60 skopeo inspect --config "docker://$config_ref" >"$results/$key.config" 2>"$results/$key.config.err"; then
        ok=1
        break
      fi
      sleep 2
    done
    if [ "$ok" -eq 0 ]; then
      fail_platforms "$key" "$image" "$(tail -n 1 "$results/$key.config.err")"
      return
    fi
    available=$(jq -r '"\(.os)/\(.architecture)"' "$results/$key.config")
  fi

  local platform
  while read -r platform; do
    local slug=${platform//\//-}
    if printf '%s\n' "$available" | grep -qxF "$platform"; then
      printf 'valid image: %s (%s)\n' "$image" "$platform"
      : >"$results/$key.$slug.ok"
    else
      local served
      served=$(printf '%s' "$available" | paste -sd ',' -)
      printf 'invalid image: %s (%s: no manifest for this platform, registry serves %s)\n' \
        "$image" "$platform" "${served:-none}" \
        >"$results/$key.$slug.fail"
    fi
  done <"$results/$key.platforms"
}

export results
export -f docker_ref fail_platforms check_image

while read -r image platform || [ -n "$image" ]; do
  [ -n "$image" ] || continue
  if [ -z "$platform" ]; then
    printf 'error: no platform given for %s\n' "$image" >&2
    exit 1
  fi
  key=$(printf %s "$image" | md5sum | cut -d ' ' -f 1)
  printf '%s\n' "$platform" >>"$results/$key.platforms"
  printf '%s\n' "$image" >"$results/$key.image"
done <"$1"

count=0
pairs=0
for file in "$results"/*.platforms; do
  [ -e "$file" ] || continue
  sort -u -o "$file" "$file"
  count=$((count + 1))
  pairs=$((pairs + $(wc -l <"$file")))
done
if [ "$count" -eq 0 ]; then
  printf 'error: the flake collected no container images\n' >&2
  exit 1
fi
printf 'checking %s container images (%s image/platform pairs)\n' "$count" "$pairs"

failed=0
printf '%s\0' "$results"/*.platforms |
  xargs -0 -P 8 -n 1 bash -c 'check_image "$1"' _ || failed=1

for file in "$results"/*.platforms; do
  base=${file%.platforms}
  while read -r platform; do
    slug=${platform//\//-}
    [ -e "$base.$slug.ok" ] && continue
    failed=1
    if [ -e "$base.$slug.fail" ]; then
      cat "$base.$slug.fail"
    else
      printf 'error: %s (%s) was not checked\n' "$(cat "$base.image")" "$platform"
    fi
  done <"$file"
done
exit "$failed"
