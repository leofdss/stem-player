#!/usr/bin/env bash
# Gate: validação estrutural das specs OpenSpec.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "OpenSpec · validação das specs"
if ! npx_has openspec; then hsoft "CLI do OpenSpec ausente — instale com: npm i -D openspec"; exit 0; fi
if npx --no-install openspec validate --all --strict 2>/dev/null \
   || npx --no-install openspec validate --all 2>/dev/null; then
  hpass "specs do OpenSpec válidas"
else
  hfail "OpenSpec acusou specs inválidas"
  exit 1
fi
