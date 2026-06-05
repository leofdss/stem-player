---
name: change-active
description: >
  Resumo de ~7 linhas da change OpenSpec ativa: nome, resumo de uma frase do
  `proposal.md`, capabilities tocadas, tasks done/total, contagem de
  scenarios e caminho. Use no início de uma sessão para o agente saber "em
  que change estamos" sem carregar `proposal.md` + `tasks.md` + `spec.md`
  inteiros. Mais focado que `/pev-status` (que combina change + harness +
  diff).
metadata:
  type: context-saver
  version: "1.0"
---

Identidade da change ativa, em um bloco. Quando o agente só precisa saber
"qual change?" e "qual o resumo?" — sem precisar de cobertura, harness ou
diff (para isso use `/pev-status`).

**Input**: argumento opcional após `/change-active` é o nome da change a
inspecionar (atalho útil para inspecionar changes não-ativas); vazio = a
mais recente em `openspec/changes/` (excluindo `archive/`).

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Descubra a change** (mesma regra do harness):
   ```bash
   if [ -n "$ARGUMENTS" ] && [ -d "openspec/changes/$ARGUMENTS" ]; then
     CHANGE_DIR="openspec/changes/$ARGUMENTS"
   else
     CHANGE_DIR=$(find openspec/changes -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
                  | grep -v '/archive$' | sort | tail -1)
   fi
   CHANGE=$(basename "$CHANGE_DIR" 2>/dev/null)
   ```
   Se vazio → emita `(nenhuma change ativa)` no formato fixo e pare.

2. **Resumo de uma frase** do `proposal.md`. Heurística:
   - Primeira linha após `## Motivação` / `## Why` / `## Proposta` /
     `## Resumo` que **não** seja outro cabeçalho nem linha em branco.
   - Trunque para 120 caracteres com `…` no fim se passar.
   - Se nada bater, use a primeira frase do arquivo (excluindo o `# Título`).

3. **Capabilities tocadas**: nomes dos diretórios em
   `openspec/changes/$CHANGE/specs/`. Junte com `, `.

4. **Tasks**:
   ```bash
   TOTAL=$(grep -cE '^\s*- \[[ x]\]' "$CHANGE_DIR/tasks.md" 2>/dev/null || echo 0)
   DONE=$(grep -cE  '^\s*- \[x\]'    "$CHANGE_DIR/tasks.md" 2>/dev/null || echo 0)
   ```

5. **Scenarios**:
   ```bash
   SC=$(grep -hE '^### Scenario:' "$CHANGE_DIR"/specs/*/spec.md 2>/dev/null | wc -l)
   ```

6. **Indicador de ativa vs arquivada**:
   - Se `CHANGE_DIR` está sob `openspec/changes/archive/` → marque `(arquivada)`.
   - Senão, se há `- [ ]` aberta → marque `(em progresso)`.
   - Se 100% das tasks marcadas → marque `(pronta para verificação)`.

## Formato de saída (obrigatório, fixo)

```
CHANGE ATIVA: <nome>  <estado>
RESUMO:       <uma frase de proposal.md>
CAPABILITIES: <cap1>, <cap2>
TASKS:        <DONE>/<TOTAL>
SCENARIOS:    <n>
CAMINHO:      openspec/changes/<nome>/

PRÓXIMO PASSO:
  <uma linha — derive do estado>
```

Mapeamento sugerido para "próximo passo" (escolha **uma**):
- `(nenhuma)`               → `proponha com /opsx:propose ou /openspec-propose`
- `(em progresso)`          → `continue a Execute: /scenario-map mostra o que falta`
- `(pronta para verificação)` → `rode /harness:verify ou /harness-digest`
- `(arquivada)`             → `crie uma change nova; esta já foi arquivada`

## Regras de ouro

- **Saída fixa**, sempre as mesmas 6 linhas + bloco PRÓXIMO PASSO.
- **Não** liste as tasks ou os scenarios um por um (use `/scenario-map` ou
  `/spec-cite`).
- **Não** repita conteúdo do `proposal.md` além da frase de resumo.
- Capabilities vêm do diretório, **não** invente — se a change não tem
  pasta `specs/`, escreva `(nenhuma)`.
- A frase de resumo é **truncada**: o ponteiro é o `CAMINHO`, é lá que o
  agente abre se precisar de mais.

## Quando NÃO usar

- Quando quer saber se está verde para commit → `/pev-status` ou
  `/harness-digest`.
- Quando quer mapear scenario→teste → `/scenario-map`.
- Quando quer escrever um `#[test]` para um scenario → `/tdd-skeleton`.
- Para listar **todas** as changes (ativas + arquivadas) → `ls
  openspec/changes/ openspec/changes/archive/` direto; esta skill foca em
  uma só.
