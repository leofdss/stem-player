#!/usr/bin/env bash
# .harness/verifiers/independent-verify.sh
#
# Fase VERIFY do loop PEV (Plan → Execute → Verify).
# Papel "cético": lê o diff + a change OpenSpec ativa + os testes e confere,
# item a item, se o trabalho fecha os critérios de aceitação — separando
# quem IMPLEMENTA (otimista) de quem VERIFICA (cético).
#
# Aqui ele roda como checklist mecânico + ganchos para um verificador agente.
# Cada cenário "### Scenario:" da spec da change vira um item a confirmar.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "PEV · verificação independente da change ativa"

# Descobre a change ativa: a mais recente em openspec/changes/ que NÃO está
# no archive (pode ser sobrescrita por HARNESS_CHANGE=<nome>).
change_dir=""
if [ -n "${HARNESS_CHANGE:-}" ]; then
  change_dir="openspec/changes/${HARNESS_CHANGE}"
else
  change_dir="$(find openspec/changes -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
                | grep -v '/archive$' | sort | tail -1 || true)"
fi

if [ -z "$change_dir" ] || [ ! -d "$change_dir" ]; then
  hskip "nenhuma change ativa em openspec/changes/ — verificação independente não se aplica"
  exit 0
fi
hinfo "change ativa: $change_dir"

rc=0

# 1. Artefatos mínimos da change presentes.
for art in proposal.md tasks.md; do
  if [ -f "$change_dir/$art" ]; then hpass "$art presente"; else hfail "$art ausente na change"; rc=1; fi
done

# 2. Todas as tasks marcadas como concluídas?
if [ -f "$change_dir/tasks.md" ]; then
  open_tasks="$(grep -cE '^\s*- \[ \]' "$change_dir/tasks.md" || true)"
  if [ "$open_tasks" -gt 0 ]; then
    hsoft "$open_tasks task(s) ainda abertas em tasks.md — execução incompleta"
  else
    hpass "todas as tasks marcadas como concluídas"
  fi
fi

# 3. Checklist de cenários da spec (cada Scenario precisa de confirmação).
spec_files="$(find "$change_dir/specs" -name 'spec.md' 2>/dev/null || true)"
if [ -n "$spec_files" ]; then
  total_scn=0
  while IFS= read -r sf; do
    [ -z "$sf" ] && continue
    while IFS= read -r scn; do
      total_scn=$((total_scn + 1))
      printf "      ${_C_DIM}[ ] confirmar: %s${_C_RESET}\n" "$scn"
    done < <(grep -E '^### Scenario:' "$sf" | sed 's/^### Scenario:[[:space:]]*//')
  done <<< "$spec_files"
  hinfo "$total_scn cenário(s) de aceitação a confirmar contra os testes e o diff"
  hinfo "dica: cada Scenario deveria ter um #[test] correspondente em stem-core"
else
  hskip "change sem specs/ — sem cenários a confirmar"
fi

# 4. Gancho opcional para um verificador-agente (LLM) externo.
#    Defina HARNESS_VERIFIER_CMD para automatizar a leitura cética do diff.
if [ -n "${HARNESS_VERIFIER_CMD:-}" ]; then
  hinfo "delegando ao verificador-agente: $HARNESS_VERIFIER_CMD"
  if eval "$HARNESS_VERIFIER_CMD"; then hpass "verificador-agente aprovou"; else hfail "verificador-agente reprovou"; rc=1; fi
fi

exit "$rc"
