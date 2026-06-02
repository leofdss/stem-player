#!/usr/bin/env bash
# Gate: lint do frontend (ESLint + angular-eslint, inclui templates HTML).
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Angular · lint (ESLint + angular-eslint)"
if ! npx_has eslint; then hskip "eslint não instalado — rode npm install"; exit 0; fi
if npx --no-install eslint "src/**/*.{ts,html}"; then
  hpass "ESLint limpo"
else
  hfail "ESLint acusou problemas — rode: npm run lint:fix"
  exit 1
fi
