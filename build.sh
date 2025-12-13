#!/usr/bin/env bash
set -e

echo "Installing pandoc..."

PANDOC_VERSION="3.1.11"
PANDOC_FILENAME="pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz"

curl -L "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/${PANDOC_FILENAME}" \
  | tar xz

PANDOC_DIR="pandoc-${PANDOC_VERSION}"
export PATH="$PWD/${PANDOC_DIR}/bin:$PATH"

echo "Pandoc installed:"
pandoc --version

echo "Building HTML..."

mkdir -p dist

./ciallo.sh src | pandoc \
  --standalone \
  --metadata title="莫号模板库" \
  -o book/index.html

echo "Successfully built book/index.html"