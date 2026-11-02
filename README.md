# Plantão

Cada quest fica em `quests/<nome>/QUEST.md`. `plantao ligar <nome>` inicia um serviço de usuário com uma trava e uma sessão Claude por quest. `plantao status` mostra o estado. `plantao desligar <nome>` pausa. `plantao reabrir <nome>` guarda a rodada anterior e cria sessões novas.

## Continuar no Codex quando o Claude atingir o limite

`plantao fallback <nome> codex` habilita a troca nessa quest. `plantao fallback <nome> nenhum` desabilita. Quests novas começam com a troca desligada.

Quando a saída do Claude indicar limite, o runner calcula o horário de retorno indicado por ele e inicia o Codex CLI autenticado por ChatGPT. A trava existente impede dois processos para a mesma quest. O Codex lê `CLAUDE.md`, `QUEST.md`, `diario.md` e os resultados em disco; a conversa do Claude não é importada. A sessão Codex fica em `.codex-sessao` e é retomada se houver outro turno. Quando o prazo do Claude chega, o próximo turno volta ao Claude. Um turno Codex em andamento termina antes da troca.

Por padrão, o Codex só pode editar a pasta da quest. Para permitir edição em um projeto, acrescente ao `QUEST.md` uma linha como `codex-pastas: /home/wtaf/projects/chatbot`. Não inclua nessa lista pastas somente de leitura. O Claude continua usando `pastas:`.

O runner remove variáveis de chave de API e só inicia o Codex quando `codex login status` confirma `Logged in using ChatGPT`. As chamadas Codex usam `workspace-write`, sem aprovações interativas e **sem rede** por padrão (sem busca na web, npm ou Docker). `codex-rede: sim` no `QUEST.md` libera busca e acesso à web, para quests de pesquisa. O Codex não tem o Chrome. O Codex nunca muda o `status` da quest; quem conclui ou trava é o Claude. Nenhum agente deve chamar o outro CLI por conta própria. As regras de dinheiro, produção e terceiros em `CLAUDE.md` valem para ambos.

Os acontecimentos importantes ficam em `quests/<nome>/diario.md`. A última saída do Claude fica em `/tmp/plantao/<nome>.saida`; a última saída estruturada do Codex e os erros ficam em `/tmp/plantao/<nome>.codex.jsonl` e `.codex.erro`. Esses arquivos temporários somem no reinício.

Com ou sem Codex, no limite da assinatura o runner dorme até o horário de retorno da mensagem (sem horário reconhecível, 1 hora). Recusa passageira ("rate limit", 429) só espera 1 minuto e não aciona o Codex. O fallback não foi exercitado com um limite real; se a mensagem mudar, a saída em `/tmp/plantao/` permite ajustar o detector.

## Linux e macOS

`plantao instalar` põe o comando em `~/.local/bin` e, no Linux, liga o serviço `plantao@.service` do systemd. No macOS cada quest vira um agente do launchd (`~/Library/LaunchAgents/com.kanz.plantao.<nome>.plist`), criado no `plantao ligar` e apagado no `plantao desligar`; os logs ficam em `/tmp/plantao/<nome>.servico.log`. As diferenças entre os dois sistemas ficam em `lib.sh`.

No macOS:
- Precisa de `python3` (vem com as ferramentas de linha de comando do Xcode) e do `claude` no PATH.
- O `caffeinate` impede o Mac de dormir enquanto a quest roda. Com a tampa fechada ele só fica acordado na tomada e com monitor externo.
- O Remote Control sempre ligado fica em `launchd/com.kanz.claude-rc.plist`; o comando de instalação está no próprio arquivo.
