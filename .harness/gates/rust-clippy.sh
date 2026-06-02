#!/usr/bin/env bash
# Gate: lint Rust. Warnings são erros. As lints de robustez de stem-core
# (no_unwrap/no_panic/no_print) vivem no [lints] do Cargo.toml do crate.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Rust · lint (cargo clippy)"
if ! have cargo; then hskip "cargo não encontrado — pulando"; exit 0; fi
if cargo clippy --workspace --all-targets --all-features -- -D warnings; then
  hpass "clippy limpo (zero warnings)"
else
  hfail "clippy acusou problemas — corrija antes de seguir"
  exit 1
fi
