# Loop Engine — Marcadores e Loops de Repetição

## Why

A função central do Stem Player é permitir que o músico iniciante repita
continuamente um trecho de uma música para praticar. Hoje o projeto não tem
nenhuma lógica de loop.

Esta é a **primeira mudança** do projeto e foi escopada deliberadamente para a
**lógica pura** em `stem-core`, sem dependência de áudio ou interface — é
exatamente a parte que pode ser desenvolvida e validada com TDD desde já. O
motor de áudio, em uma mudança futura, irá apenas *consumir* esta lógica para
decidir a próxima posição de reprodução.

## What Changes

- Novo módulo `loops` em `stem-core`.
- Modelo de **marcador**: posição temporal nomeada na faixa, com identificador.
- Modelo de **região de loop**: par início/fim que delimita o trecho repetido.
- Regra de **reposicionamento**: com o loop ativo, ao avançar além do fim da
  região, a posição volta ao início preservando o excedente.
- Validação de regiões inválidas (início ≥ fim, posições fora dos limites da
  faixa), com erros explícitos em vez de ajuste silencioso.

## Out of Scope

- Reprodução de áudio e a integração com o motor de áudio (`audio`) — mudança
  futura. Aqui só se define a lógica que o motor de áudio irá consumir.
- Commands do Tauri e interface Angular.
- Persistência dos marcadores e da região no projeto `.json`.
- Seleção de loop por arraste na waveform (decisão de interface).

## Impact

- Crate afetado: `stem-core` — adição do módulo `loops`.
- Nenhum código existente é modificado: a mudança é uma adição isolada.
- Nova capability documentada: `loops`.