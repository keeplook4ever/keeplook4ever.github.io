#!/usr/bin/env bash
set -euo pipefail

HUGO_VERSION=${HUGO_VERSION:-0.147.4}
BASEURL="https://keeplook4ever.github.io/"

echo "== Build with Hugo =="
echo "HUGO_ENV=production"
echo "Hugo version: ${HUGO_VERSION}"

# 可选：固定 hugo 可执行（如果你用 asdf 或本地二进制，可在此校验版本）
# hugo version

# 与 CI 完全一致的参数
hugo --minify --cleanDestinationDir --baseURL "${BASEURL}"

echo "== Guard: /about/index.html must exist =="
test -f public/about/index.html \
  || (echo "ERROR: public/about/index.html not found"; exit 1)

echo "Build OK."

