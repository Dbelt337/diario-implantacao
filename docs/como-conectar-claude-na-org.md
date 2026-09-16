# Como conectar o Claude Code na org (VS Code + Salesforce CLI)

Objetivo: o Claude roda `sf` na sua máquina, com a sua autenticação, dentro do repositório do diário. Ele consulta,
lista o que vai mudar, você aprova, ele grava e confere. Nenhuma senha ou token passa pelo chat.

## 1. Pré-requisitos (uma vez só)

1. **Node.js LTS**: https://nodejs.org (marque "Add to PATH"). Confira no terminal: `node -v`.
2. **Git**: https://git-scm.com. Confira: `git --version`.
3. **Salesforce CLI**: `npm install -g @salesforce/cli`. Confira: `sf --version`. Se já tiver o `sfdx` antigo, rode `sf update`.
4. **VS Code** com as extensões:
   - *Salesforce Extension Pack* (Salesforce).
   - *Claude Code* (Anthropic). Depois de instalar, clique no ícone do Claude na barra lateral e faça login com a sua conta Anthropic.
5. No VS Code, a janela precisa estar **Trusted** (é o que o seu print mostra); em modo restrito as extensões não rodam.

## 2. Repositório do diário na sua máquina

No terminal do VS Code (Terminal > New Terminal, PowerShell):

```powershell
cd C:\Users\DIego\Documents
git clone https://github.com/Dbelt337/diario-implantacao.git
cd diario-implantacao
git checkout claude/vigilant-planck-db8yo7
code .
```

Abrir o VS Code nessa pasta é o que dá ao Claude o contexto: diário, scripts 01 a 40, templates e validadores.

## 3. Projeto Salesforce dentro do repositório

O repositório não é um projeto SFDX. Crie um dentro dele (uma vez):

```powershell
sf project generate --name org --output-dir .
```

Isso cria a pasta `org/` com `sfdx-project.json` e `force-app/`. Todo comando `sf project ...` roda de dentro dela:

```powershell
cd org
```

## 4. Autenticar nas orgs

Abre o navegador, você loga normalmente (com MFA), e a CLI guarda a sessão no cofre do Windows.

```powershell
# producao
sf org login web --alias btp-prod --instance-url https://login.salesforce.com
# sandbox (preprod ou a que usarmos para testes)
sf org login web --alias btp-preprod --instance-url https://test.salesforce.com
# conferir
sf org list
```

Defina a padrão com cuidado. Recomendo deixar a **sandbox** como padrão e nomear a produção explicitamente em cada comando:

```powershell
sf config set target-org btp-preprod
```

Teste de leitura:

```powershell
sf data query -o btp-prod -q "SELECT COUNT() FROM agf__ADM_Work__c"
```

## 5. Retrieve dos metadados

Não puxe a org inteira de uma vez (Vlocity e pacotes gerenciados deixam pesado). Comece pelo que usamos:

```powershell
sf project retrieve start -o btp-prod --metadata "CustomObject:Account" "CustomObject:Opportunity" "CustomObject:Lead" "CustomObject:Quote" "CustomObject:Order" "CustomObject:agf__ADM_Work__c"
sf project retrieve start -o btp-prod --metadata "ValidationRule" "Flow" "ApexClass" "ApexTrigger" "PermissionSet" "Profile" "RecordType" "DuplicateRule" "MatchingRule"
```

Para ver tudo o que existe e escolher: `sf project generate manifest --from-org btp-prod --output-dir manifest` gera um
`package.xml` completo; edite e rode `sf project retrieve start --manifest manifest/package.xml`.

Catálogo EPC (produtos, atributos, picklists) não vem por metadados: é DataPack, via Vlocity Build (`npm install -g vlocity`
e `vlocity -sfdx.username btp-prod -job job.yaml packExport`). Fica para a Onda 1 do catálogo.

Os metadados retrieveados podem ir para o git (não têm segredo). Exports de dados com CNPJ, e-mail ou nome de cliente
ficam fora, como já está nos `.gitignore` de `tools/`.

## 6. Abrir o Claude Code e dar acesso

1. Com a pasta `diario-implantacao` aberta e trusted, clique no ícone do Claude na barra lateral (ou `Ctrl+Esc`).
2. Na primeira execução ele pede permissão por comando. Para leitura pode liberar de vez: quando ele pedir para rodar
   `sf data query`, `sf org display` ou `sf project retrieve`, escolha "Always allow". Para `sf apex run`, `sf data update`,
   `sf data import` e `sf project deploy` mantenha "Ask": esses gravam na org.
3. Diga no chat: **"conectado, orgs btp-prod e btp-preprod"**. Eu começo com `sf org display` para confirmar usuário e
   org, e sigo pela fila do diário.

O Claude usa a mesma CLI e a mesma sessão que você acabou de autenticar. Não existe token para colar no chat; se algum
comando pedir senha, pare e me avise.

## 7. Como vamos trabalhar conectados

- Leitura livre: consultas, describes, retrieve, logs.
- Escrita em duas fases, como hoje: eu mostro o antes e a lista exata do que muda; você responde "vai"; eu gravo e mostro o
  depois. Scripts continuam sendo salvos em `scripts/` e o resultado no diário, commitado.
- Produção só para o que vive lá (Agile Accelerator, chamados de sustentação). Cargas grandes (Gerente da conta do Marcelo,
  leads da SDR) passam pela sandbox primeiro.
- Ao terminar o dia, `sf org logout -o btp-prod` se a máquina for compartilhada; senão pode manter.

## 8. Fila para a primeira sessão conectada

1. `sf org display -o btp-prod` (confirma usuário, perfil e org).
2. Três consultas do Gerente da conta do Marcelo (`tools/gerente_conta/saida/consultas.soql`) na sandbox, passada online do
   validador, script 37 fase 1.
3. Decisão de 056, 070 e 102 na Sprint 1 (script 39 com `PUXAR_PARA_SPRINT1`).
4. Retrieve das regras de validação e flows de Account, Opportunity e Lead para o diário.
