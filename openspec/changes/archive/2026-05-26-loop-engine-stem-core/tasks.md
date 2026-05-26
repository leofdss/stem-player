# Tasks — Loop Engine

Cada task de implementação é precedida pelo seu teste, seguindo TDD: escrever o
teste que falha, implementar até passar, refatorar.

## 1. Estrutura do módulo

- [x] 1.1 Criar o módulo `loops` em `stem-core` e registrá-lo em `lib.rs`
- [x] 1.2 Definir `LoopError` com `thiserror` (`EmptyRegion`, `OutOfBounds`)

## 2. Marcadores

- [x] 2.1 Teste: criar um marcador em posição válida retorna um id único e ele passa a constar na lista
- [x] 2.2 Teste: criar um marcador além de `track_len` retorna `OutOfBounds`
- [x] 2.3 Implementar `Marker`, `MarkerId`, `add_marker`, `remove_marker` e `markers`

## 3. Região de loop

- [x] 3.1 Teste: definir uma região válida `[start, end)` armazena a região
- [x] 3.2 Teste: `start >= end` retorna `EmptyRegion`
- [x] 3.3 Teste: `end` além de `track_len` retorna `OutOfBounds`
- [x] 3.4 Implementar `LoopRegion` e `set_region`
- [x] 3.5 Implementar `enable`, `disable` e a consulta do estado do loop

## 4. Reposicionamento

- [x] 4.1 Teste: avanço que não cruza o fim retorna `position + frames`
- [x] 4.2 Teste: avanço que cruza o fim volta ao início preservando o excedente
- [x] 4.3 Teste: avanço maior que a região faz o *wrap* correto (módulo)
- [x] 4.4 Teste: com o loop inativo, `advance` não faz *wrap*
- [x] 4.5 Implementar `advance`

## 5. Fechamento

- [x] 5.1 Revisar a cobertura dos casos de borda da spec; `cargo fmt` e `cargo clippy` sem warnings