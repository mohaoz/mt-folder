#!/usr/bin/env bash
set -e

# Check if pandoc is already installed
if command -v pandoc &> /dev/null; then
  echo "Pandoc is already installed:"
  pandoc --version
else
  echo "Installing pandoc..."

  PANDOC_VERSION="3.1.11"
  PANDOC_FILENAME="pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz"

  curl -L "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/${PANDOC_FILENAME}" \
    | tar xz

  PANDOC_DIR="pandoc-${PANDOC_VERSION}"
  export PATH="$PWD/${PANDOC_DIR}/bin:$PATH"

  echo "Pandoc installed:"
  pandoc --version
fi

echo "Building HTML..."

mkdir -p book

# Ensure scripts are executable
chmod +x ciallo.sh 2>/dev/null || true

echo "Processing source files..."
./ciallo.sh src > /tmp/ciallo_output.md

echo "Running pandoc..."
pandoc --standalone \
  --metadata title="莫号模板库" \
  -o book/index.html \
  /tmp/ciallo_output.md


echo "Successfully built book/index.html"