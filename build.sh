#!/bin/bash
set -e

echo "Installing mdBook"
MDBOOK_VERSION="v0.4.37"
MDBOOK_FILENAME="mdbook-${MDBOOK_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

echo "Downloading mdBook version $MDBOOK_VERSION..."

curl -L "https://github.com/rust-lang/mdBook/releases/download/${MDBOOK_VERSION}/${MDBOOK_FILENAME}" | tar xvz

echo "Building..."
./mdbook build

echo "Successfully Build."
