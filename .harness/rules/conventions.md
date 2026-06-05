# Convenções — Commits, branches e fluxo

## Conventional Commits

Formato: `tipo(scope): assunto` — assunto no imperativo, sem ponto final.

**Tipos:** `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`,
`ci`, `chore`, `revert`.

**Scopes** (alinhados à arquitetura e aos módulos de `stem-core`):
`core`, `loops`, `session`, `audio`, `import`, `persistence`, `separation`,
`tauri`, `ui`, `ipc`, `openspec`, `harness`, `deps`, `release`.

Exemplos válidos:

```
feat(loops): adiciona wrap da posição ao cruzar o fim da região
fix(audio): corrige cálculo de frames no AudioSink fake
test(loops): cobre região invertida retornando EmptyRegion
chore(harness): adiciona gate de cobertura para stem-core
```

Regras (aplicadas por `commitlint.config.js`):
- assunto ≤ 72 caracteres, em minúsculas, sem ponto final;
- `scope` opcional, mas se houver deve estar na lista acima;
- mudanças que quebram API usam `!` (ex.: `feat(core)!: ...`) + nota `BREAKING CHANGE:`.

## Branches

`feat/<change-id>`, `fix/<...>`, `chore/<...>` — uma branch por change OpenSpec.
A spec da change viaja na branch; no merge ela é arquivada em
`openspec/changes/archive/`.

## Fluxo (SDD + TDD + PEV)

1. **propose** — abrir a change OpenSpec (`proposal.md`, `tasks.md`, `specs/`).
2. **plan** — derivar tasks atômicas; gate: plano não expande escopo.
3. **execute** — por task: teste que falha → implementação → refactor.
4. **verify** — `npm run harness:all`; verificação independente dos cenários.
5. **archive** — merge do PR e arquivamento da spec da change.
