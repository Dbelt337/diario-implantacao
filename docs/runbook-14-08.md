# Passo a passo, 14/08

Ordem de execução do que está pronto para fazer. Cada bloco é independente,
então dá para parar entre eles.

---

## Bloco 1. BusinessProfile de sociedade, 10 minutos

O valor `GroupCompany` já foi criado às 17:09. Falta o Replace e o script.

### 1.1 Replace dos quatro órfãos

1. Setup, Object Manager, **Business Profile**, Fields & Relationships;
2. Abrir o campo **Business Partner Type**;
3. Na seção Business Partner Type Picklist Values, clicar **Replace**;
4. No formulário: valor a substituir **Sales Dealer**, valor novo
   **Concesionario de ventas**;
5. Confirmar. Ele reescreve os quatro `BusinessProfile` de uma vez.

**Não usar Del antes do Replace.** Apagar o valor deixa os registros com texto
solto sem correspondência na lista.

### 1.2 Limpar o valor inativo

Só depois do Replace, na seção Inactive Values, clicar **Del** na linha
`Sales Dealer`.

### 1.3 Criar os perfis de sociedade

1. Developer Console, Debug, Open Execute Anonymous Window, com **Open Log**
   marcado e **Debug Only** ativado;
2. Colar `docs/scripts/alta-businessprofile-sociedades.apex` e executar **como
   está**, em simulação;
3. Conferir no log: seção 3 deve listar C101, C105 e o `GrupoQ Nicaragua N105`,
   que aparece sem código; seção 4 deve dizer CREAR nos três;
4. Trocar `EJECUTAR` para `true` e executar de novo;
5. Executar uma terceira vez em simulação para confirmar que os três dizem OK.

**Sinal de que o Replace foi feito:** a seção 6 do log não mostra mais
`Sales Dealer` na contagem por tipo.

---

## Bloco 2. Deploy da HU-039, 20 minutos

É a demanda crítica e não depende de decisão de ninguém. **A ordem importa.**

1. Setup, Object Manager, **Product2**, Fields & Relationships, botão **Set
   History Tracking**, e habilitar o rastreamento no objeto. Sem isso o deploy
   é recusado, porque quatro campos vêm com histórico ligado;
2. Na mesma tela, marcar também o **`ProductCode`**, que passou a carregar o
   código solicitado. Campo padrão não viaja no pacote, então esse fica
   esquecido se não for agora;
3. Deployar **`deploy-hu039-solicitud-material-v2.zip`**. É o de 12 campos.
   **Não usar o `deploy-hu039-solicitud-material.zip` antigo nem o
   `deploy-hu039-marca-lookup.zip`**, que morreu quando `BusinessBrandId`
   resolveu a marca;
4. Rodar `docs/scripts/post-deploy-hu039-asignar-recordtype.apex`. Obrigatório.
   Sem ele os 281 produtos existentes ficam sem Record Type e somem das List
   Views;
5. Setup, Object Manager, Product2, Record Types, e atribuir os três aos perfis
   que vão usar.

---

## Bloco 3. Colisões de ordem entre flows, 10 minutos

A da Opportunity é a que importa: dois flows after-save mexendo em desconto,
nenhum com Trigger Order, execução imprevisível entre eles.

1. Setup, Flow, abrir **`Opp_AS_EvaluarDescuento`**, clicar no elemento Start,
   e definir **Trigger Order = 10**;
2. Abrir **`Opp_RT_Discount_Approval`** e definir **Trigger Order = 20**.
   Avalia primeiro, aprova depois;
3. No Lead, `Lead_BS_EstampaAsignado` e `Lead_SetStatusOnConversion` estão os
   dois na ordem 30. Mover um dos dois para 35;
4. `Lead_AS_CrossFieldDuplicateAlert` está sem ordem convivendo com quatro que
   têm. Definir 50, que é depois de todos.

Ativar cada um de novo depois de salvar a nova versão.

---

## Bloco 4. Verificações de dois minutos que destravam decisões

1. **`Account.Sociedad__c`**: Setup, Object Manager, Account, Fields, abrir o
   campo e ver o que ele carrega. Se já tem C101 e C105, o
   `deploy-account-sapcompanycode.zip` **não deve ser deployado**, basta tornar
   o que existe único e External Id;
2. **`Account.SAPCustomerCode__c`**: confirmar que é o deudor do cliente e não a
   sociedade;
3. **`SapMuleClient.mockMode`**: confirmar como é desligado no ambiente. O
   default é `true` e nada no código deployado o desliga. Antes de qualquer
   demonstração;
4. **Job `0AfWK00000FXwhJ0AT`**: Setup, Deployment Status, confirmar Succeeded, e
   rodar `fix-sociedad-config-colas.apex` em simulação para ver os dois
   prefixos corretos.

---

## Bloco 5. Mensagens que estão prontas e não saíram

Nenhuma depende de mais trabalho. Em ordem de urgência:

1. **Paulo**, repriorização do Release 1. Ele pediu ASAP e a captura da Melisa
   não chegou. Mandar o critério hoje, sem a lista;
2. **Melisa**, as duas perguntas da RN-35 da HU-017;
3. **Melisa**, os três blocos da HU-064;
4. **Flavio**, estrutura do catálogo de preços;
5. **Gastón**, os estados da tela da HU-039 e o ponto de que a criação não é
   instantânea;
6. **Lucas**, definição técnica dos campos de reserva.

---

## O que fica esperando terceiros

- **Mule:** perna de preço `ZHYB_DBM_PRECIO_VTA_NO_MAESTRO` e a chave de upsert
  da `PricebookEntry`. Enquanto a primeira não existir, repuesto criado é
  cotizado a zero;
- **GrupoQ:** de onde saem `CANAL` e `SERIE`, lista de campos da RN-49, e a
  moeda de Costa Rica contra a RN6;
- **Negócio:** ativar ou não GTQ, HNL e NIO. Não bloqueia Costa Rica, então
  pode esperar.
