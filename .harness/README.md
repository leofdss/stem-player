# Harness do Stem Player

Este diretório é o **harness** do projeto: o conjunto de mecanismos executáveis
que mantém o código confiável quando humanos *e* agentes de IA dirigem. Ele
implementa o loop **PEV (Plan → Execute → Verify)** integrado a **SDD**
(OpenSpec) e **TDD**, e traduz cada regra inegociável de `openspec/project.md`
em uma checagem que falha sozinha quando violada.

```
Spec (OpenSpec)  ──►  PLAN  ──►  EXECUTE (TDD: RED→GREEN→REFACTOR)  ──►  VERIFY
   intenção            gate 1          gate 2 (fmt/lint/test/arch)        gate 3
                                                                    (verificação
                                                                     independente)
```

## Como funciona

- **Gates de toolchain** (`gates/`) — formatação, lint, testes, cobertura,
  Conventional Commits e validação OpenSpec. Falham o build.
- **Verifiers de projeto** (`verifiers/`) — as regras arquiteturais e de
  convenção do Stem Player viradas em código.
- **Orquestrador** (`verify.sh`) — roda o conjunto, escalando pelo que mudou,
  e dá o veredito. WARN não derruba; FAIL derruba. `HARNESS_STRICT=1` faz WARN
  virar FAIL (usado no CI).
- **Hooks** (`hooks/`) — `pre-commit` (rápido), `commit-msg` (conventional),
  `pre-push` (completo), ativados por um único `core.hooksPath`.
- **Regras** (`rules/`) — a constituição por área, mais o glossário como dado.

## Instalação

```bash
bash .harness/install.sh      # aponta hooks, instala devDeps, dá as dicas
```

## Catálogo de checagens

| Check | Arquivo | Tipo | O que garante |
|---|---|---|---|
| Formatação Rust | `gates/rust-fmt.sh` | FAIL | `cargo fmt --check` |
| Lint Rust | `gates/rust-clippy.sh` | FAIL | clippy sem warnings |
| Testes Rust | `gates/rust-test.sh` | FAIL | `cargo test` verde |
| Cobertura | `gates/rust-coverage.sh` | FAIL | `stem-core` ≥ 80% linhas |
| Formatação UI | `gates/angular-format.sh` | FAIL | Prettier |
| Lint UI | `gates/angular-lint.sh` | FAIL | ESLint + angular-eslint |
| Type-check UI | `gates/angular-build.sh` | FAIL | `ng build` compila |
| Commits | `gates/commit-lint.sh` | FAIL | Conventional Commits |
| Specs | `gates/openspec-validate.sh` | FAIL | `openspec validate` |
| Fronteiras | `verifiers/arch-boundaries.sh` | FAIL | camadas e isolamento do áudio |
| Pureza do core | `verifiers/core-purity.sh` | FAIL | sem unwrap/panic/print |
| Casca fina | `verifiers/tauri-thin.sh` | WARN | commands enxutos |
| UI só apresenta | `verifiers/angular-presentation.sh` | FAIL/WARN | sem lógica no front |
| Glossário | `verifiers/glossary.sh` | WARN | vocabulário de domínio |
| Drift de spec | `verifiers/spec-drift.sh` | WARN | código sem proposta |
| Companheiro TDD | `verifiers/tdd-companion.sh` | WARN | teste junto do código |
| Verificação PEV | `verifiers/independent-verify.sh` | FAIL/WARN | critérios de aceitação |

## Variáveis de ambiente

| Variável | Padrão | Efeito |
|---|---|---|
| `HARNESS_STRICT` | `0` | `1` faz todo WARN virar FAIL |
| `HARNESS_DIFF_MODE` | `range` | `staged` para olhar só o index |
| `HARNESS_BASE` | auto | ref base do diff (ex.: `origin/main`) |
| `HARNESS_MIN_COVERAGE` | `80` | piso de cobertura de `stem-core` |
| `HARNESS_MAX_COMMAND_LINES` | `15` | teto de linhas por command Tauri |
| `HARNESS_CPAL_ALLOWLIST` | ver `lib.sh` | onde `cpal` é permitido |
| `HARNESS_SKIP_SPEC_DRIFT` | `0` | `1` desliga o check de drift |
| `HARNESS_CHANGE` | auto | força a change a verificar no PEV |
| `HARNESS_VERIFIER_CMD` | — | comando do verificador-agente (LLM) |

## O princípio

Quando um agente (ou pessoa) erra de um jeito que o harness não pega: adicione
o check aqui. Cada novo verifier é uma classe de erro que deixa de existir.
