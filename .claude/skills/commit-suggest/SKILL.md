---
name: commit-suggest
description: >
  Sugere uma mensagem em Conventional Commits derivando tipo e scope do diff
  staged + change ativa, sem o agente reler `.harness/rules/conventions.md`.
  Devolve só a mensagem pronta para `git commit -m`, com regra de fallback
  explícita quando o staged é ambíguo. Use antes de commitar, no fim da
  fase Verify do PEV.
metadata:
  type: context-saver
  version: "1.0"
---

Mensagem de commit pronta. Substitui o ritual de reler convenções +
inferir scope manualmente.

**Input**: argumento opcional após `/commit-suggest`:
- vazio                  → infere tipo+scope do staged diff e da change ativa.
- `<tipo>`               → fixa o tipo (`feat`, `fix`, `chore`, ...).
- `<tipo>(<scope>)`      → fixa tipo e scope; só o assunto é gerado.
- `breaking`             → como vazio, mas com `!` e nota `BREAKING CHANGE`.

Argumento recebido: `$ARGUMENTS`

---

## Tipos válidos (de `.harness/rules/conventions.md`)

`feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`,
`chore`, `revert`.

## Scopes válidos (lista canônica)

`core`, `loops`, `session`, `audio`, `import`, `persistence`, `separation`,
`tauri`, `ui`, `ipc`, `openspec`, `harness`, `deps`, `release`.

---

## Procedimento

1. **Leia o staged**:
   ```bash
   STAGED=$(git diff --cached --name-only)
   STATS=$(git diff --cached --shortstat)
   ```
   Se vazio → emita `NADA STAGED — use git add antes` e pare.

2. **Inferência de SCOPE** (em ordem; primeiro que casa vence):
   - Path bate em `crates/stem-core/src/audio/`           → `audio`
   - `crates/stem-core/src/loops`                         → `loops`
   - `crates/stem-core/src/session`                       → `session`
   - `crates/stem-core/src/import`                        → `import`
   - `crates/stem-core/src/persistence`                   → `persistence`
   - `crates/stem-core/src/separation`                    → `separation`
   - Outros sob `crates/stem-core/`                       → `core`
   - `src-tauri/`                                         → `tauri`
   - `src/` com `ipc` ou `bridge` no nome                 → `ipc`
   - Outros sob `src/`                                    → `ui`
   - `openspec/`                                          → `openspec`
   - `.harness/`, `.claude/`, `commitlint.config.js`,
     `clippy.toml`, `rustfmt.toml`                        → `harness`
   - `package.json`, `Cargo.toml` (deps), `package-lock.json` → `deps`
   - `CHANGELOG.md`, tags, release notes                  → `release`
   - **Múltiplas camadas tocadas** → escolha o **scope dominante**
     (mais arquivos). Em empate, `core` > `ui` > `tauri` > `openspec` >
     `harness`. Se ainda assim houver ambiguidade, **omita o scope**
     (o formato Conventional permite scope vazio).

3. **Inferência de TIPO**:
   - Só arquivos sob `*/tests/`, `tests.rs`, ou `#[test]`               → `test`
   - Só `**/*.md`, `docs/`, `README*`, `AGENTS.md`, `.harness/rules/*.md` → `docs`
   - Só formatação (`rustfmt.toml`, `.prettierrc`, mass-format diff)    → `style`
   - Só `package.json`/`Cargo.toml` com bump de versão de dep            → `chore` (ou `build`)
   - Path em `openspec/changes/` (não-arquivado) sem código              → `docs(openspec)` ou `chore(openspec)`
   - Diff contém **apenas** mudanças que mantêm comportamento
     (renomes, extração de função, sem novo teste)                       → `refactor`
   - Diff contém **novo `#[test]` + nova função pública**                → `feat`
   - Diff contém **só `#[test]` corrigindo regressão**                   → `test` ou `fix` (use change ativa para desempate)
   - Diff contém alteração comportamental sem novo teste                → **AVISO** ao agente: provável drift TDD; sugerir `feat`/`fix` mas pedir confirmação.
   - Default → `feat` (se a change ativa adiciona capability) ou `fix`
     (se a change ativa cita "bug" / "regression" no proposal).

4. **Assunto** (≤ 72 chars, minúsculas, imperativo, sem ponto):
   - Se há change ativa: derive do `proposal.md` (mesma frase do resumo do
     `/change-active`), reescrita no imperativo presente.
   - Senão: derive dos **novos símbolos** introduzidos no diff
     (`+fn `, `+pub`, `+impl`, `+struct`, `+component`). Use a primeira
     novidade como gancho.
   - Não cite o número/nome da change (vai no rodapé).

5. **Detecção de BREAKING**:
   - Argumento `breaking` OU diff contém remoção de função/método `pub` em
     `crates/stem-core/src/` OU mudança de assinatura `#[tauri::command]`
     → emita `tipo(scope)!:` + nota.

6. **Validação local**:
   - Reverifique: tipo ∈ lista; scope ∈ lista ou vazio; assunto ≤ 72.
   - Se quebrar, ajuste e marque os ajustes no PRÓXIMO PASSO.

## Formato de saída (obrigatório, fixo)

```
COMMIT SUGERIDO  (tipo=<t> scope=<s|−> breaking=<sim|não>)

<tipo>(<scope>): <assunto no imperativo, ≤72 chars>

<corpo opcional — 1-3 linhas explicando o porquê, se o diff > 3 arquivos
 ou se há nota BREAKING CHANGE; senão omita>

Refs: openspec/changes/<change-ativa>/          (se houver)
BREAKING CHANGE: <descrição>                    (só se !)

USE:
  git commit -m "<tipo>(<scope>): <assunto>"
```

Se houver **avisos** (drift TDD, scope ambíguo, sem change ativa para mudança
comportamental), liste-os antes do bloco:

```
AVISOS:
  - <aviso>
USE COM CUIDADO: <recomendação>
```

## Regras de ouro

- **Não** invoque `git commit` — emita só a mensagem. Quem decide commitar
  é o usuário (e os hooks vão revalidar).
- Tipo e scope **vêm das listas canônicas**; nunca invente.
- Assunto **sem ponto final**, em **minúsculas**, no **imperativo**
  ("add wrap-around handling"), não no infinitivo ("adicionar").
- Se a mudança envolve várias camadas, prefira **um único commit
  coerente** com scope dominante a sugerir split — só sugira split se
  combinou cargas claramente independentes (ex.: bump de dep + feature
  nova).
- O rodapé `Refs:` aponta o caminho da change ativa, **não** uma URL
  externa.

## Quando NÃO usar

- Quando o usuário quer dividir o commit em N → faça você o split (com
  `git restore --staged`) e chame esta skill para cada parte.
- Para mensagem de PR → não é o mesmo formato; use `gh pr create` com
  título derivado, mas a descrição é mais rica.
- Quando o staged está vazio → a skill aborta.
