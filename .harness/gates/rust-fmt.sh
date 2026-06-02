#!/usr/bin/env bash
# Gate: formatação Rust (cargo fmt --check) em todo o workspace.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Rust · formatação (cargo fmt)"
if ! have cargo; then hskip "cargo não encontrado — pulando"; exit 0; fi
if cargo fmt --all --check; then
  hpass "código Rust formatado"
else
  hfail "código Rust fora do padrão — rode: cargo fmt --all"
  exit 1
fi
