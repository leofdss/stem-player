#!/usr/bin/env bash
# .harness/verifiers/tauri-thin.sh
#
# Regra 2 do project.md: src-tauri é uma casca fina. Cada #[tauri::command]
# deve apenas chamar stem-core e converter tipos. Heurísticas:
#   - corpo do command não pode exceder HARNESS_MAX_COMMAND_LINES linhas;
#   - command não pode conter laços (for/while/loop) — sinal de lógica.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "src-tauri · casca fina (commands enxutos)"
if [ ! -d src-tauri/src ]; then hskip "src-tauri/src ausente — pulando"; exit 0; fi

rc=0
# awk varre cada arquivo, detecta a fn após #[tauri::command] e mede o corpo.
report="$(
  for f in $(find src-tauri/src -name '*.rs'); do
    awk -v MAX="$HARNESS_MAX_COMMAND_LINES" -v F="$f" '
      /#\[tauri::command\]/ { armed=1; next }
      armed && /fn[ \t]+[A-Za-z0-9_]+/ {
        name=$0; sub(/.*fn[ \t]+/,"",name); sub(/[(<].*/,"",name)
        in_fn=1; armed=0; depth=0; start=FNR; loops=0; counted=0
      }
      in_fn {
        if ($0 ~ /\b(for|while|loop)\b/) loops++
        o=gsub(/\{/,"{"); c=gsub(/\}/,"}")
        depth += o - c; counted++
        if (depth <= 0 && counted>0) {
          body = counted - 1
          if (body > MAX) print F":"start": command `"name"` tem ~"body" linhas (max "MAX")"
          if (loops > 0)  print F":"start": command `"name"` contém laço — mova a lógica para stem-core"
          in_fn=0
        }
      }
    ' "$f"
  done
)"

if [ -n "$report" ]; then
  echo "$report" | sed 's/^/      /'
  hsoft "commands com indício de lógica — a casca deve só delegar a stem-core"
  rc=0   # heurística => aviso; vira erro só em modo estrito (via hsoft)
else
  hpass "commands do Tauri estão enxutos"
fi
exit "$rc"
