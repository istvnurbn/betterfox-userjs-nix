#!/usr/bin/env bash
# Extract user_pref() entries from Betterfox files into JSON, one file per source
# for Smoothfox, one file per OPTION section as they are mutually exclusive
set -euo pipefail

# {"key": value} per active user_pref() line of stdin -> <outbase>.json;
# with bysection=1, prefs are grouped by "* OPTION: NAME" headers into
# <outbase>-<option-slug>.json (prefs before any header -> <outbase>.json)
extract() {
  local outbase="$1" bysection="${2:-0}" tmp j name out
  tmp=$(mktemp -d)
  # always emit <outbase>.json in plain mode, so an empty source trips the guard below
  [ "$bysection" = 1 ] || touch "$tmp/__base__.jsonl"
  awk -v out="$tmp/" -v bysection="$bysection" '
    bysection == 1 && /OPTION:/ {
      s = $0
      sub(/.*OPTION:[ \t]*/, "", s)
      sub(/[ \t*\/]*$/, "", s)
      gsub(/[^A-Za-z0-9]+/, "-", s)
      sub(/^-/, "", s); sub(/-$/, "", s)
      slug = tolower(s)
      next
    }
    /^[ \t]*user_pref\(/ {
      line = $0
      sub(/^[ \t]*/, "", line)
      sub(/\);.*/, "", line)
      key = line
      sub(/^user_pref\([ \t]*"/, "", key)
      sub(/".*$/, "", key)
      val = line
      sub(/^user_pref\([ \t]*"[^"]*"[ \t]*,[ \t]*/, "", val)
      f = out (slug == "" ? "__base__" : slug) ".jsonl"
      printf "{\"%s\": %s}\n", key, val >> f
      close(f)
    }
  '
  for j in "$tmp"/*.jsonl; do
    [ -e "$j" ] || continue
    name=$(basename "$j" .jsonl)
    out="${outbase}-${name}.json"
    [ "$name" = "__base__" ] && out="${outbase}.json"
    # explicit return: set -e is off inside && lists and if-conditions
    jq -s 'add // {}' "$j" > "$out" || return 1
    echo "wrote $out"
  done
  rm -rf "$tmp"
}

# sourced by tests/extract-test.sh: define extract() only
[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

base="https://raw.githubusercontent.com/yokoffing/Betterfox/main"

mkdir -p prefs
# start clean so renamed or removed upstream sections do not linger
rm -f prefs/*.json

for f in user.js Fastfox.js Peskyfox.js Securefox.js; do
  out=$(tr '[:upper:]' '[:lower:]' <<<"${f%.js}") # not ${out,,}: macOS ships bash 3.2
  curl -fsSL "$base/$f" | extract "prefs/$out"
done

curl -fsSL "$base/Smoothfox.js" | extract prefs/smoothfox 1

# an empty module means upstream changed format and prefs were dropped silently
for f in prefs/*.json; do
  jq -e 'length > 0' "$f" >/dev/null || { echo "error: $f has no prefs" >&2; exit 1; }
done
compgen -G 'prefs/smoothfox-*.json' >/dev/null || { echo "error: no smoothfox sections" >&2; exit 1; }
