---
name: tdd-skeleton
description: >
  Gera um `#[test]` em RED, no padrão do `stem-core`, a partir de um
  `### Scenario:` da change ativa. Emite só o snippet de código pronto para
  colar (Edit), sem o agente carregar `spec.md` inteiro nem reabrir cada
  arquivo de teste para imitar o estilo. Use no início da fase Execute do
  PEV, ao começar um cenário novo.
metadata:
  type: context-saver
  version: "1.0"
---

Esqueleto de `#[test]` derivado de um scenario OpenSpec. Substitui o ritual
de ler o spec.md + abrir o arquivo de testes para copiar o padrão do projeto.

**Input**: o argumento após `/tdd-skeleton` é a busca do scenario, na mesma
forma de `/spec-cite`:
- `<capability> <substring>`  → restringe à capability.
- `<substring>`               → busca em **todas** as capabilities da change ativa.

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Localize o scenario** (delegue a lógica para `/spec-cite` ou refaça):
   - Encontre o `### Scenario:` que casa com a busca em
     `openspec/changes/<ativa>/specs/<cap>/spec.md`.
   - Extraia GIVEN/WHEN/THEN para usar como comentário do teste.
   - Se múltiplos casam → pare e peça uma busca mais específica.

2. **Derive o módulo de destino** a partir da `<capability>`:
   - `loop-markers`, `loops` → `crates/stem-core/src/loops.rs`
   - `session`             → `crates/stem-core/src/session.rs`
   - `audio`               → `crates/stem-core/src/audio/...`
   - `import`              → `crates/stem-core/src/import.rs`
   - `persistence`         → `crates/stem-core/src/persistence.rs`
   - desconhecida          → reporte e peça confirmação.

3. **Derive o nome da função** (snake_case do título do scenario):
   ```bash
   slug() { printf "%s" "$1" | tr '[:upper:]' '[:lower:]' \
            | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g'; }
   ```
   Se o nome já existe no arquivo destino (grep), avise — não sobrescreva.

4. **Reaproveite as conveniências locais** (sem ter que ler o arquivo todo,
   confie no padrão estabelecido):
   - `mod tests { use super::*; ... }` é o módulo.
   - Há um helper `engine(track_len)` em `loops.rs`. Para outros módulos,
     deixe um TODO explícito em vez de inventar helper.
   - Erros vêm de `<Modulo>Error` (ex.: `LoopError::OutOfBounds`,
     `LoopError::EmptyRegion`). Se o THEN cita "erro X", use a variante.

5. **Mapeie GIVEN/WHEN/THEN para asserts**:
   - **THEN** "retorna `<Variante>`" → `assert_eq!(err, <Tipo>::<Variante>);`
   - **THEN** "operação é rejeitada" → `assert!(result.is_err());`
   - **THEN** "<estado>" → `assert_eq!(...) // TODO derivar de THEN: "<texto>"`.
   - Sem inventar invariantes que o scenario não cita.

## Formato de saída (obrigatório, fixo)

```
TDD SKELETON · capability=<cap>  destino=<arquivo>  fn=<nome>

# Cole o snippet abaixo dentro de `mod tests { ... }` em <arquivo>.
# O teste DEVE FALHAR primeiro (Red). Implemente o mínimo em <arquivo> para
# passar (Green) — depois refatore.

```rust
#[test]
fn <nome_snake>() {
    // Scenario: <título original do scenario>
    // GIVEN <texto do GIVEN>
    // WHEN  <texto do WHEN>
    // THEN  <texto do THEN>

    let mut e = engine(<track_len ou TODO>);     // se o módulo for `loops`

    // TODO Arrange (GIVEN): <ações iniciais derivadas do GIVEN>

    // Act (WHEN):
    let result = /* TODO: chamada que o scenario descreve */;

    // Assert (THEN):
    // <um assert por afirmação do THEN — sem inventar invariantes a mais>
    assert!(/* TODO derivar do THEN */);
}
```

PRÓXIMO PASSO:
  1. Aplique com Edit em <arquivo>.
  2. `cargo test -p stem-core <nome_snake>`  →  deve FALHAR (Red).
  3. Implemente o mínimo na API para o teste passar (Green).
  4. /scenario-map para confirmar a cobertura.
```

## Regras de ouro

- **Não** escreva o arquivo — emita o snippet. Quem aplica é o agente
  principal (com Edit), porque ele tem o contexto da posição correta no
  módulo (entre quais outros testes, em qual sub-seção `// ── 3. Região ─`).
- **Não invente asserts** além do que o THEN diz. Prefira deixar `TODO` a
  cravar invariantes erradas.
- **Preserve a língua dos comentários**: GIVEN/WHEN/THEN vêm da spec
  (português); identificadores Rust em inglês.
- Se o scenario é só de **erro**, devolva esqueleto curto:
  `let err = ... .unwrap_err(); assert_eq!(err, <Variante>);`.
- Se a `<capability>` não tem módulo correspondente ainda, reporte e
  sugira ao agente criar o módulo + atualizar `lib.rs` antes do teste.

## Quando NÃO usar

- Para um teste que não tem scenario na spec → escreva o `#[test]` direto;
  o harness vai avisar do drift se o scenario faltar.
- Para revisar o estado de cobertura → `/scenario-map`.
- Para o texto do scenario → `/spec-cite`.
