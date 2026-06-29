---
name: harness-digest
description: >
  Roda o harness do Stem Player e devolve só um RESUMO de ~15 linhas: tabela
  gate → PASS/WARN/FAIL, as 3 primeiras falhas com arquivo:linha, e o próximo
  passo. A saída crua (centenas de linhas) vai para `.harness/last-run.log` —
  só leia se o resumo não bastar. Use no lugar de despejar `verify.sh --all`
  inteiro no histórico (especialmente antes de commit/push, no fechamento da
  fase Verify do PEV, ou em sessões longas onde o ruído já comeu contexto).
metadata:
  type: context-saver
  version: "1.0"
---

Substituto enxuto para `bash .harness/verify.sh`. Em vez de mandar a saída
crua para o contexto (facilmente +500 linhas), você emite um digest curto e
parqueia o log completo em disco.

**Input**: argumento opcional após `/harness-digest`:
- vazio   → modo automático (escala pelo diff): `verify.sh`
- `all`   → roda tudo: `verify.sh --all`
- `quick` → só checks rápidos: `verify.sh --quick`

Argumento recebido: `$ARGUMENTS`

---

## Procedimento

1. **Garanta o destino do log** (não polua o repo):
   ```bash
   mkdir -p .harness/.cache
   ```
   Use `.harness/.cache/last-run.log` como destino (já cabe no padrão de
   ignorar caches, e o `.harness/` é diretório de ferramenta, não de fonte).
   Se preferir, fixe um caminho fora do repo via `$HARNESS_LOG_PATH`.

2. **Rode o harness redirecionando a saída crua**:
   ```bash
   case "$ARGUMENTS" in
     all)   FLAG="--all"  ;;
     quick) FLAG="--quick";;
     *)     FLAG=""       ;;
   esac
   LOG=".harness/.cache/last-run.log"
   bash .harness/verify.sh $FLAG >"$LOG" 2>&1
   echo "exit=$?"
   ```
   **Não** ecoe `$LOG` no histórico. Ele existe para consulta sob demanda.

3. **Extraia só o que importa**, processando o log com `grep`/`awk`:
   - Linhas que começam com `▶` são o nome do check.
   - Resultado de cada check: `✓` (PASS), `⚠` (WARN), `✗` (FAIL), `∅` (skip).
   - Última seção "resultado" tem o sumário oficial (n falhas, n avisos).

   Exemplo de extração:
   ```bash
   awk '
     /^▶ /                  { check=$0; next }
     /^  ✓/                 { print "PASS " check; next }
     /^  ⚠/ || /^  ✗/        { print (/✗/?"FAIL ":"WARN ") check " :: " $0 }
   ' "$LOG"
   ```

4. **Pegue as 3 primeiras falhas com contexto** (1-2 linhas cada):
   ```bash
   grep -n '✗' "$LOG" | head -n 3
   ```
   Se a linha apontar para `arquivo:linha`, preserve esse trecho — é o que o
   agente principal vai abrir se precisar.

## Formato de saída (obrigatório, fixo)

Imprima **apenas** este bloco:

```
HARNESS · modo=<auto|all|quick>  log=.harness/.cache/last-run.log

GATES:
  ✓ <nome do check>
  ⚠ <nome do check>          (warn: <motivo curto>)
  ✗ <nome do check>          (fail: <motivo curto>)
  ∅ <nome do check>          (skip: <motivo>)

PRIMEIRAS FALHAS (até 3):
  1. <check> — <arquivo:linha> — <mensagem>
  2. <check> — <arquivo:linha> — <mensagem>
  3. <check> — <arquivo:linha> — <mensagem>

VEREDITO: <aprovado | aprovado com ressalvas | reprovado>  (F=<n>, W=<n>)
PRÓXIMO PASSO: <uma linha — ex: "abra <arquivo:linha> e remova o unwrap"
                                ou "tudo verde, commit liberado">
```

## Regras de ouro

- **Nunca** despeje o conteúdo do log no chat. Ele tem ANSI, banners,
  duplicação. O ponto desta skill é manter isso fora do contexto.
- Se houver 0 falhas e 0 warnings → veredito `aprovado`, próximo passo
  curtíssimo ("commit liberado").
- Se houver warnings → liste no máximo 3, sumarizados.
- Se houver falhas → veredito `reprovado`, próximo passo aponta a **causa**
  (não "rode de novo"). NÃO sugira corrigir você mesmo — quem corrige é o
  agente principal/PEV Execute.
- Em caso de erro do próprio script (`verify.sh` ausente, exit anômalo),
  reporte numa linha e pare.

## Quando NÃO usar

- Quando o usuário quer ver a saída completa para depurar uma regra de harness
  → mande `bash .harness/verify.sh --all` direto.
- Dentro do subagente `harness-verifier`: ele já é cético e prepara um
  relatório próprio (BLOQUEIOS/AVISOS/cenários). Esta skill é para o agente
  principal não importar todo o ruído.
