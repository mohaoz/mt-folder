#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <file|dir> [more files/dirs]" >&2
  exit 1
fi

AWK_SCRIPT="$(dirname "$0")/ciallo.awk"

files=()

for arg in "$@"; do
  if [ -f "$arg" ]; then
    case "$arg" in
      *.cpp|*.hpp)
        files+=("$arg")
        ;;
      *)
        echo "warning: skipped non-cpp/hpp file: $arg" >&2
        ;;
    esac

  elif [ -d "$arg" ]; then
    while IFS= read -r f; do
      files+=("$f")
    done < <(
      find "$arg" -type f \( -name '*.cpp' -o -name '*.hpp' \) | sort
    )

  else
    echo "error: not found: $arg" >&2
    exit 1
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "error: no .cpp/.hpp files found" >&2
  exit 1
fi

for f in "${files[@]}"; do
  cat "$f"
  printf '\n'  
done | awk -f "$AWK_SCRIPT"
