#!/usr/bin/env bash
# .harness/verifiers/arch-boundaries.sh
#
# Transforma as "Regras arquiteturais (inegociáveis)" do openspec/project.md
# em checagens mecânicas:
#
#   1. stem-core não depende de Tauri (nem de nada de UI/IPC).
#   2. stem-core não depende de symphonia/cpal direto fora do módulo audio.
#   3. src-tauri não carrega crates de áudio (isso é papel do stem-core).
#   4. A saída real via cpal fica confinada à allowlist (isolada atrás da trait).
#   5. Consistência de edição do Rust no workspace.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "Arquitetura · fronteiras entre camadas"
rc=0

core_toml="crates/stem-core/Cargo.toml"
tauri_toml="src-tauri/Cargo.toml"

# 1. stem-core não pode depender de Tauri.
if [ -f "$core_toml" ]; then
  if grep -Eiq '^\s*tauri' "$core_toml"; then
    hfail "stem-core depende de Tauri em $core_toml — a lógica deve ser independente da casca"
    rc=1
  else
    hpass "stem-core não depende de Tauri"
  fi
  # 1b. Nenhum `use tauri` no código-fonte de stem-core.
  if grep -Rnq --include='*.rs' -E '^\s*use\s+tauri' crates/stem-core/src 2>/dev/null; then
    hfail "stem-core importa 'tauri' no código — remova o acoplamento com a casca"
    rc=1
  fi
fi

# 2. symphonia/cpal só podem aparecer no módulo audio de stem-core.
if [ -d crates/stem-core/src ]; then
  offenders="$(grep -Rln --include='*.rs' -E '\b(cpal|symphonia)\b' crates/stem-core/src 2>/dev/null \
                | grep -v '/audio' || true)"
  if [ -n "$offenders" ]; then
    hfail "áudio (cpal/symphonia) referenciado fora do módulo audio de stem-core:"
    echo "$offenders" | sed 's/^/      /'
    rc=1
  else
    hpass "áudio confinado ao módulo audio de stem-core"
  fi
fi

# 3. src-tauri não deve carregar crates de áudio (papel do stem-core).
if [ -f "$tauri_toml" ]; then
  if grep -Eiq '^\s*(cpal|symphonia|rodio|rubato)\b' "$tauri_toml"; then
    hfail "src-tauri declara dependência de áudio em $tauri_toml — mova para stem-core"
    rc=1
  else
    hpass "src-tauri sem dependências de áudio (casca fina)"
  fi
fi

# 4. cpal só é permitido nos arquivos da allowlist (saída real atrás da trait).
allow_regex="$(printf '%s' "$HARNESS_CPAL_ALLOWLIST" | sed 's/:/|/g')"
cpal_files="$(grep -Rln --include='*.rs' -E '\bcpal\b' crates src-tauri 2>/dev/null || true)"
if [ -n "$cpal_files" ]; then
  bad="$(printf '%s\n' "$cpal_files" | grep -Ev "^($allow_regex)$" || true)"
  if [ -n "$bad" ]; then
    hfail "uso de cpal fora da allowlist (saída real deve ficar isolada atrás de AudioSink):"
    echo "$bad" | sed 's/^/      /'
    hinfo "allowlist atual: $HARNESS_CPAL_ALLOWLIST"
    rc=1
  else
    hpass "cpal isolado na allowlist"
  fi
else
  hskip "cpal ainda não usado (ok nesta fase do projeto)"
fi

# 5. Consistência de edição do Rust entre os membros do workspace.
editions="$(grep -Rh --include='Cargo.toml' -E '^\s*edition\s*=' crates src-tauri 2>/dev/null \
            | sed -E 's/.*"([0-9]+)".*/\1/' | sort -u || true)"
n_editions="$(printf '%s\n' "$editions" | grep -c . || true)"
if [ "$n_editions" -gt 1 ]; then
  hsoft "edições Rust divergentes no workspace: $(echo $editions | tr '\n' ' ')— padronize"
else
  hpass "edição Rust consistente no workspace"
fi

[ "$rc" -eq 0 ] && hinfo "fronteiras arquiteturais respeitadas"
exit "$rc"
