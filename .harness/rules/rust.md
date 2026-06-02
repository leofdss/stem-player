# Regras — Rust (`stem-core` + `src-tauri`)

## stem-core (a lógica — alvo do TDD)

- **Independência total.** Sem `tauri`, sem nada de UI. Só `std` + crates de
  domínio (`thiserror` hoje; áudio quando chegar a hora).
- **Sem panics escondidos.** Nada de `unwrap`/`expect`/`panic!`/`todo!` no
  código de produção. Tudo retorna `Result<_, ErroDoModulo>`. As lints abaixo
  tornam isso um erro de compilação no clippy.
- **Sem I/O de debug** (`println!`, `dbg!`) no código de produção.
- **Erros com `thiserror`**, um enum por módulo (`LoopError`, `AudioError`, …).
- **Áudio isolado.** `cpal`/`symphonia` só dentro do módulo `audio`; a saída
  real fica atrás da trait `AudioSink`, com um *fake* determinístico nos testes.

### Lints recomendadas (adicione ao `crates/stem-core/Cargo.toml`)

```toml
[lints.clippy]
unwrap_used = "deny"
expect_used = "deny"
panic = "deny"
print_stdout = "deny"
print_stderr = "deny"
dbg_macro = "deny"
todo = "warn"
unimplemented = "warn"
```

Com o `clippy.toml` na raiz liberando esses padrões **em testes**, você ganha a
pureza no código de produção sem atrapalhar a suíte.

## src-tauri (a casca)

- Cada `#[tauri::command]` **só** valida/converte tipos e delega a `stem-core`.
- Sem laços nem lógica de domínio (o `verifiers/tauri-thin.sh` reclama).
- Não declare crates de áudio aqui — isso é de `stem-core`.

## Geral

- `cargo fmt` (config em `rustfmt.toml`) e `cargo clippy -D warnings` antes do commit.
- Padronize a `edition` entre os membros do workspace.
