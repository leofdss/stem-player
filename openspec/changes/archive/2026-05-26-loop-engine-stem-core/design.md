# Design — Loop Engine

## Unidade de posição

As posições — de marcadores, da região de loop e da reprodução — são
representadas em **frames de áudio (amostras)**, como inteiros sem sinal
(`u64`).

Motivação: o motor de áudio opera em frames; usar a mesma unidade torna a regra
de loop uma aritmética inteira **exata**, sem erros de arredondamento. O motor
de loop é **agnóstico à taxa de amostragem** — a conversão entre milissegundos e
frames acontece nas bordas (interface e motor de áudio), nunca dentro deste
módulo.

## Modelo

```rust
pub struct MarkerId(u64);

pub struct Marker {
    pub id: MarkerId,
    pub label: Option<String>,
    pub position: u64,        // frame
}

pub struct LoopRegion {
    pub start: u64,           // frame, inclusivo
    pub end: u64,             // frame, exclusivo
}

pub struct LoopEngine {
    track_len: u64,           // duração da faixa em frames
    markers: Vec<Marker>,
    region: Option<LoopRegion>,
    enabled: bool,
}
```

A região é o intervalo semiaberto `[start, end)`.

## Regra de reposicionamento

Operação central: `advance(position, frames) -> u64`.

- Loop **inativo** ou sem região definida: retorna `position + frames`. A
  saturação no fim da faixa é responsabilidade do motor de áudio, não deste
  módulo.
- Loop **ativo** com `position` dentro de `[start, end)`:
  - `raw = position + frames`
  - se `raw < end`: retorna `raw`
  - caso contrário: retorna `start + ((raw - start) % (end - start))`
- O uso do módulo garante o comportamento correto mesmo quando `frames` é maior
  que o tamanho da região (vários *wraps* em um único avanço).
- Se `position` está fora da região, `advance` apenas soma — o playhead entra na
  região naturalmente. "Saltar para o início ao ativar o loop" é decisão de
  transporte e fica para uma mudança futura.

## Marcadores × região

A região é definida diretamente por posições (`set_region(start, end)`). A
conveniência de "criar um loop entre o marcador A e o marcador B" é resolvida
pela interface, que lê as posições dos marcadores e chama `set_region`. Isso
mantém o núcleo mínimo e desacoplado.

## Erros

O módulo `loops` expõe `LoopError` (via `thiserror`):

- `EmptyRegion` — `start >= end`.
- `OutOfBounds` — posição além de `track_len`.

Regiões inválidas são rejeitadas; nunca ajustadas silenciosamente.

## Estratégia de testes

Tudo é função pura sobre inteiros — testes unitários diretos, sem hardware de
áudio. Casos de borda obrigatórios: avanço sem cruzar o fim; avanço cruzando o
fim; avanço maior que a região; loop inativo; região na primeira e na última
amostra; região inválida.