---
name: scenario-map
description: >
  Mapeia cada `### Scenario:` da change OpenSpec ativa para o `#[test]`
  correspondente em `stem-core`, uma linha por cenário. Substitui a leitura
  manual de `specs/<cap>/spec.md` + cada arquivo de teste — o que o
  `harness-verifier` (e qualquer agente fazendo a fase Verify do PEV) faz hoje
  abrindo um por um. Use antes de commit, ao terminar a Execute do PEV, ou
  quando precisar saber "quais scenarios ainda não têm teste".
metadata:
  type: context-saver
  version: "1.0"
---

Mapa enxuto scenario → teste para a change ativa. Substitui o varrer manual
do `independent-verify.sh` + a leitura de cada `#[test]`.

**Input**: argumento opcional após `/scenario-map` é o nome da change a
inspecionar; vazio = change ativa mais recente em `openspec/changes/`
(mesmo descobridor usado por `.harness/verifiers/independent-verify.sh`).

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Descubra a change ativa** (mesma regra do harness):
   ```bash
   if [ -n "$ARGUMENTS" ] && [ -d "openspec/changes/$ARGUMENTS" ]; then
     CHANGE_DIR="openspec/changes/$ARGUMENTS"
   else
     CHANGE_DIR=$(find openspec/changes -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
                  | grep -v '/archive$' | sort | tail -1)
   fi
   ```
   Se vazio, emita `(nenhuma change ativa)` no formato fixo e pare.

2. **Liste os scenarios** de cada `specs/<cap>/spec.md` da change:
   ```bash
   grep -nH '^### Scenario:' "$CHANGE_DIR"/specs/*/spec.md 2>/dev/null
   ```
   Para cada linha, extraia: capability (do path), título (após `Scenario:`).

3. **Normalize o título para snake_case** (mesma convenção dos testes
   existentes em `crates/stem-core/src/loops.rs`):
   ```bash
   slug() {
     printf "%s" "$1" \
       | tr '[:upper:]' '[:lower:]' \
       | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g'
   }
   ```

4. **Localize o `#[test]` correspondente** em `crates/stem-core/src/`:
   ```bash
   grep -rn -E "fn ${SLUG}\b" crates/stem-core/src/ 2>/dev/null | head -n1
   ```
   - **Achou**: derive `<module>::tests::<fn>` do path
     (ex.: `crates/stem-core/src/loops.rs:142:    fn empty_region_...`
     → `loops::tests::empty_region_...`).
   - **Não achou**: marque como pendente.

5. **(Opcional)** Para scenarios sem match exato, tente um `grep` mais frouxo
   por palavras-chave do título para sinalizar "talvez aqui":
   ```bash
   grep -rn -E "fn .*${PIVOT_WORD}.*\(" crates/stem-core/src/ | head -n1
   ```
   Se achar, marque com `?` (candidato), não como coberto.

## Formato de saída (obrigatório, fixo)

Imprima **apenas** este bloco:

```
SCENARIO MAP · change=<nome>  capability=<cap | múltiplas>

[x] <título do scenario> → <module>::tests::<fn> (<arquivo:linha>)
[x] <título do scenario> → <module>::tests::<fn> (<arquivo:linha>)
[?] <título do scenario> → CANDIDATO: <module>::tests::<fn> (<arquivo:linha>)
[ ] <título do scenario> → SEM TESTE

COBERTURA: <n_cobertos>/<n_total>   PENDENTES: <n_pendentes>   CANDIDATOS: <n_cand>
PRÓXIMO PASSO: <uma linha — ex: "escrever #[test] fn <slug> em loops::tests"
                              | "todos cobertos — fase Verify pode rodar">
```

## Regras de ouro

- **Saída fixa**. Sem prosa antes ou depois.
- **Não** inclua o corpo dos scenarios (use `/spec-cite` para isso).
- **Não** inclua o código dos testes (o `arquivo:linha` é o ponteiro).
- Se houver scenarios duplicados entre capabilities, mostre o `cap/` no
  título: `<cap>/<scenario>`.
- `[?]` é deliberadamente um terceiro estado: o slug exato não casou, mas há
  algo parecido — o agente decide se é match ou se precisa escrever teste novo.
- **Não** rode `cargo test` aqui. Se o usuário quer rodar, é `/harness-digest`.

## Quando NÃO usar

- Quando o usuário quer ver o texto do scenario → `/spec-cite`.
- Quando quer só saber "estamos verdes?" → `/pev-status` ou `/harness-digest`.
- Para a auditoria oficial pré-commit → o subagente `harness-verifier` é
  cético e independente; esta skill é um atalho do agente principal.
