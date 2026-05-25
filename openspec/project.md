# Stem Player — Contexto do Projeto

> Arquivo de contexto do OpenSpec. É lido pelo agente em **toda** proposta.
> Mantenha-o atualizado quando uma decisão estrutural mudar. Especificações
> detalhadas de features **não** moram aqui — vivem em `openspec/changes/`
> e, depois de arquivadas, em `openspec/specs/`.

## Propósito

Aplicativo desktop para reprodução de *stems* (faixas de áudio isoladas de uma
mesma música), com foco em **criar loops de repetição de trechos por meio de
marcadores temporais**. O músico delimita um trecho na linha do tempo e o app o
repete continuamente, permitindo treinar a sua parte tocando junto — ou no lugar
de — um instrumento da gravação original.

## Público-alvo

Músicos iniciantes que precisam repetir várias vezes o mesmo trecho de uma
música para praticar. As decisões de UX devem priorizar simplicidade e clareza
sobre densidade de funcionalidades.

## Stack

- **Tauri 2** — shell desktop e ponte de IPC.
- **Angular** — frontend renderizado na WebView. **Apenas apresentação.**
- **Rust** — toda a lógica, concentrada no crate `stem-core`.
- **cpal** — saída de áudio do sistema.
- **symphonia** — decodificação de áudio (wav, flac, mp3, etc.).
- **serde / serde_json** — persistência do projeto em `.json`.

## Regras arquiteturais (inegociáveis)

1. **Toda lógica de negócio fica no crate `stem-core`**, que não depende do
   Tauri e é 100% testável com `cargo test`.
2. **`src-tauri` é uma casca fina**: cada *command* apenas chama `stem-core` e
   converte tipos. Nenhuma regra de negócio aqui.
3. **O Angular só desenha a tela.** Nenhuma regra de negócio no frontend. A
   comunicação acontece exclusivamente por *commands* (Angular → Rust) e
   *events* (Rust → Angular).
4. **A saída de áudio real (cpal) fica isolada atrás de uma `trait`** (ex.:
   `AudioSink`), com implementação falsa nos testes e a real em produção.

## Estrutura de diretórios

```
stem-player/
├── Cargo.toml          # workspace Cargo
├── crates/
│   └── stem-core/      # lógica do app — alvo do TDD
├── src-tauri/          # casca Tauri (commands)
├── src/                # frontend Angular
├── openspec/           # specs e changes (fonte da verdade das features)
└── docs/               # documentação de visão e apoio
```

### Módulos de `stem-core`

- `session` — estado do projeto/sessão atual.
- `loops` — marcadores temporais e loops de repetição.
- `audio` — decodificação, mixagem e playback.
- `import` — importação de stems do disco.
- `persistence` — serialização do projeto em `.json`.
- `separation` — *adapter* (trait) para a API de separação. **Futuro.**

## Fluxo de desenvolvimento

- **Spec-Driven Development.** Toda mudança começa como uma proposta OpenSpec:
  `propose` → `apply` → `archive`. Não escrever código antes de a proposta
  estar revisada.
- **TDD.** Para cada task: escrever o teste que falha primeiro, implementar até
  passar, refatorar. A cobertura se concentra em `stem-core`.
- O comportamento detalhado de cada feature é definido na *change* do OpenSpec,
  nunca em documentos avulsos.

## Convenções

- **Rust:** edição 2021. `cargo fmt` e `cargo clippy` sem warnings antes de
  cada commit.
- **Erros:** usar `thiserror` em `stem-core`; tipos de erro próprios por módulo.
- **Idioma:** código e identificadores em inglês; termos de domínio seguem o
  glossário abaixo, de forma consistente.
- **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`, ...).

## Glossário de domínio

- **Stem** — faixa de áudio isolada de um instrumento ou voz de uma mesma
  música (ex.: bateria, baixo, vocal).
- **Projeto / Sessão** — conjunto de stems de uma música, mais marcadores e
  estado do mixer, salvo como arquivo `.json`.
- **Marcador** — ponto temporal nomeado na linha do tempo.
- **Loop** — trecho delimitado por um marcador inicial e um final, repetido
  continuamente durante o playback.
- **Mixer** — controle, por stem, de volume, mute e solo.
- **Mute** — silencia um stem específico.
- **Solo** — toca apenas o(s) stem(s) em solo, silenciando os demais.
- **Transporte** — controles de play, pause e stop.
- **Importação** — carregar arquivos de stem do disco para o projeto.
- **Separação** — (futuro) gerar stems a partir de uma música única, via API
  externa.

## Fora de escopo (por enquanto)

- Separação automática de stems via API — planejada; haverá o módulo
  `separation` com uma trait de adapter.
- Efeitos ou edição de áudio além de volume, mute e solo.
- Versão mobile.