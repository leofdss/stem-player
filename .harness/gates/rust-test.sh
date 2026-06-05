#!/usr/bin/env bash
# Gate: testes Rust do workspace (alvo principal: stem-core).
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Rust · testes (cargo test)"
if ! have cargo; then hskip "cargo não encontrado — pulando"; exit 0; fi
if cargo test --workspace --all-features; then
  hpass "testes Rust passando"
else
  hfail "há testes Rust falhando"
  exit 1
fi
