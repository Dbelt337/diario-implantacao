# Diagnóstico: Order Management Standard ou Plus?

**Org:** Brasil Tecpar (`prod-brasiltecpar`)
**Data:** 13/08/2026
**Pergunta:** o org tem Industries Order Management **Standard** ou **Plus**?

---

## Resposta

**Order Management Standard.**

Confirmado diretamente na página **XOM Administration** em produção
(`/lightning/n/vlocity_cmt__VlocityXOMAdministration`):

> **CPQ/ORDER MANAGEMENT INTERFACE STATUS**
> **CONFIGURED FOR ORDER MANAGEMENT STANDARD**

O botão "Configure for Order Management Standard" aparece **desabilitado** — é o
estado corrente. O botão "Configure for Order Management Plus" está disponível
como mudança de modo.

### Segunda confirmação, na mesma página

O conteúdo da XOM Administration corrobora o status. Os nove itens listados são
todos de manutenção **on-platform** — jobs Apex agendados dentro do org:

- Apply Record Types and Page Layout Assignments
- Update Orchestration Queues Counters
- Schedule Jeopardy Management Job
- Schedule Future-Dated Tasks Job
- Schedule Orchestration Recovery Job
- Schedule Integration Retry Job
- Orchestration Data Purge Job
- Activate Fulfillment Diagram Graph Template

**Nenhuma entrada de OM Plus aparece**: Manage Secrets, Manage Encryption Keys,
Service Level Health Check, OMPL DB Query e Off-Platform Access Config estão
ausentes. A doc do OM Plus descreve essas entradas como parte da XOM
Administration em modo Plus (*"With OM Plus, you can view and edit custom secrets
directly from the XOM Administration page"*). No Plus, as responsabilidades
desses jobs migram para os pods na AWS.

---

## O que diferencia Standard de Plus

Não é tier de licença. É **arquitetura**.

| | OM Standard | OM Plus |
|---|---|---|
| Onde roda | Dentro do org, on-platform | Fora do org, em **AWS** |
| Stack | Apex + objetos `vlocity_cmt__*` | Kafka, PostgreSQL/RDS, pods, WAF v2 |
| Integração com o org | nativa | **ODIN** (Order Management Integration Layer) |
| Segurança | trust.salesforce.com | mTLS bidirecional SFDC↔AWS, chaves de criptografia geridas pelo cliente |
| Administração | objetos do pacote | XOM Administration page, Manage Secrets, Health Check, OMPL DB Query |
| Releases | ciclo do pacote CME | patches próprios, numeração `999.x` |

Fonte: [OM Plus: Security and Encryption](https://help.salesforce.com/s/articleView?id=ind.comms_t_om_plussecurity_and_encryption_240859.htm&language=en_US&type=5)
— *"Order Management Plus architecture includes significant differences from that
of Order Management Standard, most notably the addition of AWS."*

---

## Evidências corroborantes

| Verificação | Resultado | Conclusão |
|---|---|---|
| Página XOM Administration (produção) | `CONFIGURED FOR ORDER MANAGEMENT STANDARD` | **Standard** — prova direta |
| Itens da XOM Administration | só jobs Apex on-platform; sem Manage Secrets / Encryption Keys / Health Check / OMPL DB Query | **Standard** — a página renderiza o modo Standard |
| `NamedCredential` | 4 no total: `CNPJPublicAPI`, `GetAddress`, `MuleCallout`, `ZendeskStatusIntegration` | nenhuma aponta para OM Plus/AWS |
| `RemoteProxy` (Remote Site Settings) | ~140, todas FSL / Marketing Cloud / MuleSoft Tecpar / Google Maps / BrasilAPI / URLs internas | nenhum endpoint OMPL/XOM/AWS de orquestração |
| `PermissionSet` com label `OM %`, `%OMPlus%`, `%XOM%` | vazio | sample permission sets de OM nunca implantados |

**Argumento decisivo (antes mesmo da tela):** todo callout Apex para URL externa
exige Remote Site Setting **ou** Named Credential. Não há terceira via. Ambas as
listas estão limpas — logo não existia caminho de rede entre o org e um motor
off-platform.

Observação: os remote sites `EnableLWC*` referenciam `prod-brasiltecpar`,
confirmando que a sandbox analisada é refresh de produção e reflete a
configuração dela.

---

## Armadilhas — o que NÃO prova nada

Três sinais que parecem indicar OM Plus e não indicam:

1. **PSL `Comms Cloud Plus` ativa** (`vlocity_cmt_CommunicationsCloudPlusPsl`,
   2100 licenças, 1479 em uso, até 17/06/2028). É o tier do **Communications
   Cloud** (CME: CPQ, EPC, DC, OM on-platform) — não o sabor do Order Management.
   O "Plus" do nome é de outro produto.
2. **ApexPages com cara de OM Plus** (`XOMOffPlatformAccessConfig`,
   `XOMOmplDBQuery`, `XOMManageSecrets`, `XOMManageEncryptionKeys`,
   `XOMThorStatusPage`, `XOMLoki`, `XOMSyncDeltaPage`). O managed package
   `vlocity_cmt` instala **todas** as páginas independentemente do contratado.
3. **Permission sets `vlocity_cmt`** (`CommsPlusCCUser`,
   `CommunicationsCloudPlusRuntime`, `Async Engine *`, etc.). Mesma lógica: o
   pacote entrega todas as personas de todos os tiers.

**Regra geral:** presença de metadado prova apenas que o pacote está instalado.
Só configuração de runtime e conectividade provam provisionamento.

---

## ⚠️ Não clicar em "Configure for Order Management Plus"

O botão apenas troca o modo da interface CPQ/OM no org — **não provisiona nada**.
Sem o ambiente AWS do OM Plus operacional (Kafka, RDS, ODIN, certificados,
chaves de criptografia), acioná-lo aponta a submissão de pedidos para um motor
inexistente e quebra o fluxo em produção.

Sequência correta, caso o OM Plus venha a ser adotado:
provisionamento pela Salesforce → conectividade, certificados e chaves →
só então a troca de modo.

---

## Contratado ≠ implantado

O OM Plus pode constar no Order Form e nunca ter sido provisionado. As duas
afirmações convivem:

- **Contrato:** a confirmar no Order Form / com o AE.
- **Org, hoje:** OM Standard, comprovado acima.

Se o Plus estiver contratado, é preciso acionar a Salesforce para provisionar o
ambiente — com impacto direto no cronograma de implantação.

---

## ⚠️ Achado crítico: o motor de orquestração está parado

Verificado em produção em 13/08/2026.

### Nenhum job agendado

```sql
SELECT CronJobDetail.Name, State, NextFireTime, PreviousFireTime
FROM CronTrigger
WHERE CronJobDetail.Name LIKE '%Orchestration%'
   OR CronJobDetail.Name LIKE '%XOM%'
   OR CronJobDetail.Name LIKE '%Jeopardy%'
   OR CronJobDetail.Name LIKE '%Retry%'
```

**Resultado vazio.** Nenhum dos jobs da XOM Administration está agendado —
Orchestration Recovery, Integration Retry, Jeopardy Management, Future-Dated
Tasks, Data Purge.

### Passivo acumulado

| Objeto | Total | Distribuição |
|---|---|---|
| `OrchestrationPlan__c` | 260 | 47 `Completed` (18%) · **213 `In Progress` (82%)** |
| `OrchestrationItem__c` | 2.360 | 1.330 `Completed` · **813 `Pending`** · **201 `Running`** · **16 `Fatally Failed`** |

### Não é fulfillment longo — é travamento

A hipótese de que `In Progress` fosse normal em telecom (instalação de fibra,
agendamento de técnico) **foi descartada pelos dados**:

- Na maioria dos planos travados, `LastModifiedDate` é **idêntico** ao
  `CreatedDate` — o plano nasceu e nunca mais foi tocado. Fulfillment em
  andamento teria a data avançando conforme os itens completam.
- `Plan0000000`, o mais antigo, é de **14/12/2025**, última modificação em
  22/12/2025: ~8 meses parado.
- **Nenhum plano criado desde 28/05/2026** — ~2,5 meses sem entrada.
- Os 201 itens em `Running` estão marcados como executando sem nada executando.
- Os 813 `Pending` são trabalho enfileirado que ninguém puxa sem os jobs.

**Conclusão:** o OM rodou como piloto entre dezembro/2025 e maio/2026 e parou.
Hoje não está em operação.

### Não acionar "Start" direto em produção

Ligar os jobs parece a correção óbvia e **é perigoso**. O Recovery Job e o
Integration Retry Job varrem os 1.014 itens parados e os 213 planos travados e
disparam **integrações reais** — callouts para MuleSoft e sistemas de rede —
referentes a pedidos de 3 a 8 meses atrás. Provisionamento retroativo em
produção, sem ninguém esperando.

Sequência segura:

1. Reproduzir em sandbox e ligar os jobs lá primeiro, medindo o que dispara
2. Definir o destino do passivo histórico — purgar, encerrar ou descartar os
   213 planos — **antes** de qualquer agendamento
3. Tratar os 16 `Fatally Failed` (fila de fallout nunca trabalhada)
4. Só então agendar em produção, com monitoramento

---

## Escala: piloto, não produção

260 planos desde a origem (dez/2025), ~1 por semana no período ativo. Para uma
operadora com 1479 usuários no Comms Cloud Plus, não é volume de produção — é
piloto, homologação ou linha de produto isolada.

### Consultas usadas

```sql
SELECT vlocity_cmt__State__c, COUNT(Id)
FROM vlocity_cmt__OrchestrationPlan__c
GROUP BY vlocity_cmt__State__c
```
```sql
SELECT Id, Name, vlocity_cmt__State__c, CreatedDate, LastModifiedDate
FROM vlocity_cmt__OrchestrationPlan__c
WHERE vlocity_cmt__State__c = 'In Progress'
ORDER BY CreatedDate ASC
```
```sql
SELECT vlocity_cmt__State__c, COUNT(Id)
FROM vlocity_cmt__OrchestrationItem__c
GROUP BY vlocity_cmt__State__c
```

`LastModifiedDate` é o campo que distingue "em andamento" de "travado".

### Custom setting `XOMSetup`

```sql
SELECT FIELDS(ALL) FROM vlocity_cmt__XOMSetup__c LIMIT 200
```

`FIELDS(ALL)` evita adivinhar o nome do campo de valor.

O setting contém ~59 chaves, incluindo um bloco `Thor*` (`ThorCalloutRegion`,
`ThorCalloutAccessKey`, `ThorCalloutSecretKey`, `ThorAwsAccessKeysPath`,
`ThorSystemURL`, `ThorBaseDomain`…) e um bloco `OMPL*` (`OMPLSubmitMode`,
`OMPLCatalogSyncEventBatchSize`, `OMPLMonitoring.E2E.requestTimeoutMs`…).
"Thor" é a nomenclatura interna do motor off-platform em AWS.

**Isso não indica OM Plus.** `XOMSetup` é list custom setting e o managed package
instala o conjunto completo de chaves nos dois modos — mesma armadilha das
ApexPages e dos permission sets. O que decide são os **valores**:

| Chave | Leitura |
|---|---|
| `OrderSubmitMode`, `OMPLSubmitMode`, `OrchestrationMode` | modo de submissão/orquestração |
| `ThorSystemURL`, `ThorBaseDomain`, `ThorEnvironmentDomain` | vazios = sem motor off-platform |
| `InCoreDecompositionEnabled` | decomposição on-platform, coerente com Standard |
| `SchedulerEnabled` | `false` explicaria planos parados em `In Progress` |
| `SchedulerJobTimeIntervalMins`, `OrchestrationRecoveryWaitPeriodMins`, `OrchestrationRecoveryJobBatchSize` | cadência do motor |
| `OrderDecompositionEnabled` | decomposição ligada |
| `XOMDebug` | ligado em produção é achado à parte |

O custom setting diz o que *deveria* rodar; `CronTrigger` diz o que *está*
agendado. Os dois são necessários.

---

## Como reproduzir o diagnóstico

1. Abrir `/lightning/n/vlocity_cmt__VlocityXOMAdministration` e ler o
   **CPQ/Order Management Interface Status**. Resolve sozinho.
2. Conferência independente, via Salesforce Inspector (Tooling API para
   `RemoteProxy`):

```sql
SELECT DeveloperName, Endpoint, PrincipalType FROM NamedCredential
```
```sql
SELECT SiteName, EndpointUrl, IsActive FROM RemoteProxy
```
```sql
SELECT MasterLabel, DeveloperName, TotalLicenses, UsedLicenses, Status
FROM PermissionSetLicense ORDER BY MasterLabel
```

Rodar a lista de PSLs **sem filtro**: rótulos como `Comms Cloud Plus` não contêm
"Order Management", "Vlocity" nem "Industries", e escapam de filtros por palavra.

---

## Fontes

- [OM Plus: Security and Encryption](https://help.salesforce.com/s/articleView?id=ind.comms_t_om_plussecurity_and_encryption_240859.htm&language=en_US&type=5)
- [Order Management Plus Only: Patch Releases](https://help.salesforce.com/s/articleView?id=ind.order_mgmt_order_management_plus_patch_updates.htm&language=en_US&type=5)
- [CPQ, EPC, DC, OM Sample Permission Sets and Groups](https://help.salesforce.com/s/articleView?id=ind.comms_t_cpqepcdcom_sample_permission_sets_and_groups_250705.htm&language=en_US&type=5)
- [Industries Order Management](https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5)
- [Salesforce Order Management Licenses and Allocations](https://help.salesforce.com/s/articleView?id=commerce.om_licenses.htm&language=en_US&type=5) — produto distinto (Commerce), sem tiers Standard/Plus
