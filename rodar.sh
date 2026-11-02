#!/usr/bin/env bash
# Mantém uma única execução por quest. Após limite, usa Codex se a quest permitir;
# após outras falhas, tenta retomar o Claude em 1 minuto.
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")" && pwd)"
NOME="${1:?uso: rodar.sh <quest>}"
Q="$RAIZ/quests/$NOME"
TMP=/tmp/plantao
# O codex do app ChatGPT se atualiza com ele; o /usr/bin/codex fica velho e a conta recusa os modelos
CODEX=/usr/lib/chatgpt/resources/codex
[ -x "$CODEX" ] || CODEX=codex
[ -f "$Q/QUEST.md" ] || { echo "quest $NOME não existe"; exit 1; }

# Só a assinatura: nenhuma chave de API ou provedor pago
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX
unset OPENAI_API_KEY OPENAI_BASE_URL CODEX_API_KEY AZURE_OPENAI_API_KEY

mkdir -p "$TMP"
exec 9>"$TMP/$NOME.lock"
flock -n 9 || { echo "quest $NOME já está rodando"; exit 0; }
cd "$Q"
touch diario.md

evento() { echo "$(date '+%F %H:%M') · sistema · $1" >> diario.md; }
ativa() { grep -q '^status: ativa' QUEST.md; }
codex_habilitado() { grep -q '^codex: sim$' QUEST.md; }
# Limite da assinatura (volta num horário conhecido) ≠ recusa passageira (429), que só espera 1 min
limite_assinatura() { grep -qiE "session limit|usage limit|hit your limit|limit will reset|resets? [0-9]" "$TMP/$NOME.saida"; }
limite_qualquer() { limite_assinatura || grep -qiE "rate limit|limit reached" "$TMP/$NOME.saida"; }

# A mensagem do Claude costuma incluir "resets 1:30am (America/Sao_Paulo)".
# Sem horário reconhecível, consulta de novo em uma hora.
proxima_tentativa() {
  python3 - "$TMP/$NOME.saida" <<'PY'
import datetime as dt
import re
import sys
from zoneinfo import ZoneInfo

message = open(sys.argv[1], errors='replace').read()[-4000:]
match = re.search(r'resets?\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?(?:\s*\(([^)]+)\))?', message, re.I)
if not match:
    print(int(dt.datetime.now().timestamp()) + 3600)
    raise SystemExit
hour, minute = int(match[1]), int(match[2] or 0)
if match[3]:
    hour = hour % 12 + (12 if match[3].lower() == 'pm' else 0)
try:
    zone = ZoneInfo(match[4]) if match[4] else dt.datetime.now().astimezone().tzinfo
except (KeyError, ValueError):
    zone = dt.datetime.now().astimezone().tzinfo
now = dt.datetime.now(zone)
target = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
if target <= now:
    target += dt.timedelta(days=1)
print(int(target.timestamp()) + 60)
PY
}

# Executa uma única sessão Codex por quest; a mesma trava flock cobre os dois CLIs.
# O Codex não herda a conversa do Claude: lê os artefatos e o diário da quest.
rodar_codex_ate() {
  local prazo="$1" rc inicio dur id prompt vazios=0
  local -a dirs=()
  # --ignore-user-config volta ao modelo padrão do CLI, que a conta ChatGPT pode recusar;
  # tenta os modelos em ordem e descarta o que a conta não aceitar
  local -a modelos=(${CODEX_MODELOS:-gpt-6-luna gpt-6-sol})
  if ! "$CODEX" login status 2>&1 | grep -q '^Logged in using ChatGPT'; then
    evento 'Codex indisponível pela assinatura; aguardando Claude'
    return
  fi
  for p in $(sed -n 's/^codex-pastas: *//p' QUEST.md); do dirs+=(--add-dir "$p"); done
  # codex-rede: sim libera busca e acesso à web (quests de pesquisa); padrão é sem rede
  if grep -q '^codex-rede: sim$' QUEST.md; then
    dirs+=(--search -c sandbox_workspace_write.network_access=true)
  fi
  while ativa && [ "$(date +%s)" -lt "$prazo" ]; do
    if [ -s .codex-sessao ]; then
      id=$(cat .codex-sessao)
      prompt="Continue a quest. Releia QUEST.md, o fim de diario.md e $RAIZ/AGENTS.md. Não mude o status do QUEST.md. Registre só decisões e feitos no diário."
      inicio=$(date +%s)
      "$CODEX" -C "$Q" --sandbox workspace-write --ask-for-approval never "${dirs[@]}" exec resume --ignore-user-config -c "model=\"${modelos[0]}\"" --json "$id" "$prompt" < /dev/null > "$TMP/$NOME.codex.jsonl" 2> "$TMP/$NOME.codex.erro"
    else
      prompt="Você assumiu esta quest porque a assinatura Claude atingiu o limite. Leia $RAIZ/AGENTS.md, QUEST.md, diario.md e os resultados existentes; continue de onde parou. As regras de segurança e de dinheiro do AGENTS.md e os limites do QUEST.md valem integralmente. Você roda sem rede e só escreve na pasta da quest e nas codex-pastas: pule o que depender de outra coisa. Não mude o status do QUEST.md. Não invoque Claude ou outro serviço de IA. Registre apenas decisões e feitos no diário; resposta final curta."
      inicio=$(date +%s)
      "$CODEX" -C "$Q" --sandbox workspace-write --ask-for-approval never "${dirs[@]}" exec --ignore-user-config -c "model=\"${modelos[0]}\"" --json "$prompt" < /dev/null > "$TMP/$NOME.codex.jsonl" 2> "$TMP/$NOME.codex.erro"
    fi
    rc=$?
    dur=$(( $(date +%s) - inicio ))
    # thread.started é emitido antes do trabalho; persistir o ID mesmo se o turno falhar.
    id=$(python3 - "$TMP/$NOME.codex.jsonl" <<'PY'
import json
import sys
for line in open(sys.argv[1], errors='replace'):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get('type') == 'thread.started' and event.get('thread_id'):
        print(event['thread_id'])
        break
PY
)
    [ -n "$id" ] && printf '%s\n' "$id" > .codex-sessao
    if [ "$rc" -ne 0 ] && grep -q "model is not supported" "$TMP/$NOME.codex.jsonl" "$TMP/$NOME.codex.erro"; then
      evento "Codex recusou o modelo ${modelos[0]}"
      modelos=("${modelos[@]:1}")
      rm -f .codex-sessao
      [ "${#modelos[@]}" -gt 0 ] && continue
      evento 'Codex sem modelo aceito pela conta; aguardando Claude'
      return
    fi
    [ "$rc" -eq 0 ] || { evento "Codex parou (código $rc); aguardando Claude"; return; }
    [ "$dur" -lt 60 ] && vazios=$((vazios + 1)) || vazios=0
    if [ "$vazios" -ge 3 ]; then
      evento 'Codex encerrou 3 turnos curtos; aguardando Claude'
      return
    fi
  done
}

[ -f .sessao ] || cat /proc/sys/kernel/random/uuid > .sessao
SESSAO=$(cat .sessao)

falhas=0; vazias=0
while ativa; do
  extra=()
  for p in $(sed -n 's/^pastas: *//p' QUEST.md); do extra+=(--add-dir "$p"); done

  # Sessão já gravada em disco (mesmo que a 1ª chamada tenha caído no limite) → retomar, não recriar
  if [ ! -f .iniciada ] && find "$HOME/.claude/projects" -name "$SESSAO.jsonl" -print -quit | grep -q .; then
    touch .iniciada
  fi

  if [ -f .iniciada ]; then
    args=(--resume "$SESSAO" "Continue. Releia $RAIZ/CLAUDE.md, QUEST.md e diario.md. O Codex pode ter trabalhado enquanto seu limite estava esgotado: confira os arquivos atuais antes de editar e preserve o progresso dele.")
  else
    args=(--session-id "$SESSAO" "Plantão iniciado. Siga as regras e trabalhe na quest.")
  fi

  inicio=$(date +%s)
  claude -p --chrome --model claude-opus-5-5 --permission-mode auto --autocompact 100k --add-dir "$RAIZ" "${extra[@]}" "${args[@]}" < /dev/null > "$TMP/$NOME.saida" 2>&1
  rc=$?
  dur=$(( $(date +%s) - inicio ))

  # Limite de uso pode sair com código 0: turno curto com mensagem de limite conta como queda
  if [ $rc -eq 0 ] && [ $dur -lt 60 ] && limite_qualquer; then
    rc=1
  fi

  if [ $rc -eq 0 ]; then
    touch .iniciada
    [ $falhas -gt 0 ] && evento "retomou após $falhas tentativas"
    falhas=0
    # Turnos curtos em sequência sem avanço: evita girar gastando limite
    if [ $dur -lt 60 ]; then vazias=$((vazias + 1)); else vazias=0; fi
    if [ $vazias -ge 5 ]; then
      sed -i 's/^status: ativa/status: travada/' QUEST.md
      evento "5 turnos seguidos sem trabalho, travada"
    fi
  else
    [ $falhas -eq 0 ] && evento "parou: $(tail -c 200 "$TMP/$NOME.saida" | tr '\n' ' ')"
    falhas=$((falhas + 1))
    if limite_assinatura; then
      # Espera até o horário em que o limite volta, em vez de tentar a cada minuto
      prazo=$(proxima_tentativa)
      if codex_habilitado; then
        evento 'limite do Claude; passando a quest ao Codex'
        rodar_codex_ate "$prazo"
      else
        evento "aguardando o limite até $(date -d "@$prazo" '+%H:%M')"
      fi
      restante=$(( prazo - $(date +%s) ))
      if ativa && [ "$restante" -gt 0 ]; then sleep "$restante"; fi
    else
      sleep 60
    fi
  fi
done
