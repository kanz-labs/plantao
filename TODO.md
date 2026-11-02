# TODO — menos token, contexto limpo

- [ ] **Medir antes de mexer:** `--output-format json` no `rodar.sh`, gravando tokens e custo de cada turno em `/tmp/plantao/<nome>.uso`. Sem isso não dá pra saber o que funcionou.
- [ ] **Enxugar o prompt de sistema:** cada turno carrega todas as skills e plugins (hyperframes, vercel, marketing, remotion…). Rodar a quest só com o que ela usa: `--strict-mcp-config` com o Chrome, plugins desligados, `--setting-sources` mínimo.
- [ ] **Modelo por quest:** campo `modelo:` no `QUEST.md` (sonnet para trabalho mecânico, opus para o difícil), repassado via `--model`.
- [x] **Leitura pesada em subagente:** páginas web, arquivos grandes e buscas amplas vão para um subagente que devolve só a conclusão. O contexto principal não recebe o despejo.
- [ ] **Saída de ferramenta curta:** grep/head em vez de ler arquivo inteiro, `get_page_text` em vez de screenshot, sem reler o que acabou de editar. Colocar essas regras no `CLAUDE.md`.
- [ ] **Renovar a sessão quando o contexto sujar:** depois de N compactações, ou de uma pausa longa por limite (o cache expira e retomar relê tudo), começar sessão nova a partir do `QUEST.md` + `diario.md`. Pede um campo "estado atual" no `QUEST.md`, que a quest mantém atualizado.
- [x] **Retomada sem tentativa cega:** ler da saída o horário em que o limite volta e dormir até lá, em vez de tentar a cada 60 s.
- [ ] **`CLAUDE.md` curto:** ele entra em todo turno. Cortar o que não mudar comportamento.

# TODO — fila de quests

- [ ] **Fila:** rodar quests em sequência, cada uma começando quando a anterior conclui. Ex.: `plantao fila noite quest-1 quest-2`. Continua valendo rodar uma quest sozinha (`plantao ligar quest-1`) ou várias em paralelo (duas filas, ou fila + avulsa).
- [ ] Definir o que acontece quando uma quest da fila trava: pular para a próxima ou parar a fila.
