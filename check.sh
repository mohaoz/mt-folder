#!/usr/bin/env bash
set -euo pipefail

if [ -z "${CXX:-}" ]; then
  if command -v g++-15 >/dev/null 2>&1; then
    CXX=g++-15
  elif command -v g++ >/dev/null 2>&1; then
    CXX=g++
  else
    CXX=c++
  fi
fi
STD=${STD:-gnu++23}
TMP=${TMPDIR:-/tmp}/mt-folder-check.md

./ciallo.sh src > "$TMP"

while IFS= read -r file; do
  "$CXX" -std="$STD" -Wno-pragma-once-outside-header -fsyntax-only -x c++ "$file"
done < <(find src -type f \( -name '*.cpp' -o -name '*.hpp' \) | sort)

echo "Static check passed"
