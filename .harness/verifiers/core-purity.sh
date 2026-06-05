#!/usr/bin/env bash
# .harness/verifiers/core-purity.sh
#
# stem-core é a lógica que o motor de áudio (tempo real) vai consumir.
# Código de produção do crate não deve conter panics escondidos nem I/O de
# debug. Esta é uma rede de segurança RÁPIDA, complementar às lints do clippy
# (clippy::unwrap_used etc.) declaradas no Cargo.toml do crate.
#
# Tokens proibidos fora de testes:
#   unwrap(  expect(  panic!  unreachable!  todo!  unimplemented!
#   println!  eprintln!  print!  eprint!  dbg!
#
# A detecção de "fora de testes" remove blocos `#[cfg(test)] mod { ... }`
# via um pequeno autômato em awk, e ignora arquivos sob tests/.
# Escape pontual: anote a linha com `// harness:allow`.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "stem-core · pureza (sem unwrap/panic/print em produção)"

if [ ! -d crates/stem-core/src ]; then
  hskip "stem-core/src ausente — pulando"; exit 0
fi

pattern='unwrap\(|expect\(|panic!|unreachable!|todo!|unimplemented!|println!|eprintln!|print!|eprint!|dbg!'
rc=0
found=0

# awk: imprime "arquivo:linha:conteúdo" apenas para linhas FORA de um
# módulo de teste. Rastreia profundidade de chaves após `#[cfg(test)]`.
strip_tests() {
  awk '
    /#\[cfg\(test\)\]/ { pending_test=1; next }
    {
      line=$0
      if (pending_test && line ~ /\{/) { in_test=1; depth=0; pending_test=0 }
      if (in_test) {
        n=gsub(/\{/,"{"); m=gsub(/\}/,"}")
        depth += n - m
        if (depth <= 0) { in_test=0 }
        next
      }
      if (line ~ /#\[test\]/) { next }
      print FILENAME ":" FNR ":" line
    }
  ' "$1"
}

while IFS= read -r f; do
  # Arquivos de teste dedicados ficam de fora.
  case "$f" in */tests/*|*_test.rs|*tests.rs) continue;; esac
  hits="$(strip_tests "$f" | grep -E "$pattern" | grep -v 'harness:allow' || true)"
  if [ -n "$hits" ]; then
    found=1
    echo "$hits" | sed 's/^/      /'
  fi
done < <(find crates/stem-core/src -name '*.rs')

if [ "$found" -eq 1 ]; then
  hfail "tokens proibidos no código de produção de stem-core (ver acima)"
  hinfo "use Result/? em vez de unwrap/expect; remova prints; anote exceções com // harness:allow"
  rc=1
else
  hpass "stem-core sem unwrap/panic/print em produção"
fi

exit "$rc"
