---
name: "Harness: Verify"
description: "Verificação cética independente (só a fase Verify do PEV), via subagente harness-verifier — ideal antes de um commit pontual"
category: Workflow
tags: [workflow, harness, pev, verify]
---

Rode **apenas a fase Verify** do PEV: uma conferência cética e independente do
estado atual do código, sem passar pelo ciclo completo. Use antes de um commit
pontual, ao revisar um trabalho já implementado, ou sempre que quiser uma
segunda opinião sobre se a change ativa fecha os critérios de aceitação.

**Input**: o argumento após `/harness:verify` é, opcionalmente, o nome de uma
change em `openspec/changes/` para focar a verificação. Se vier vazio, o
verificador usa a change ativa mais recente (ou nenhuma, se não houver).

Argumento recebido: `$ARGUMENTS`

---

## O que fazer

Delegue ao subagente **`harness-verifier`** (independente, só leitura). Se um
nome de change foi passado em `$ARGUMENTS`, instrua-o a focar nela exportando
`HARNESS_CHANGE=$ARGUMENTS` ao rodar o verificador independente.

O subagente vai:

1. rodar `bash .harness/verify.sh --all` (formatação, lint, testes, cobertura,
   build, verifiers de arquitetura);
2. rodar `bash .harness/verifiers/independent-verify.sh` para confirmar, item a
   item, cada `### Scenario:` da change contra os testes e o diff;
3. devolver um veredito priorizado: **BLOQUEIOS / AVISOS / cenários**.

## Tratamento do veredito

- `reprovado` → liste os BLOQUEIOS ao usuário e proponha a correção da **causa**
  (não maquie o relatório). Não prossiga para commit.
- `aprovado com ressalvas` → mostre os avisos e pergunte se o usuário aceita ou
  quer endereçá-los antes de commitar.
- `aprovado` → confirme que está liberado; se fizer sentido, sugira a mensagem
  de commit em Conventional Commits (scope válido em `.harness/rules/conventions.md`).

Importante: este comando **não** implementa nem corrige código — ele só
verifica e relata. Para o ciclo completo (planejar → implementar → verificar),
use `/harness:pev`.