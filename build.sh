#!/bin/sh
# Cloudflare Pages 构建入口；全部逻辑在 ci/cloudflare_build.py
set -e
exec python3 ci/cloudflare_build.py
