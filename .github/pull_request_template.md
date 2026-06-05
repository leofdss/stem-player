## Change OpenSpec

<!-- Link/identificador da change. PR sem change correspondente costuma indicar drift. -->
- Change: `openspec/changes/<id>`

## PEV — checklist

### Plan
- [ ] O plano (`tasks.md`) deriva da spec, sem expandir o escopo.
- [ ] Não introduz dependência/biblioteca nova sem combinar antes.

### Execute (TDD)
- [ ] Cada task seguiu RED → GREEN → REFACTOR.
- [ ] Cobertura de `stem-core` mantida ou melhorada.

### Verify
- [ ] `npm run harness:all` passou localmente.
- [ ] Cada `### Scenario:` da spec tem teste correspondente.

## Fronteiras (marque o que se aplica)
- [ ] `stem-core` segue puro (sem Tauri/UI; sem unwrap/panic/print em produção).
- [ ] `src-tauri` continua casca fina (commands só delegam).
- [ ] Angular segue só apresentação (comunicação via IPC).
- [ ] Áudio real (cpal) isolado atrás de `AudioSink`.

## Pós-merge
- [ ] Spec da change pronta para `archive`.
