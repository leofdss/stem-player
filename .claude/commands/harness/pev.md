---
name: "Harness: PEV"
description: "Roda o ciclo Plan → Execute → Verify completo, delegando aos subagentes spec-author e harness-verifier"
category: Workflow
tags: [workflow, harness, pev, sdd, tdd]
---

Conduza uma feature pelo loop **PEV** (Plan → Execute → Verify) de ponta a ponta,
respeitando o SDD (OpenSpec) e o TDD do projeto. Você é o orquestrador: delega o
planejamento e a verificação a subagentes dedicados, e faz a implementação você
mesmo na etapa do meio.

**Input**: o argumento após `/harness:pev` é a descrição da feature/mudança, OU
o nome de uma change já existente em `openspec/changes/`. Se vier vazio, pergunte
ao usuário o que ele quer construir (AskUserQuestion, aberto) antes de começar.

Argumento recebido: `$ARGUMENTS`

---

## Pré-voo

1. Leia `openspec/project.md` e `AGENTS.md` para carregar contexto e as
   restrições inegociáveis. Toda a execução abaixo deve respeitá-las.
2. Anuncie ao usuário o plano de três fases e qual será a change alvo.

## Fase 1 — PLAN (delegar)

Delegue ao subagente **`spec-author`** para criar/atualizar a change do OpenSpec
a partir de `$ARGUMENTS`:

- Ele produz `proposal.md`, `tasks.md` e `specs/<capability>/spec.md` no formato
  `## Requirement:` + `### Scenario:` (GIVEN/WHEN/THEN).
- Ele **não** implementa código de produção.

**Portão de entrada para a Fase 2:** só prossiga depois que
`npx --no-install openspec validate --all --strict` passar **e** o usuário
aprovar a proposta. Apresente ao usuário o resumo do escopo e a lista de
cenários, e peça confirmação explícita ("a proposta está boa? sigo para
implementar?"). Se ele pedir ajustes, volte ao `spec-author`.

## Fase 2 — EXECUTE (você mesmo, em TDD)

Implemente a change, **você** (agente principal), seguindo TDD estrito:

1. Para **cada** `### Scenario:` da spec, escreva primeiro um `#[test]` em
   `stem-core` que falhe (Red).
2. Implemente o mínimo para passar (Green). Toda lógica de domínio mora em
   `stem-core`; `src-tauri` só ganha um command-casca delegando, se necessário;
   Angular só apresentação.
3. Refatore com os testes verdes (Refactor).
4. Marque as tasks em `tasks.md` conforme conclui (`- [x]`).
5. Rode o feedback rápido entre passos:
   ```bash
   bash .harness/verify.sh --quick
   ```

Pare e pergunte ao usuário antes de: adicionar dependência, mudar API pública de
`stem-core`/assinatura de command, ou mover lógica entre camadas.

## Fase 3 — VERIFY (delegar)

Delegue ao subagente **`harness-verifier`** (independente, só leitura) para a
conferência cética final. Ele vai:

- rodar `bash .harness/verify.sh --all`;
- rodar `bash .harness/verifiers/independent-verify.sh`;
- confirmar cada `### Scenario:` contra os testes e o diff;
- devolver um veredito priorizado (BLOQUEIOS / AVISOS / cenários).

**Tratamento do veredito:**
- `reprovado` → leve os BLOQUEIOS de volta à Fase 2, corrija e re-verifique.
  **Não** conserte você mesmo o relatório do verificador; corrija a causa.
- `aprovado com ressalvas` → mostre os avisos ao usuário e pergunte se aceita
  ou quer endereçar.
- `aprovado` → siga para o fechamento.

## Fechamento

1. Sugira a mensagem de commit em Conventional Commits, com *scope* válido
   (veja `.harness/rules/conventions.md`) e referência à change.
2. Lembre que os hooks (`pre-commit`/`commit-msg`/`pre-push`) vão revalidar.
3. Quando a change estiver implementada e verificada, lembre o usuário do passo
   de arquivamento do OpenSpec (`/opsx:archive` ou `openspec archive`), que move
   a spec de `changes/` para `specs/`.

Mantenha o usuário no comando dos portões entre fases — PEV é sobre verificação
em cada transição, não sobre correr até o fim sozinho.
