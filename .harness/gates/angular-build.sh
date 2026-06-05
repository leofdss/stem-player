#!/usr/bin/env bash
# Gate: type-check / build do Angular. Em projeto strict, o build é o
# checador de tipos mais confiável. (Quando houver testes Karma/Jest,
# adicione `ng test --watch=false` aqui.)
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
hgroup "Angular · type-check (ng build)"
if ! npx_has ng; then hskip "@angular/cli não instalado — rode npm install"; exit 0; fi
if npx --no-install ng build --configuration development >/dev/null; then
  hpass "Angular compila com os tipos em dia"
else
  hfail "build do Angular falhou (erro de tipos ou template)"
  exit 1
fi
