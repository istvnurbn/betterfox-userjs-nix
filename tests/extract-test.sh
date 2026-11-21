#!/usr/bin/env bash
# Parser check: run extract() on a fixture and diff against expected JSON
set -euo pipefail
cd "$(dirname "$0")"
source ../betterfox-extract.sh

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/plain" "$tmp/split"
extract "$tmp/plain/fixture" <fixture.js >/dev/null
extract "$tmp/split/fixture" 1 <fixture.js >/dev/null
diff -r expected "$tmp"

if extract "$tmp/bad" <<<"user_pref(\"a\", 'x');" 2>/dev/null; then
  echo "FAIL: invalid JSON value accepted" >&2
  exit 1
fi
echo "ok"
