#!/usr/bin/env bash
# Extract user_pref() entries from Betterfox files into JSON, one file per source
# for Smoothfox, one file per OPTION section as they are mutually exclusive
set -euo pipefail

base="https://raw.githubusercontent.com/yokoffing/Betterfox/main"

mkdir -p prefs

# plain extraction: lines starting with user_pref( -> {"key": value}
extract() {
  sed -n '/^[[:space:]]*user_pref(/ {
    s/);.*$//
    s/^[[:space:]]*user_pref([[:space:]]*"\([^"]*\)"[[:space:]]*,[[:space:]]*\(.*\)$/{"\1": \2}/p
  }'
}

# like extract, but groups prefs by "* OPTION: NAME" headers and writes
# <outbase>-<option-slug>.json per section (prefs before any header -> <outbase>.json)
split_extract() {
  local outbase="$1" tmp j name
  tmp=$(mktemp -d)
  awk -v out="$tmp/" '
    /OPTION:/ {
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
      sub(/\);.*$/, "", line)
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
    if [ "$name" = "__base__" ]; then
      jq -s 'add // {}' "$j" > "${outbase}.json" && echo "wrote ${outbase}.json"
    else
      jq -s 'add // {}' "$j" > "${outbase}-${name}.json" && echo "wrote ${outbase}-${name}.json"
    fi
  done
  rm -rf "$tmp"
}

for f in user.js Peskyfox.js Securefox.js; do
  out="${f%.js}"; out="${out,,}.json"
  curl -fsSL "$base/$f" | extract | jq -s 'add // {}' > "prefs/$out"
  echo "wrote prefs/$out"
done

curl -fsSL "$base/Smoothfox.js" | split_extract "prefs/smoothfox"
