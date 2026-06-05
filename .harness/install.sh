#!/usr/bin/env bash
# .harness/install.sh — ativa o harness no clone local.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "› apontando os git hooks para .harness/hooks"
git config core.hooksPath .harness/hooks
chmod +x .harness/hooks/* .harness/gates/*.sh .harness/verifiers/*.sh .harness/verify.sh 2>/dev/null || true

if command -v npm >/dev/null 2>&1; then
  echo "› instalando devDependencies do frontend (ESLint, Prettier, commitlint, openspec)"
  npm install
fi

echo "› (opcional) ferramenta de cobertura Rust:"
echo "    cargo install cargo-llvm-cov"

echo
echo "✓ Harness ativo. Comandos úteis:"
echo "    npm run harness         # verificação com escopo automático"
echo "    npm run harness:all     # tudo"
echo "    make verify             # idem, via Makefile"
