---
name: rule-lookup
description: >
  Índice das regras inegociáveis do Stem Player. Dado um termo (`unwrap`,
  `cpal`, `AudioContext`, `command Tauri`, `nova dependência`, `Cargo.lock`,
  `playlist`...), devolve UMA frase com a regra + escape (se houver) +
  arquivo:seção de origem. Use no lugar de reler `AGENTS.md`,
  `.harness/rules/*.md` ou `openspec/project.md` quando a dúvida é pontual
  ("posso usar X aqui?").
metadata:
  type: context-saver
  version: "1.0"
---

Mini-índice das regras do projeto. Substitui reler 300+ linhas de constituição
quando a pergunta é "posso/devo fazer X?".

**Input**: o argumento após `/rule-lookup` é a palavra-chave ou frase curta
em linguagem natural. Sem argumento → pergunte ("o que você quer conferir?").

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Normalize** a busca para minúsculas, sem acentos.
2. **Case** contra a tabela abaixo (palavras-chave em qualquer ordem). Se
   múltiplas regras casam, retorne as TOP 3, mais relevante primeiro.
3. **Se zero matches**: devolva a linha `NÃO ENCONTRADO` + 3 sugestões de
   palavras-chave conhecidas.

## Tabela de regras

> Sempre formato: **regra** (1 frase imperativa) → **escape/exceção** (se
> houver) → **origem** (arquivo:seção) → **verifier que reprova**.

### Pureza do `stem-core`

- **unwrap / expect / panic! / todo! / println! / dbg!**
  Proibidos em produção dentro de `crates/stem-core/src/**` (permitidos em
  `#[cfg(test)]`).
  Escape pontual: anote a linha com `// harness:allow`.
  Origem: `.harness/rules/rust.md#stem-core`, `AGENTS.md#restrições`.
  Verifier: `core-purity.sh` (FAIL).

- **erro / Result / thiserror**
  `stem-core` retorna `Result<_, Erro>`; um `enum` de erro por módulo
  (ex.: `LoopError`, `AudioError`) com `#[derive(thiserror::Error)]`.
  Origem: `openspec/project.md#convenções`, `.harness/rules/rust.md#geral`.

### Áudio isolado

- **cpal / symphonia**
  Só dentro de `crates/stem-core/src/audio/**`. Em qualquer outro lugar,
  reprovado pelo harness. `src-tauri` não declara crates de áudio.
  Saída real fica atrás do trait `AudioSink`; nos testes use o `fake`
  determinístico.
  Origem: `AGENTS.md#restrições`, `.harness/rules/rust.md#stem-core`.
  Verifier: `arch-boundaries.sh` (FAIL). Allowlist:
  `$HARNESS_CPAL_ALLOWLIST`.

- **AudioContext / Web Audio / decodeAudioData**
  Proibidos no Angular. Áudio é responsabilidade do Rust; UI só dispara
  intenções e desenha estado.
  Origem: `.harness/rules/angular.md`, `AGENTS.md#restrições`.
  Verifier: `angular-presentation.sh` (FAIL).

### Camada Tauri (`src-tauri`)

- **command Tauri longo / com lógica**
  Cada `#[tauri::command]` só valida/converte tipos e delega a `stem-core`.
  Sem laços, sem regra de negócio. Teto padrão: **15 linhas por command**
  (`$HARNESS_MAX_COMMAND_LINES`).
  Origem: `AGENTS.md#restrições`, `.harness/rules/rust.md#src-tauri`.
  Verifier: `tauri-thin.sh` (WARN, vira FAIL com `HARNESS_STRICT=1`).

- **dependência de áudio em `src-tauri`**
  Proibido. cpal/symphonia ficam em `stem-core::audio`. Aqui é casca.
  Origem: `.harness/rules/rust.md#src-tauri`.
  Verifier: `arch-boundaries.sh` (FAIL).

### Angular / Frontend

- **regra de negócio no front**
  Proibida. Cálculo de áudio, mixagem, regra de loop são do Rust. A UI
  desenha estado e dispara intenções.
  Origem: `.harness/rules/angular.md`, `openspec/project.md#regras-arquiteturais`.
  Verifier: `angular-presentation.sh`.

- **`invoke` solto / sem camada de IPC**
  Componentes não chamam `invoke` direto. Concentre na camada de IPC
  (arquivos `*ipc*` / `*bridge*`), com tipos espelhando os de `stem-core`.
  Origem: `.harness/rules/angular.md`.

- **acesso a filesystem no front**
  Proibido. Exponha um command no Rust e chame por IPC.
  Origem: `.harness/rules/angular.md`.

### OpenSpec / SDD

- **código sem proposta**
  Não escreva código antes de a change OpenSpec estar revisada
  (`propose → apply → archive`). O verifier `spec-drift.sh` reclama.
  Escape: mudanças exclusivamente de docs/harness/tests sem alteração de
  comportamento.
  Origem: `AGENTS.md#antes-de-escrever-código`, `openspec/project.md#fluxo`.

- **scenario sem teste**
  Cada `### Scenario:` deveria ter um `#[test]` em `stem-core`. O
  `harness-verifier` confirma 1:1 antes do commit final.
  Origem: `.claude/agents/spec-author.md#regras`.
  Verifier: `independent-verify.sh`.

### Commits & convenções

- **scope de commit**
  Conventional Commits. Tipos válidos: `feat`, `fix`, `refactor`, `perf`,
  `test`, `docs`, `style`, `build`, `ci`, `chore`, `revert`.
  Scopes válidos: `core`, `loops`, `session`, `audio`, `import`,
  `persistence`, `separation`, `tauri`, `ui`, `ipc`, `openspec`,
  `harness`, `deps`, `release`.
  Origem: `.harness/rules/conventions.md`.
  Verifier: `commit-lint.sh` (FAIL).

- **assunto do commit**
  ≤ 72 caracteres, em minúsculas, imperativo, sem ponto final.
  Quebras de API: `tipo(scope)!: ...` + nota `BREAKING CHANGE:`.
  Origem: `.harness/rules/conventions.md#conventional-commits`.

### Glossário de domínio

- **playlist** → use `projeto` (sessão).
- **snippet** / **clip** → use `loop`.
- **bookmark** → use `marcador`.
  Origem: `.harness/rules/glossary.txt`, `openspec/project.md#glossário`.
  Verifier: `glossary.sh` (WARN). Falso positivo: `// harness:allow`.

### "Pare e pergunte antes de"

- **nova dependência (Rust ou npm)** — pergunte ao usuário antes.
- **mudar a API pública de `stem-core`** — pergunte.
- **mudar assinatura de um `#[tauri::command]`** — pergunte.
- **mover lógica entre camadas** — pergunte.
  Origem: `AGENTS.md#pare-e-pergunte-antes-de`.

### "Faça sem perguntar"

- Refatorar dentro de uma função mantendo comportamento + testes verdes.
- Adicionar testes para código sem cobertura.
- Melhorar documentação e mensagens de erro.
  Origem: `AGENTS.md#faça-sem-perguntar`.

---

## Formato de saída (obrigatório, fixo)

**Caso único** (1-3 regras, mais relevante primeiro):

```
RULE LOOKUP · "<busca>"

1. <REGRA EM 1 FRASE>
   escape:   <texto | "nenhum">
   origem:   <arquivo:seção>
   verifier: <nome> (<FAIL|WARN>)

2. <REGRA EM 1 FRASE>
   ...
```

**Sem match**:

```
RULE LOOKUP · NÃO ENCONTRADO: "<busca>"
TENTE: unwrap, cpal, AudioContext, command tauri, scope commit,
        nova dependência, playlist, "pare e pergunte"
```

## Regras de ouro

- **Uma frase por regra**. Se a regra precisa de mais contexto, o agente
  abre o arquivo de origem (`arquivo:seção`).
- **Não invente** regras que não estão nos arquivos canônicos. Só sintetize.
- Se a busca casa com algo do glossário, dê **a tradução** + verifier.
- Não despeje a tabela inteira. Só os matches.

## Quando NÃO usar

- Para entender uma regra de fato (precedentes, exceções complexas) → leia
  o arquivo de origem.
- Para rever um trabalho concreto → `/harness:verify` ou `harness-digest`.
- Para escolher tipo/scope de commit → `/commit-suggest` (deriva tudo do
  diff).
