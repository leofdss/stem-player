#!/usr/bin/env bash
# .harness/verifiers/angular-presentation.sh
#
# Regra 3 do project.md: Angular SÓ desenha a tela; nenhuma regra de negócio,
# e a comunicação acontece exclusivamente por commands/events do Tauri.
# Heurísticas:
#   - proíbe APIs de processamento de áudio no frontend (AudioContext, etc.);
#   - proíbe acesso a sistema de arquivos no frontend;
#   - `invoke`/`listen` só são permitidos na camada de IPC (arquivos *ipc*).
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$HARNESS_ROOT"

hgroup "Angular · só apresentação (sem lógica de negócio)"
if [ ! -d src/app ]; then hskip "src/app ausente — pulando"; exit 0; fi

rc=0

# 1. APIs que indicam lógica de áudio/negócio vazando para a UI.
biz="$(grep -RnE '\b(AudioContext|webkitAudioContext|AudioBuffer|decodeAudioData|createScriptProcessor|OfflineAudioContext)\b' \
        src/app 2>/dev/null || true)"
if [ -n "$biz" ]; then
  echo "$biz" | sed 's/^/      /'
  hfail "processamento de áudio no frontend — isso é papel do stem-core"
  rc=1
else
  hpass "sem processamento de áudio no frontend"
fi

# 2. Acesso direto a filesystem no frontend.
fsx="$(grep -RnE "from ['\"]node:fs|require\(['\"]fs|@tauri-apps/plugin-fs" src/app 2>/dev/null || true)"
if [ -n "$fsx" ]; then
  echo "$fsx" | sed 's/^/      /'
  hsoft "acesso a arquivos no frontend — prefira expor um command no Rust"
fi

# 3. invoke/listen concentrados na camada de IPC.
ipc_hits="$(grep -RlnE "invoke\(|@tauri-apps/api/event" src/app 2>/dev/null || true)"
if [ -n "$ipc_hits" ]; then
  leaked="$(printf '%s\n' "$ipc_hits" | grep -viE 'ipc|tauri|bridge|api' || true)"
  if [ -n "$leaked" ]; then
    echo "$leaked" | sed 's/^/      /'
    hsoft "invoke()/eventos fora de uma camada de IPC dedicada (arquivos *ipc*/*bridge*)"
  else
    hpass "comunicação com o Rust concentrada na camada de IPC"
  fi
else
  hskip "ainda não há chamadas de IPC (ok nesta fase)"
fi

exit "$rc"
