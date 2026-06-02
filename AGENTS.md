# AGENTS.md — Constituição do Stem Player

> Lido **antes de qualquer ação** por qualquer agente (ou pessoa) que vá tocar
> neste repositório. Não é README nem documentação de feature — é o conjunto de
> regras que o harness torna mecanicamente verificáveis. Cada linha aqui
> corresponde a uma decisão do projeto ou a um erro que não pode se repetir.

## Contexto em um parágrafo

Aplicativo desktop para tocar *stems* (faixas isoladas de uma música) com foco
em **loops de repetição por marcadores temporais**, para músicos iniciantes
praticarem trechos. **Tauri 2** é a casca, **Angular** desenha a tela, e **toda
a lógica** vive no crate Rust **`stem-core`**.

## Antes de escrever código

1. Leia `openspec/project.md` (contexto e convenções) e o glossário lá definido.
2. Toda mudança começa como **proposta OpenSpec**: `propose → apply → archive`.
   **Nada de código antes da proposta revisada.** (skills em `.claude/`.)
3. Cada task segue **TDD**: teste que falha → implementação mínima → refatoração.

## Loop PEV e subagentes (Claude Code)

O fluxo Plan → Execute → Verify tem dois subagentes dedicados em
`.claude/agents/`, que separam quem planeja/verifica de quem implementa:

- **Plan** → delegue ao subagente `spec-author` para redigir a change OpenSpec
  (proposal.md, tasks.md, specs com Requirement + Scenario) antes de codar.
- **Execute** → o agente principal implementa em `stem-core`, guiado pelos
  testes derivados de cada `### Scenario:`.
- **Verify** → delegue ao subagente `harness-verifier` (só leitura) para uma
  conferência cética e independente. Ele roda `verify.sh --all` e confirma cada
  cenário. É o mesmo papel automatizável via `HARNESS_VERIFIER_CMD` no
  `verifiers/independent-verify.sh`.

## Restrições inegociáveis (o harness reprova quem violar)

- **`stem-core` é puro e independente.** Não depende de Tauri, nem de UI.
  É 100% testável com `cargo test`. → `verifiers/arch-boundaries.sh`
- **`src-tauri` é casca fina.** Cada `#[tauri::command]` só chama `stem-core` e
  converte tipos. Sem regra de negócio, sem laços. → `verifiers/tauri-thin.sh`
- **Angular só desenha.** Nenhuma regra de negócio no frontend; comunicação só
  por *commands* (Angular→Rust) e *events* (Rust→Angular), concentrados numa
  camada de IPC. → `verifiers/angular-presentation.sh`
- **Saída de áudio real (cpal) isolada atrás de uma trait** (`AudioSink`), com
  *fake* nos testes. `cpal`/`symphonia` só no módulo `audio`. → `arch-boundaries.sh`
- **`stem-core` de produção não tem `unwrap`/`expect`/`panic!`/`println!`.**
  Tudo retorna `Result<_, _>` com `thiserror`. → `verifiers/core-purity.sh`
  (escape pontual: `// harness:allow`).

## Comandos que você deve rodar

```bash
npm run harness            # verificação com escopo automático (o que mudou)
npm run harness:all        # roda tudo
cargo fmt --all            # formatar Rust
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
npm run lint && npm run format:check
```

O harness completo: `bash .harness/verify.sh` (veja `.harness/README.md`).

## Convenções

- **Commits:** Conventional Commits. Tipos e *scopes* válidos em
  `.harness/rules/conventions.md`. O hook `commit-msg` valida.
- **Idioma:** código e identificadores em **inglês**; termos de domínio seguem
  o glossário (`.harness/rules/glossary.txt`). → `verifiers/glossary.sh`
- **Rust:** `cargo fmt` e `cargo clippy` sem warnings antes de cada commit;
  erros com `thiserror`, um tipo por módulo.
- **Angular:** TypeScript `strict` (já configurado); ESLint + Prettier.

## Pare e pergunte antes de

- Adicionar dependência nova (Rust ou npm).
- Mudar a API pública de `stem-core` ou a assinatura de um *command*.
- Tocar na fronteira entre camadas (mover lógica entre `stem-core`/`src-tauri`/UI).

## Faça sem perguntar

- Refatorar dentro de uma função mantendo o comportamento e os testes verdes.
- Adicionar testes para código existente sem cobertura.
- Melhorar documentação e mensagens de erro.

## O princípio do harness

> Cada vez que um agente erra, **engenheire uma correção permanente no
> ambiente** para que aquele erro não possa mais acontecer.

Na prática: ou vira uma **regra** aqui/neste diretório, ou — melhor — vira um
**check executável** em `.harness/`. Documentação sozinha não é harness.
