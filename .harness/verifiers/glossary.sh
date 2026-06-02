#!/usr/bin/env bash
# .harness/verifiers/glossary.sh
#
# Mantém o vocabulário de domínio consistente com o glossário do project.md.
# Lê pares "proibido => preferido" de rules/glossary.txt e avisa quando um
# termo banido aparece em código ou specs. Aviso (não bloqueia) por padrão,
# porque linguagem natural gera falsos positivos.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "Domínio · consistência do glossário"
map="$(dirname "$0")/../rules/glossary.txt"
[ -f "$map" ] || { hskip "rules/glossary.txt ausente — pulando"; exit 0; }

scan_dirs="crates src-tauri/src src/app openspec/changes openspec/specs"
any=0
while IFS='=' read -r banned preferred; do
  case "$banned" in ''|\#*) continue;; esac
  banned="$(echo "$banned" | xargs)"; preferred="$(echo "$preferred" | xargs)"
  hits="$(grep -RniwE "$banned" $scan_dirs 2>/dev/null | grep -v 'harness:allow' || true)"
  if [ -n "$hits" ]; then
    any=1
    hwarn "termo '$banned' encontrado — prefira '$preferred':"
    echo "$hits" | head -5 | sed 's/^/      /'
  fi
done < "$map"

[ "$any" -eq 0 ] && hpass "vocabulário alinhado ao glossário"
exit 0
