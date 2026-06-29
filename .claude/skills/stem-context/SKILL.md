---
name: stem-context
description: >
  Pré-voo enxuto do Stem Player. Devolve só as 8-15 linhas das regras
  inegociáveis para a camada alvo (core, tauri, ui, audio, openspec, harness) +
  glossário restrito. Use ANTES de abrir AGENTS.md / openspec/project.md /
  .harness/rules/*.md inteiros, quando o agente precisa só "lembrar o que pode e
  o que não pode" naquela camada. Cabe em ~20 linhas no contexto.
metadata:
  type: context-saver
  version: "1.0"
---

Pré-voo focado por camada. Substitui a leitura de `AGENTS.md` +
`openspec/project.md` + `.harness/rules/*.md` por um resumo restrito ao escopo
do trabalho atual.

**Input**: o argumento depois de `/stem-context` é o **nome da camada**:
`core`, `tauri`, `ui`, `audio`, `openspec`, `harness`. Se vier vazio, pergunte
ao usuário em qual camada ele vai mexer (`AskUserQuestion` com essas opções).

Argumento recebido: `$ARGUMENTS`

---

## Como responder

Imprima **apenas** o bloco da camada pedida, no formato abaixo, sem nada além.
Não cole o conteúdo de `AGENTS.md` nem de `project.md` — sintetize. Se a camada
não estiver na lista, peça para o usuário escolher uma válida.

### `core` — crate `stem-core`

```
ONDE: crates/stem-core/src/
REGRAS:
  - Independência total: sem tauri, sem UI. Só std + crates de domínio
    (thiserror; cpal/symphonia só em audio).
  - Sem unwrap/expect/panic!/todo!/println!/dbg! em produção
    (escape pontual: // harness:allow).
  - Erros com thiserror, um enum por módulo (LoopError, AudioError, ...).
  - Áudio real isolado atrás do trait AudioSink; fake nos testes.
MÓDULOS: session, loops, audio, import, persistence, separation.
TERMOS: stem, projeto/sessão, marcador, loop, mixer, mute, solo, transporte.
BANIDOS → preferidos: playlist→projeto, snippet/clip→loop, bookmark→marcador.
VERIFIERS QUE PEGAM: core-purity.sh, arch-boundaries.sh, glossary.sh.
```

### `tauri` — casca `src-tauri`

```
ONDE: src-tauri/src/
REGRAS:
  - Casca fina: cada #[tauri::command] só valida/converte tipos e delega a stem-core.
  - Sem regra de domínio, sem laços. Teto padrão: 15 linhas por command.
  - NÃO declare crates de áudio aqui (cpal/symphonia ficam em stem-core::audio).
COMUNICAÇÃO: commands (Angular→Rust) e events (Rust→Angular).
VERIFIERS QUE PEGAM: tauri-thin.sh (WARN), arch-boundaries.sh.
```

### `ui` — frontend Angular

```
ONDE: src/
REGRAS:
  - Só apresentação. Zero regra de negócio no front (cálculo de áudio,
    mixagem, regra de loop são do Rust).
  - Comunicação só por IPC: invoke (command) e listen (event), concentrados
    numa camada *ipc*/*bridge*. Componentes pedem ao serviço, não chamam invoke.
  - Sem AudioContext / decodeAudioData / Web Audio.
  - Sem acesso a filesystem (use um command no Rust).
  - TypeScript strict (sem any), standalone + OnPush quando possível.
ESTILO: ESLint (angular-eslint) + Prettier. `npm run lint && npm run format`.
VERIFIERS QUE PEGAM: angular-presentation.sh.
```

### `audio` — módulo `stem-core::audio`

```
ONDE: crates/stem-core/src/audio/
REGRAS (em cima das de `core`):
  - cpal e symphonia SÓ aqui (allowlist em HARNESS_CPAL_ALLOWLIST).
  - Saída real atrás do trait AudioSink; nos testes usa o fake determinístico.
  - Nada de I/O bloqueante na rota de áudio sem documentar.
VERIFIERS QUE PEGAM: arch-boundaries.sh, core-purity.sh.
```

### `openspec` — specs e changes

```
ONDE: openspec/changes/<nome>/, openspec/specs/<cap>/.
REGRAS:
  - Nada de código antes de uma change revisada (propose → apply → archive).
  - Cada change tem: proposal.md, tasks.md, specs/<cap>/spec.md.
  - Specs no formato: ## Requirement (MUST) + ### Scenario (GIVEN/WHEN/THEN).
  - Todo requisito tem 1 cenário feliz + 1 de erro/limite.
  - Cada ### Scenario vira um #[test] em stem-core (TDD).
  - Prosa em PT-BR; identificadores em inglês.
COMANDO: npx --no-install openspec validate --all --strict.
SUBAGENTE: spec-author (escreve), harness-verifier (confere).
```

### `harness` — verificação

```
ONDE: .harness/{gates,verifiers,rules,hooks}/.
REGRAS:
  - Quando um erro escapa, vira REGRA aqui ou (melhor) CHECK executável.
  - Documentação sozinha não é harness.
  - WARN não derruba; FAIL derruba. HARNESS_STRICT=1 faz WARN virar FAIL (CI).
COMANDOS:
  - bash .harness/verify.sh           (escopo automático pelo diff)
  - bash .harness/verify.sh --all     (tudo)
  - bash .harness/verify.sh --quick   (sem build/cobertura)
COMMITS: Conventional Commits, scopes em .harness/rules/conventions.md.
SCOPES VÁLIDOS: core, loops, session, audio, import, persistence, separation,
                tauri, ui, ipc, openspec, harness, deps, release.
```

---

## Convenção de saída

- Imprima **apenas** o bloco da camada pedida.
- Termine com **uma** linha: `→ Aprofunde em: <arquivo:seção>` apontando para
  onde o agente lê se precisar (`AGENTS.md`, `.harness/rules/<file>.md`,
  `openspec/project.md#glossário-de-domínio`, etc.).
- Não repita o conteúdo de `AGENTS.md` integralmente. O objetivo é
  **economizar contexto**, não duplicá-lo.

## Quando NÃO usar

- Quando o usuário quer auditar uma regra específica → mande ele ler o arquivo.
- Quando a tarefa cruza várias camadas profundamente → invoque uma camada de
  cada vez, em chamadas separadas, ainda economiza contra ler tudo.
