#!/usr/bin/env bash
# .harness/verifiers/spec-drift.sh
#
# Princípio SDD: nada de código sem proposta OpenSpec revisada.
# Se houve mudança de comportamento (crates/src/src-tauri) sem uma mudança
# correspondente em openspec/changes/, sinaliza drift de spec.
# Escapes: commits chore/docs/test/ci, token [no-spec] na mensagem, ou
# variável HARNESS_SKIP_SPEC_DRIFT=1.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "OpenSpec · detecção de drift (código sem spec)"

if [ "${HARNESS_SKIP_SPEC_DRIFT:-0}" = "1" ]; then hskip "ignorado por HARNESS_SKIP_SPEC_DRIFT"; exit 0; fi
last_msg="$(git log -1 --pretty=%s 2>/dev/null || true)"
case "$last_msg" in
  chore:*|docs:*|test:*|ci:*|build:*|style:*|*"[no-spec]"*)
    hskip "commit de manutenção — drift não se aplica"; exit 0;;
esac

code_changed=0; spec_touched=0
harness_touched '^(crates/|src-tauri/src/)' && code_changed=1
spec_changed && spec_touched=1

if [ "$code_changed" -eq 1 ] && [ "$spec_touched" -eq 0 ]; then
  hsoft "houve mudança de lógica sem mudança em openspec/changes/ — abra/atualize a proposta"
  hinfo "fluxo: opsx propose → apply → archive. Escape pontual: [no-spec] na mensagem do commit"
else
  hpass "mudanças de código acompanhadas de spec (ou não há mudança de lógica)"
fi
exit 0
