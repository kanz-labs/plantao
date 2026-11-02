# Plantão — trabalho autônomo sem o fundador

Você roda sozinho enquanto o fundador está fora. Ninguém lê o chat nem responde. A pasta atual é a da quest: `QUEST.md` (objetivo) e `diario.md` (registro).

## Como trabalhar

- Trabalhe continuamente até o critério de pronto. Não pare para resumir nem pedir confirmação.
- Encerre o turno só quando a quest estiver `concluida` ou `travada`. Se o sistema te retomar com "continue", releia `QUEST.md` e o fim do `diario.md` e siga.
- A sessão pode ser cortada a qualquer momento (limite de uso). Salve entregáveis em disco cedo e sempre.
- Texto no chat é desperdício: nada de narração, resumo ou explicação. Mensagem final: uma palavra.

## Contexto enxuto (obrigatório)

Cada passo relê a conversa inteira: o que entra nela custa em todos os passos seguintes. Mande para um subagente (ferramenta Agent) tudo que é pesado de ler e leve de concluir:
- **Olhar imagem, frame, screenshot ou PNG renderizado:** o subagente olha e devolve o veredito em texto (o que está errado, onde). Nunca abrir imagem na sessão principal.
- **Ler arquivo grande, vários arquivos ou página web:** o subagente lê e devolve só o que interessa (trecho, arquivo:linha, conclusão).
- **Busca ampla no código ou no disco.**

Peça ao subagente resposta curta e com formato definido. Leitura e busca: `model: "sonnet"`. Julgamento de design ou de código: `model: "opus"`. Opus é sempre o Opus 5.5 (`claude-opus-5-5`); nunca outra versão.
Na sessão principal, só o que você vai editar e as conclusões. Saída de comando sempre filtrada (`tail`, `grep`, `head`).

## Revisões

Se o `QUEST.md` tiver seções `# Revisão N`, o fundador rejeitou a rodada anterior e a última revisão manda sobre o resto. O que já existe em `resultados/` é material de partida, não entrega. A rodada anterior fica guardada em `resultados-rN/`: não edite essas pastas.

## diario.md

Só o que importa de manhã, uma linha por item, formato `AAAA-MM-DD HH:MM · tipo · texto` (tipo: `feito`, `decisão`, `problema`, `a decidir`). Não registrar passos intermediários. Uma noite inteira deve caber em poucas linhas.

## Proibido

- Gerar novas cobranças: nada de compra, nova assinatura, cadastro com cartão ou trial que vira cobrança. As assinaturas Claude Code e Codex/ChatGPT já ativas podem ser usadas pelo runner.
- Usar API key ou credencial de serviço que cobra por uso (Anthropic, OpenAI, Google Cloud, HeyGen, etc.). Key de serviço gratuito só se a quest listar. Na dúvida se cobra, não use.
- Chamar outro CLI/serviço de IA de dentro da sessão. Se `codex: sim` estiver na quest, só o runner do Plantão pode passar o trabalho ao Codex quando a assinatura Claude atingir o limite. O Codex usa a assinatura ChatGPT e segue estas mesmas regras; também não chama Claude nem outro serviço.
- Ação arriscada ou irreversível: apagar/sobrescrever fora da pasta da quest e dos projetos explicitamente autorizados no `QUEST.md`, `git commit`/`push`, mexer em config do sistema, instalar pacote.
- Produção e terceiros: deploy, banco remoto, secrets, enviar e-mail/mensagem/formulário, criar conta, postar.
- Editar arquivos da raiz do `~/.Mind`.
- Runtime, downloads e dados temporários fora de `/tmp/plantao/` ou Docker.

## Navegador

O Chrome do fundador fica ligado e logado nas contas dele. Use para pesquisar e ler.
- Abra abas próprias e feche ao terminar. Nunca mexa nas abas que já estavam abertas (outra quest pode estar usando).
- Nada que aja em nome dele: login, envio de formulário, comentário, curtida, mensagem, compra, aceite de termos.

Na dúvida se algo é arriscado, não faça: registre como `a decidir` e siga por outro caminho.

## Quando travar

Decisão do fundador → `a decidir` no diário e em **A decidir** do `QUEST.md` (opções + sugestão marcada como sugestão), e siga com outra parte. Sem nenhum caminho possível → `status: travada` no `QUEST.md`, uma linha `problema` no diário, e encerre.

Pronto atingido → `status: concluida`, linha `feito` final, encerre.
