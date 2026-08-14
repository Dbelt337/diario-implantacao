# Contexto do projeto — GrupoQ / OSF Digital

Diário de implantação do programa Salesforce Automotive Cloud + MuleSoft + SAP para o **GrupoQ**, 6 países e 12 sociedades.

**Papel do Diego (dono deste repositório):** arquiteto do **fluxo de vendas** na OSF Digital.

**Fronteira de responsabilidade, importa em toda conversa:**
- **OSF:** arquitetura Salesforce (Diego) e o **time de MuleSoft**;
- **GrupoQ:** o **SAP é inteiro deles**. Workflow, RFCs, dados mestres e decisões de ERP não são entregáveis da OSF;
- Interlocutores do cliente: **Melisa Vallejo** (governança e arquitetura), **Santiago** (HU-045), **Gastón** (UX/protótipos);
- Time OSF citado: **Davi** e **Santiago** (build), **Flavio Medeiros**, **Pablo Brito** e **Diego Braz** (integração/Mule), **Roseli** (estimativas).

---

## DEMANDA CRÍTICA EM CURSO — HU-039

**HU-039 · Repuestos y PA · Gestión de Solicitud de Creación de Material.** Está aberta, é crítica e o Diego precisa fechar a solução sem se expor.

### Onde está tudo

| Documento | Para que serve |
|---|---|
| `docs/hu039-solucion-tecnica-para-la-hu.md` | **Seção em espanhol pronta para colar na HU.** É o entregável que fecha a história |
| `docs/hu039-cobertura-tecnica-2026-08-13.md` | Análise interna, conflitos com o código no ar, cruzamento com o inventário de integrações |
| `docs/hu039-que-construir-en-salesforce.md` | Lista de construção peça por peça, com ordem por blocos |
| `docs/diagramas/hu039-solucion.svg` e `.mmd` | Diagrama no visual do Lucidchart do cliente, e o Mermaid importável |
| `deploy/deploy-hu039-solicitud-material.zip` | Pacote 1: 3 Record Types, 18 campos, validation rule |
| `deploy/deploy-hu039-marca-lookup.zip` | Pacote 2: lookup de marca, isolado de propósito |
| `docs/scripts/post-deploy-hu039-asignar-recordtype.apex` | **Obrigatório após o pacote 1** |

### Decisões de arquitetura que não devem ser reabertas sem motivo

1. **A solicitação e o material são o MESMO registro Product2.** Nasce inativo com Record Type de solicitação e vira material definitivo quando o SAP confirma. Sem objeto custom (RN-05).
2. **`ProductRequest` não serve** e isso vai ser proposto por alguém em alguma reunião: ele pede peças que já existem e suas linhas apontam para um Product2 existente, o que é circular aqui.
3. **`RequestKey__c` único e External ID faz três trabalhos:** fecha a corrida de duplicados que Flow sozinho não fecha, permite reabrir após rejeição porque campo único ignora nulo, e é a chave do upsert de volta do Mule.
4. **Três camadas no controle de duplicados, de propósito:** LWC dá a mensagem amigável, Flow before-save com Custom Error é a regra formal da RN-34, campo único é a única sem janela de corrida.
5. **`ZQEV_DBM_CREACION_MATERIALES` recebe o código como ENTRADA e devolve só `MENSAJE`.** O SAP não atribui MATNR. É síncrona e a mesma função cria e estende. Só serve para repuestos, fixa ZREP, ZUN e ZQRP.
6. **A réplica MATMAS é o vetor concreto de duplicidade** que a RN-43 teme. O campo único transforma isso em erro determinista e tratável.
7. **Product2 não admite regras de compartilhamento nem compartilhamento manual.** Não há visibilidade por registro. É o único requisito capaz de derrubar a premissa da RN-05.
8. **Callout sempre antes de DML.** A ordem das RN-20 e RN-21 tem que ser invertida no código.
9. **Aviso ao Gestión de Inventarios:** não está definido (RN-54). Não se notifica dentro de um sistema quem não tem usuário nele, e é a mesma restrição que deixa o estado En revisión sem dono. Três opções documentadas, com `SAP_WAPI_START_WORKFLOW` como a única que resolve aviso e rastreabilidade juntos.

### Bloqueios abertos, em ordem

1. **De onde saem `CANAL` e `SERIE`**, entradas obrigatórias da RFC que o fluxo guiado não tem. Bloqueia a construção do caminho automático;
2. **Lista de campos da RN-49**, "todos los datos de la consulta rápida". Sem ela não há dimensionamento;
3. **Segmentos da réplica MATMAS**, se traz `E1MARCM` e `E1MVKEM` ou só `E1MARAM`. Define se a consulta ao SAP é exceção ou norma;
4. RN-24 traslado, RN-52 escalonamento, RN-54 aviso. Os três já declarados abertos pela própria HU.

---

## Ambiente e convenções

- **A implantação é Costa Rica.** Os outros cinco países entram depois. Costa Rica opera com **duas moedas, CRC e USD**, e as duas estão ativas na org. Por isso GTQ, HNL e NIO não estarem ativas não bloqueia o escopo atual, embora bloqueie as sociedades desses países quando entrarem. Sociedades de Costa Rica: **C101, Autos, e C105, Motos**.
- Org de trabalho: **DEV Sales**, e **INT** para integração. INT não tem a pilha de venta guiada, então pacotes para lá levam só metadados.
- **Convenção de nomenclatura GRPQM: metadados em inglês.** API names, labels e descrições em inglês; exibição em espanhol via Translation Workbench.
- Licenças verificadas em 13/08 com `docs/scripts/check-licencias-objetos.apex`: Automotive Cloud, avalúo, lending, Product Catalog Management e Commerce todos contratados com folga. **`AssetTitle` e `AssetTitleParty` não existem na org** apesar das licenças de lending, provável toggle de Setup.
- 2554 licenças Salesforce com 48 em uso. **Licença nunca é o obstáculo** quando se discute dar usuário a alguém.
- Não há acesso à org a partir daqui: as verificações vão como scripts `.apex` para o Diego executar em Execute Anonymous.
- `developer.salesforce.com` e `help.salesforce.com` são bloqueados pelo proxy. Pesquisar via WebSearch.

## Governança da org, decisão de 14/08

A org acumulou **39 automações**, com concentração em Lead, Account e Opportunity, e já apareceu campo custom duplicado entre equipes (moeda). Decisão do Diego: **freio na criação**, nada novo sem antes verificar o que já existe.

### REGRA DURA: não se cria nada sem consultar antes

Vale para **campo, objeto, Record Type, flow, classe, Custom Metadata, valor de picklist, permission set, lista de preço**, qualquer metadado. Antes de propor ou empacotar qualquer criação, é **obrigatório**:

1. Rodar um script de describe na org e olhar o que já existe, incluindo campos padrão livres, não só os custom;
2. Mostrar ao Diego o cruzamento entre o que se quer criar e o que já existe, item por item;
3. Só depois montar o pacote.

Não é etapa opcional nem se pula por pressa. **Um pacote montado sem essa verificação é retrabalho e é dívida**, porque tirar campo depois de criado é muito mais caro que não criar.

Casos reais que originaram a regra, todos em 14/08:

- O pacote da HU-039 nasceu com **18 campos em `Product2` sem nenhuma verificação prévia**. A revisão posterior mostrou que `RequestedMaterialCode__c` provavelmente é `ProductCode`, `RequestedBy__c` provavelmente é `CreatedById`, `SapLastError__c` e `SapRetryCount__c` cabem no Nebula Logger que já está instalado, e `RequestVin__c` e `RequestVehicleModel__c` estão no objeto errado, porque VIN é contexto de uma venda e o material fica no catálogo para todos. Verificação em `docs/scripts/check-product2-campos-existentes.apex`;
- `CountryCurrency__mdt` foi criado ao lado de `Sociedad_Config__mdt.Currency_Code__c`, que já existia e já era usado pelo `Lead_BS_DeriveSociedad`. Duas fontes para moeda;
- Sete Custom Metadata carregam país ou sociedade, e o código da sociedade se repete como texto livre sem integridade referencial nenhuma;
- `BusinessProfile.BusinessType__c` já carrega Aseguradoras, Talleristas, Repuesteras e Flotas/Arrendadoras, que é praticamente o catálogo de Grupo de Clientes que a RN-35 da HU-017 quer criar em outro lugar.

**Antes de aceitar criação vinda de outro time, aplicar a mesma regra.** Foi assim que se descobriu que o `CountryCurrency__mdt` proposto pelo time financeiro já estava deployado e duplicava o que existia.

### Demais decisões

- Inventário em `docs/scripts/inventario-automacoes-e-campos.apex`: flows ativos por objeto e gatilho, triggers por objeto, e campos custom com rótulo repetido.
- **Nunca sincronizar dois campos com o mesmo significado por Flow.** Escolher um, backfill, repontar e aposentar o outro. Manter os dois em sincronia perpetua a duplicidade e adiciona automação que pode falhar.
- Ordem entre flows do mesmo objeto e gatilho só é previsível com **Trigger Order** definida em cada um.
- O avalúo já existe na Opportunity, construído pelo Santi, sobre o objeto padrão `Appraisal`. Não replicar.
- **Antes de acrescentar valor a picklist restrita padrão, verificar se um valor existente já serve.** Acrescentar valor próprio faz funcionalidade padrão ver algo que não conhece, e trocar valores sem Replace deixa registros órfãos, que foi o que aconteceu com os quatro `Sales Dealer` do `BusinessProfile`.

## Preferências de comunicação do Diego

- Mensagens para o cliente **em espanhol**, prontas para colar no Teams. Documentos internos em português.
- **Sem emojis. Sem travessão nem hífen como pontuação, usar vírgula.** Nada que pareça texto gerado.
- Quer o número honesto, não a versão otimista. Prefere saber onde não cobre antes de fechar.
- Teams corta mensagens longas: sugerir divisão ou anexo.

## Segurança

O PDF `Integraciones_para_cotizar_y_crear_un_pedido.pdf` **contém credenciais de SFTP em texto claro**. Devem ser rotacionadas e removidas antes de qualquer distribuição. Nunca repetir os valores.
