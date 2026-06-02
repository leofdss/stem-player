#!/usr/bin/env bash
# Gate: formatação do frontend (Prettier).
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Angular · formatação (Prettier)"
if ! npx_has prettier; then hskip "prettier não instalado — rode npm install"; exit 0; fi
if npx --no-install prettier --check "src/**/*.{ts,html,css,scss,json}"; then
  hpass "frontend formatado"
else
  hfail "frontend fora do padrão — rode: npm run format"
  exit 1
fi
