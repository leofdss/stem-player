#!/usr/bin/env bash
# .harness/verifiers/tdd-companion.sh
#
# Heurística de TDD: se houve mudança em código de produção de stem-core,
# espera-se que testes tenham mudado junto (RED → GREEN → REFACTOR).
# Aviso, não bloqueio — o gate duro de TDD é a cobertura (rust-coverage.sh).
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "TDD · código de stem-core acompanhado de teste"
if ! core_changed; then hskip "stem-core não mudou — nada a checar"; exit 0; fi

changed="$(harness_changed_files | grep -E '^crates/stem-core/.*\.rs$' || true)"
prod_changed=0; test_signal=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in */tests/*|*_test.rs|*tests.rs) test_signal=1;; *) prod_changed=1;; esac
done <<< "$changed"

# Mudança no diff que adiciona/altera um #[test] também conta como sinal.
if git diff -U0 $( [ "$HARNESS_DIFF_MODE" = staged ] && echo --cached ) -- 'crates/stem-core/**/*.rs' 2>/dev/null \
     | grep -qE '^\+.*#\[test\]'; then test_signal=1; fi

if [ "$prod_changed" -eq 1 ] && [ "$test_signal" -eq 0 ]; then
  hsoft "código de stem-core mudou sem mudança em testes — escreveu o teste antes?"
else
  hpass "mudança de stem-core acompanhada de teste"
fi
exit 0
