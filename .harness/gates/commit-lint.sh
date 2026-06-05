#!/usr/bin/env bash
# Gate: Conventional Commits. Recebe o caminho do arquivo de mensagem
# (padrão do hook commit-msg) ou valida o último commit.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Commits · Conventional Commits (commitlint)"
if ! npx_has commitlint; then hskip "commitlint não instalado — rode npm install"; exit 0; fi
msg_file="${1:-}"
if [ -n "$msg_file" ] && [ -f "$msg_file" ]; then
  if npx --no-install commitlint --edit "$msg_file"; then
    hpass "mensagem de commit válida"
  else
    hfail "mensagem fora do Conventional Commits — ver .harness/rules/conventions.md"
    exit 1
  fi
else
  if git log -1 --pretty=%B | npx --no-install commitlint; then
    hpass "último commit válido"
  else
    hfail "último commit fora do Conventional Commits"
    exit 1
  fi
fi
