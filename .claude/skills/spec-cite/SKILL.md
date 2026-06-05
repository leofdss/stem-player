---
name: spec-cite
description: >
  Devolve apenas o bloco `### Scenario:` (ou um `## Requirement:` inteiro) que
  bate com a busca, em vez de carregar `openspec/specs/<cap>/spec.md` inteiro
  ou `openspec/changes/<id>/specs/<cap>/spec.md`. Use quando precisar relembrar
  o GIVEN/WHEN/THEN de um cenário específico, citar um requisito numa
  discussão, ou ao escrever o `#[test]` correspondente — sem inflar o contexto
  com requisitos não relacionados.
metadata:
  type: context-saver
  version: "1.0"
---

Citação cirúrgica de spec. Substitui ler o `spec.md` inteiro só para tirar
uma dúvida pontual.

**Input**: o argumento após `/spec-cite` é a **busca**, em uma destas formas:
- `<capability> <substring>`  → restringe à capability (diretório em
  `openspec/specs/<cap>/` ou em `openspec/changes/*/specs/<cap>/`).
- `<substring>`               → busca em **todas** as capabilities.
- `req:<substring>`           → casa contra `## Requirement:` em vez de
  `### Scenario:` (devolve o requisito + todos os scenarios dele).

Sem argumento → pergunte ao usuário qual scenario ele quer citar
(`AskUserQuestion` aberto).

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Defina o conjunto de specs** a olhar:
   ```bash
   SPECS=$( { ls openspec/specs/*/spec.md openspec/changes/*/specs/*/spec.md ; } 2>/dev/null )
   ```
   Se o argumento começa com um nome de capability conhecido, filtre o set.

2. **Decida o modo**:
   - Se a busca começa com `req:` → procure por `^## Requirement:.*<sub>`.
   - Senão → procure por `^### Scenario:.*<sub>` (case-insensitive).

3. **Extraia o bloco** (do cabeçalho até o próximo cabeçalho do mesmo nível
   ou superior, exclusivo):
   ```bash
   awk -v re="$REGEX" -v lvl="$LVL" '
     $0 ~ re                     { capt=1; print; next }
     capt && /^(##|###) /        {
       # próximo cabeçalho — para se for do mesmo nível ou mais alto
       hdr=$0; sub(/[^#].*/, "", hdr)
       if (length(hdr) <= length(lvl)) { capt=0 }
     }
     capt                        { print }
   ' "$SPEC_FILE"
   ```
   - Para `### Scenario:` → `LVL="###"` (para no próximo `###` ou `##`).
   - Para `## Requirement:` → `LVL="##"` (para no próximo `##`, captura os
     `###` filhos).

4. **Se houver múltiplas correspondências** (em arquivos diferentes ou no
   mesmo arquivo), liste-as como candidatas e peça ao usuário escolher.
   Não despeje todos os blocos de uma vez — isso anularia o objetivo.

## Formato de saída (obrigatório, fixo)

**Caso único — devolva apenas**:

```
<arquivo:linha>

### Scenario: <título>
- **GIVEN** ...
- **WHEN** ...
- **THEN** ...
```

(idem para `## Requirement:` quando o modo é `req:`; inclui seus `###
Scenario:` filhos).

**Múltiplos candidatos** — emita só a lista, sem o corpo:

```
CANDIDATOS (n):
  1. <arquivo:linha> — ### Scenario: <título>
  2. <arquivo:linha> — ### Scenario: <título>
  3. ...

REFAÇA COM: /spec-cite <capability> <substring mais específica>
```

**Zero matches**:

```
NÃO ENCONTRADO: "<busca>"
DICA: /scenario-map lista todos os scenarios da change ativa.
```

## Regras de ouro

- **Nunca** imprima o spec.md inteiro. Se o bloco passar de ~40 linhas,
  imprima só o cabeçalho + a primeira frase de cada `###` filho e ofereça
  uma sub-busca.
- **Não** invente texto: se o spec não tem GIVEN/WHEN/THEN explícito, copie
  o que estiver lá, sem completar.
- O caminho `arquivo:linha` no topo é obrigatório — é o ponteiro que evita
  o agente abrir o arquivo "para conferir".
- Match é **case-insensitive** e **substring** (não regex completa) para
  ser tolerante a como o usuário lembra o nome.
- Se um scenario aparece tanto em `openspec/changes/<id>/specs/.../spec.md`
  quanto em `openspec/specs/<cap>/spec.md` (já arquivada), prefira a da
  change ativa e mostre o conflito como aviso.

## Quando NÃO usar

- Para listar todos os scenarios da change → `/scenario-map`.
- Para conferir cobertura de testes → `/scenario-map` ou
  `/harness:verify`.
- Para escrever um scenario novo (planejamento) → delegue ao subagente
  `spec-author`.
