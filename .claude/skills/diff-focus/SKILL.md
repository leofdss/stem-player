---
name: diff-focus
description: >
  `git diff` enxuto, agrupado por camada (core, tauri, ui, openspec, harness,
  outros) e ignorando ruído (`package-lock.json`, `Cargo.lock`, `dist/`,
  `target/`, `.angular/`, `node_modules/`). Por padrão devolve só estatísticas
  por camada; passando o nome de uma camada, devolve os hunks **só** dela.
  Use antes de `/code-review`, antes da fase Verify do PEV, ou sempre que o
  `git diff` cru fosse despejar milhares de linhas de lock/dist no contexto.
metadata:
  type: context-saver
  version: "1.0"
---

`git diff` recortado para o que importa no Stem Player.

**Input**: argumento opcional após `/diff-focus`:
- vazio                      → sumário por camada (sem hunks), base = `HEAD`.
- `<camada>`                 → hunks **só** da camada (`core`, `tauri`, `ui`,
                                `openspec`, `harness`, `other`), base = `HEAD`.
- `base=<ref>`               → muda a base (ex.: `base=origin/main`).
- `<camada> base=<ref>`      → combina.

Argumento recebido: `$ARGUMENTS`

---

## Mapeamento de camadas

| Camada    | Pathspec                              |
|-----------|---------------------------------------|
| `core`    | `crates/stem-core/`                   |
| `tauri`   | `src-tauri/`                          |
| `ui`      | `src/`                                |
| `openspec`| `openspec/`                           |
| `harness` | `.harness/` `.claude/`                |
| `other`   | tudo que não casou nas acima          |

## Ignore-list fixa (sempre, em todos os modos)

```
:(exclude)package-lock.json
:(exclude)Cargo.lock
:(exclude)dist/**
:(exclude)target/**
:(exclude).angular/**
:(exclude)node_modules/**
:(exclude)*.lock
```

## Procedimento

1. **Parse o input**: extraia `BASE` (default `HEAD`) e `LAYER` (default `_summary`).

2. **Monte o pathspec da ignore-list** (use `git -c core.quotepath=false`
   para nomes com unicode):
   ```bash
   IGNORE=( ':(exclude)package-lock.json' ':(exclude)Cargo.lock'
            ':(exclude)dist/**' ':(exclude)target/**'
            ':(exclude).angular/**' ':(exclude)node_modules/**'
            ':(exclude)*.lock' )
   ```

3. **Modo sumário** (`LAYER=_summary`):
   ```bash
   git diff --stat "$BASE" -- "${IGNORE[@]}" \
     | awk '
       /crates\/stem-core\//  { c["core"]++;     L["core"]+=$NF;     next }
       /src-tauri\//          { c["tauri"]++;    L["tauri"]+=$NF;    next }
       /^ src\//              { c["ui"]++;       L["ui"]+=$NF;       next }
       /openspec\//           { c["spec"]++;     L["spec"]+=$NF;     next }
       /\.harness\//          { c["harn"]++;     L["harn"]+=$NF;     next }
       /\.claude\//           { c["harn"]++;     L["harn"]+=$NF;     next }
       /\|/                   { c["other"]++;    L["other"]+=$NF }
     END { ... }'
   ```
   (Para os totais +X -Y, use `git diff --shortstat -- <pathspec>` por camada.)

4. **Modo por camada**:
   ```bash
   PATHS=$(layer_paths "$LAYER")    # ver tabela acima
   git diff "$BASE" -- $PATHS "${IGNORE[@]}"
   ```
   Limite a saída a um teto razoável; se o diff da camada passar de **400
   linhas**, mostre o `--stat` da camada e um aviso para o usuário pedir uma
   sub-pasta:
   ```bash
   git diff "$BASE" -- $SUBPATH "${IGNORE[@]}"
   ```

## Formato de saída (obrigatório, fixo)

**Modo sumário**:

```
DIFF FOCUS · base=<ref>  (ignorado: package-lock, Cargo.lock, dist, target, .angular, node_modules)

CAMADA       ARQUIVOS   ±LINHAS
core         <n>        +<a> -<r>
tauri        <n>        +<a> -<r>
ui           <n>        +<a> -<r>
openspec     <n>        +<a> -<r>
harness      <n>        +<a> -<r>
other        <n>        +<a> -<r>

TOTAL:       <N>        +<A> -<R>
APROFUNDE:   /diff-focus <camada> [base=<ref>]
```

**Modo por camada** (cabeçalho + hunks crus, mas só dela):

```
DIFF FOCUS · base=<ref>  layer=<camada>  (ignorado: ...)

<saída crua de `git diff` filtrada — sem hunks de outras camadas>
```

**Modo por camada quando passa do teto**:

```
DIFF FOCUS · base=<ref>  layer=<camada>  (TRUNCADO: >400 linhas)

<saída de `git diff --stat` para a camada>

APROFUNDE:   /diff-focus <camada>/<sub-pasta> [base=<ref>]
```

## Regras de ouro

- **Sempre** aplique a ignore-list, mesmo no modo por camada (o lock pode
  morar dentro de `src-tauri/`).
- **Nunca** rode `git diff` sem `-- <pathspec>` quando o modo é por camada
  — isso anularia o foco.
- **Não** copie a mensagem "X files changed, Y insertions(+), Z deletions(-)"
  bruta; reformate na tabela.
- Se o diff total estiver vazio, devolva uma linha só:
  `DIFF FOCUS · base=<ref> — sem mudanças.`
- A camada `other` é deliberada: sinaliza que algo escapa do mapeamento
  conhecido (ex.: `Makefile`, `eslint.config.js`). Se for alta, vale revisar.

## Quando NÃO usar

- Para revisão de correção (bugs lógicos) → `/code-review` recebe o diff
  filtrado desta skill como entrada.
- Para a auditoria cética de PEV → `harness-verifier` (subagente) já filtra.
- Para `git log`/blame → use `git` direto; esta skill é só sobre o diff atual.
