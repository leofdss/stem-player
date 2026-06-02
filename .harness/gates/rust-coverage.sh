#!/usr/bin/env bash
# Gate de TDD: cobertura de linhas em stem-core >= HARNESS_MIN_COVERAGE.
# Usa cargo-llvm-cov. Se não estiver instalado, vira aviso (não bloqueia local).
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Rust · cobertura de stem-core (>= ${HARNESS_MIN_COVERAGE}%)"
if ! have cargo; then hskip "cargo não encontrado — pulando"; exit 0; fi
if ! cargo llvm-cov --help >/dev/null 2>&1; then
  hsoft "cargo-llvm-cov ausente — instale com: cargo install cargo-llvm-cov"
  exit 0
fi
if cargo llvm-cov --package stem-core --fail-under-lines "${HARNESS_MIN_COVERAGE}" --summary-only; then
  hpass "cobertura de stem-core dentro do mínimo"
else
  hfail "cobertura de stem-core abaixo de ${HARNESS_MIN_COVERAGE}% — adicione testes"
  exit 1
fi
