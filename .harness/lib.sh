#!/usr/bin/env bash
# .harness/lib.sh
# Biblioteca compartilhada do harness do Stem Player.
# Centraliza configuração, detecção de mudanças e helpers de log.
# Todos os gates e verifiers fazem `source` deste arquivo.

# --------------------------------------------------------------------------- #
# Configuração (sobrescrevível por variáveis de ambiente)
# --------------------------------------------------------------------------- #

# Raiz do repositório (resolvida a partir do git).
HARNESS_ROOT="${HARNESS_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export HARNESS_ROOT

# Cobertura mínima de linhas exigida em `stem-core` (gate de TDD).
HARNESS_MIN_COVERAGE="${HARNESS_MIN_COVERAGE:-80}"

# Tamanho máximo (em linhas) do corpo de um `#[tauri::command]`
# antes de o verifier "tauri-thin" reclamar de lógica vazando para a casca.
HARNESS_MAX_COMMAND_LINES="${HARNESS_MAX_COMMAND_LINES:-15}"

# Caminhos onde o uso de `cpal` (saída de áudio real) é permitido.
# A regra arquitetural manda isolar a saída real atrás de uma trait.
# Qualquer `cpal` fora desta lista é uma violação.
HARNESS_CPAL_ALLOWLIST="${HARNESS_CPAL_ALLOWLIST:-crates/stem-core/src/audio/sink_cpal.rs:src-tauri/src/audio.rs}"

# Em modo estrito, WARN também derruba o build (usado no CI por opção).
HARNESS_STRICT="${HARNESS_STRICT:-0}"

# Base de comparação para detectar o que mudou.
# - range  : diff entre HARNESS_BASE..HEAD (CI / pre-push)
# - staged : apenas o que está no index (pre-commit)
HARNESS_DIFF_MODE="${HARNESS_DIFF_MODE:-range}"
HARNESS_BASE="${HARNESS_BASE:-}"

# --------------------------------------------------------------------------- #
# Log com cores
# --------------------------------------------------------------------------- #

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  _C_RESET='\033[0m'; _C_BOLD='\033[1m'; _C_DIM='\033[2m'
  _C_RED='\033[31m'; _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'
  _C_BLUE='\033[34m'; _C_CYAN='\033[36m'
else
  _C_RESET=''; _C_BOLD=''; _C_DIM=''
  _C_RED=''; _C_GREEN=''; _C_YELLOW=''; _C_BLUE=''; _C_CYAN=''
fi

# Contadores globais (usados pelo orquestrador).
HARNESS_FAILS=0
HARNESS_WARNS=0

hgroup() { printf "\n${_C_BOLD}${_C_CYAN}▶ %s${_C_RESET}\n" "$*"; }
hinfo()  { printf "  ${_C_DIM}%s${_C_RESET}\n" "$*"; }
hpass()  { printf "  ${_C_GREEN}✓ %s${_C_RESET}\n" "$*"; }
hwarn()  { printf "  ${_C_YELLOW}⚠ %s${_C_RESET}\n" "$*"; HARNESS_WARNS=$((HARNESS_WARNS + 1)); }
hfail()  { printf "  ${_C_RED}✗ %s${_C_RESET}\n" "$*"; HARNESS_FAILS=$((HARNESS_FAILS + 1)); }
hskip()  { printf "  ${_C_DIM}∅ %s${_C_RESET}\n" "$*"; }

# Resolve um WARN: vira FAIL em modo estrito.
hsoft() {
  if [ "$HARNESS_STRICT" = "1" ]; then hfail "$*"; else hwarn "$*"; fi
}

# --------------------------------------------------------------------------- #
# Detecção de mudanças
# --------------------------------------------------------------------------- #

# Descobre a base de diff quando não informada.
_harness_resolve_base() {
  if [ -n "$HARNESS_BASE" ]; then echo "$HARNESS_BASE"; return; fi
  # Tenta o upstream da branch; cai para origin/main; cai para HEAD~1.
  if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
    git rev-parse --abbrev-ref '@{upstream}'
  elif git rev-parse --verify origin/main >/dev/null 2>&1; then
    echo "origin/main"
  elif git rev-parse --verify main >/dev/null 2>&1; then
    echo "main"
  else
    echo "HEAD~1"
  fi
}

# Lista os arquivos alterados conforme o modo de diff.
harness_changed_files() {
  if [ "$HARNESS_DIFF_MODE" = "staged" ]; then
    git diff --cached --name-only --diff-filter=ACMR
  else
    local base; base="$(_harness_resolve_base)"
    git diff --name-only --diff-filter=ACMR "${base}...HEAD" 2>/dev/null \
      || git diff --name-only --diff-filter=ACMR "${base}" 2>/dev/null \
      || git diff --name-only --diff-filter=ACMR HEAD~1 2>/dev/null \
      || true
  fi
}

# Verdadeiro se houver mudança casando com o regex passado.
harness_touched() {
  harness_changed_files | grep -Eq "$1"
}

rust_changed()    { harness_touched '^(crates/|src-tauri/|Cargo\.(toml|lock))'; }
angular_changed() { harness_touched '^(src/|angular\.json|tsconfig.*\.json|package(-lock)?\.json|eslint\.config\.js|\.prettierrc)'; }
core_changed()    { harness_touched '^crates/stem-core/'; }
spec_changed()    { harness_touched '^openspec/changes/'; }

# --------------------------------------------------------------------------- #
# Utilidades
# --------------------------------------------------------------------------- #

have() { command -v "$1" >/dev/null 2>&1; }

# Verdadeiro se o binário npm <1> estiver instalado e executável via npx.
# Distingue "ferramenta ausente" de "ferramenta rodou e reprovou".
npx_has() {
  have npx || return 1
  npx --no-install "$1" --version >/dev/null 2>&1
}

# Roda um comando mostrando-o em modo dim; devolve o código de saída.
hrun() {
  hinfo "\$ $*"
  "$@"
}
