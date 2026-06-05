#!/usr/bin/env bash
# .harness/verify.sh — orquestrador do harness do Stem Player.
#
# Roda os gates de toolchain + os verifiers de arquitetura/convenção.
# Por padrão escala pelo que mudou (rust? angular? specs?), mas aceita
# rodar tudo. WARN não derruba (a menos de HARNESS_STRICT=1); FAIL derruba.
#
# Uso:
#   bash .harness/verify.sh            # escopo automático pelo diff
#   bash .harness/verify.sh --all      # roda tudo, sem filtrar por mudança
#   bash .harness/verify.sh --quick    # só os checks rápidos (sem build/cobertura)
#   HARNESS_STRICT=1 bash .harness/verify.sh   # WARN vira FAIL
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
cd "$HARNESS_ROOT"

MODE="auto"
for a in "$@"; do
  case "$a" in
    --all) MODE="all";;
    --quick) MODE="quick";;
    *) echo "opção desconhecida: $a"; exit 2;;
  esac
done

printf "${_C_BOLD}╔══════════════════════════════════════════════╗${_C_RESET}\n"
printf "${_C_BOLD}║   Stem Player · Harness · verificação (PEV)  ║${_C_RESET}\n"
printf "${_C_BOLD}╚══════════════════════════════════════════════╝${_C_RESET}\n"
hinfo "modo: $MODE · diff: $HARNESS_DIFF_MODE · estrito: $HARNESS_STRICT"

TOTAL_FAILS=0
TOTAL_WARNS=0

run() {  # run <script> [args...]
  local s="$1"; shift || true
  if [ ! -f "$s" ]; then printf "  ${_C_YELLOW}⚠ ausente: %s${_C_RESET}\n" "$s"; TOTAL_WARNS=$((TOTAL_WARNS+1)); return; fi
  # Executa o check, espelhando a saída e contabilizando ✗/⚠ a partir dela.
  local out; out="$(bash "$s" "$@" 2>&1 || true)"
  printf "%s\n" "$out"
  local f w
  f="$(printf "%s" "$out" | grep -c '✗' || true)"
  w="$(printf "%s" "$out" | grep -c '⚠' || true)"
  TOTAL_FAILS=$((TOTAL_FAILS + f))
  TOTAL_WARNS=$((TOTAL_WARNS + w))
}

want_rust=1; want_ng=1
if [ "$MODE" = "auto" ]; then
  rust_changed || want_rust=0
  angular_changed || want_ng=0
  # Se nada casou (ex.: primeira rodada), roda os dois.
  if [ "$want_rust" = 0 ] && [ "$want_ng" = 0 ]; then want_rust=1; want_ng=1; fi
fi

# ---- Convenções transversais (sempre) ----
run "$HERE/verifiers/glossary.sh"
run "$HERE/verifiers/spec-drift.sh"
run "$HERE/gates/openspec-validate.sh"
run "$HERE/verifiers/independent-verify.sh"

# ---- Trilha Rust ----
if [ "$want_rust" = 1 ]; then
  run "$HERE/verifiers/arch-boundaries.sh"
  run "$HERE/verifiers/core-purity.sh"
  run "$HERE/verifiers/tauri-thin.sh"
  run "$HERE/verifiers/tdd-companion.sh"
  run "$HERE/gates/rust-fmt.sh"
  run "$HERE/gates/rust-clippy.sh"
  run "$HERE/gates/rust-test.sh"
  if [ "$MODE" != "quick" ]; then run "$HERE/gates/rust-coverage.sh"; fi
fi

# ---- Trilha Angular ----
if [ "$want_ng" = 1 ]; then
  run "$HERE/verifiers/angular-presentation.sh"
  run "$HERE/gates/angular-format.sh"
  run "$HERE/gates/angular-lint.sh"
  if [ "$MODE" != "quick" ]; then run "$HERE/gates/angular-build.sh"; fi
fi

# ---- Veredito ----
# Em modo estrito, avisos contam como falhas.
if [ "$HARNESS_STRICT" = "1" ]; then
  TOTAL_FAILS=$((TOTAL_FAILS + TOTAL_WARNS))
  TOTAL_WARNS=0
fi
printf "\n${_C_BOLD}─── resultado ───────────────────────────────${_C_RESET}\n"
if [ "$TOTAL_FAILS" -gt 0 ]; then
  printf "${_C_RED}${_C_BOLD}✗ %d falha(s), %d aviso(s). Build reprovado.${_C_RESET}\n" "$TOTAL_FAILS" "$TOTAL_WARNS"
  exit 1
elif [ "$TOTAL_WARNS" -gt 0 ]; then
  printf "${_C_YELLOW}${_C_BOLD}⚠ 0 falhas, %d aviso(s). Aprovado com ressalvas.${_C_RESET}\n" "$TOTAL_WARNS"
  exit 0
else
  printf "${_C_GREEN}${_C_BOLD}✓ Tudo verde. Pronto para o PR.${_C_RESET}\n"
  exit 0
fi
