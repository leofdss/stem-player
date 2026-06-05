---
name: pev-status
description: >
  Snapshot de ~10 linhas do estado atual do loop PEV no Stem Player. Mostra a
  change ativa, % de tasks marcadas, contagem de scenarios cobertos x
  pendentes, último veredito do harness e diff resumido por crate/camada.
  Use no início de uma sessão para o agente "se localizar" sem reabrir
  proposal.md / tasks.md / spec.md / git diff inteiros. Cabe num único bloco
  no contexto.
metadata:
  type: context-saver
  version: "1.0"
---

Onde estamos no loop PEV — em um bloco. Substitui o ritual de abrir
`openspec/changes/<ativa>/proposal.md` + `tasks.md` + `specs/**/spec.md` +
rodar `git status` + `git diff` para o agente lembrar do contexto.

**Input**: opcional. Se vier um argumento após `/pev-status`, é o nome da
change a inspecionar; vazio = change ativa mais recente em
`openspec/changes/` (excluindo `archive/`).

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Identifique a change ativa**:
   ```bash
   if [ -n "$ARGUMENTS" ] && [ -d "openspec/changes/$ARGUMENTS" ]; then
     CHANGE="$ARGUMENTS"
   else
     CHANGE=$(ls -1dt openspec/changes/*/ 2>/dev/null \
              | grep -v '/archive/$' | head -n1 | xargs -I{} basename {})
   fi
   ```
   Se não houver, registre `(nenhuma)` e siga — ainda vale mostrar diff/harness.

2. **Conte tasks marcadas** em `openspec/changes/$CHANGE/tasks.md`:
   ```bash
   TOTAL=$(grep -cE '^\s*- \[[ x]\]' "openspec/changes/$CHANGE/tasks.md" 2>/dev/null || echo 0)
   DONE=$(grep -cE  '^\s*- \[x\]'    "openspec/changes/$CHANGE/tasks.md" 2>/dev/null || echo 0)
   ```

3. **Conte scenarios** na spec da change e quantos têm teste correspondente:
   ```bash
   SPECS=$(ls openspec/changes/$CHANGE/specs/*/spec.md 2>/dev/null)
   SC_TOTAL=$(grep -h '^### Scenario:' $SPECS 2>/dev/null | wc -l)
   ```
   Para o cobertos, faça o mapeamento canônico: cada scenario deve ter um
   `#[test]` em `crates/stem-core/src/**`. Heurística rápida:
   ```bash
   SC_COVERED=$(grep -rh '#\[test\]' crates/stem-core/src 2>/dev/null | wc -l)
   ```
   (Se quiser precisão, delegue para `bash .harness/verifiers/independent-verify.sh`
   e leia a saída — mas para o snapshot, a contagem direta basta.)

4. **Último veredito do harness**: se `.harness/.cache/last-run.log` existe
   (a `harness-digest` parqueia ali), extraia a última linha "resultado":
   ```bash
   tail -n 20 .harness/.cache/last-run.log 2>/dev/null \
     | grep -E 'falha|aviso|aprovado|reprovado' | tail -n 1
   ```
   Se não existe, mostre `não executado nesta sessão (rode /harness-digest)`.

5. **Diff resumido por camada**, sem despejar hunks:
   ```bash
   git diff --stat HEAD 2>/dev/null | awk '
     /crates\/stem-core/        { core+=1 }
     /src-tauri\//              { tauri+=1 }
     /^ src\//                  { ui+=1 }
     /openspec\//               { spec+=1 }
     /\.harness\//              { harn+=1 }
     END { printf("core:%d  tauri:%d  ui:%d  openspec:%d  harness:%d\n",
                  core+0, tauri+0, ui+0, spec+0, harn+0) }'
   ```

## Formato de saída (obrigatório, fixo)

Imprima **apenas** este bloco e nada mais:

```
PEV · stem-player

CHANGE ATIVA: <nome>            (ou: nenhuma)
TASKS:        <DONE>/<TOTAL>    (<pct>%)
SCENARIOS:    <SC_TOTAL> total · <SC_COVERED> com teste · <SC_TOTAL-SC_COVERED> pendentes
HARNESS:      <última linha de veredito | não executado nesta sessão>
DIFF (HEAD):  core:<n>  tauri:<n>  ui:<n>  openspec:<n>  harness:<n>

PRÓXIMO PASSO:
  <uma linha; ex: "escrever #[test] para `<scenario>` em loops::tests"
   | "rodar /harness-digest" | "marcar tasks restantes em tasks.md"
   | "abrir PR — tudo verde">
```

## Regras de ouro

- Saída **fixa**, sempre o mesmo formato — economiza tokens em sessões longas.
- **Não** liste cada scenario ou cada task um por um. Se o usuário pedir
  detalhe, ele chama a skill específica (`scenario-map`, `change-active`, etc.).
- **Não** inclua hunks de diff. O contador por camada já localiza o trabalho.
- **Não** rode o harness aqui — leia o último log se existir. Para rodar,
  delegue a `/harness-digest`.
- Próximo passo é **uma** linha imperativa e específica (cita arquivo ou
  comando), nunca genérica ("continue trabalhando").

## Quando NÃO usar

- Quando o usuário está abrindo a primeira change da sessão e quer revisar a
  proposta de fato → leia `proposal.md` direto.
- Para conferência cética antes de commit/push → delegue ao subagente
  `harness-verifier` (`/harness:verify`).
