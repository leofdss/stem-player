# Regras — Angular (somente apresentação)

- **Zero regra de negócio.** A UI desenha estado e dispara intenções; quem
  decide é o Rust. Nada de cálculo de áudio, mixagem ou regra de loop no front.
- **Comunicação só por IPC.** Use *commands* (`invoke`) e *events* do Tauri,
  concentrados numa **camada de IPC** dedicada (arquivos `*ipc*`/`*bridge*`),
  com tipos espelhando os do `stem-core`. Componentes não chamam `invoke`
  diretamente — pedem ao serviço de IPC.
- **Sem áudio no navegador.** Nada de `AudioContext`/`decodeAudioData` & cia.
- **Sem filesystem no front.** Precisa ler disco? Exponha um command no Rust.
- **TypeScript strict** (já ligado em `tsconfig.json`): mantenha sem `any`,
  respeite `noPropertyAccessFromIndexSignature` etc.
- **Estilo:** ESLint (`eslint.config.js`, com `angular-eslint` para templates) +
  Prettier (`.prettierrc.json`). Rode `npm run lint && npm run format`.
- **Componentes** standalone (padrão do Angular 20), `OnPush` quando possível,
  estado reativo via signals/RxJS — mas sempre alimentado pelo Rust.
