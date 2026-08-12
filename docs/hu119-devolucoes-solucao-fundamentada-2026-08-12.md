# Devoluções e anulações (HU-119 / RN-22) — solução fundamentada nas docs oficiais

**Data:** 12/08/2026 · Pesquisa: Object Reference (ReturnOrder/Order), Salesforce Help (Reduction Orders), SAP Help Portal (DBM), estado real da org DevSales (print Order Settings 12/08).

---

## 1. Como o mercado automotivo trata (fundamentado)

**O padrão da indústria é: o ERP/DMS é dono do DOCUMENTO de devolução; o CRM captura a SOLICITAÇÃO.** No SAP DBM (o ERP do GrupoQ):
- A reversão de uma venda se faz criando um **returns order** referenciando o documento original — é literal na documentação: *"To reverse the sales transaction, you can create a returns order"* (SAP Help Portal, DBM Order Processing).
- Processos de cancelamento/retirada usam tipos de documento próprios (ex.: sales order type **KA** para cancelamento de consignação, com return delivery).
- Peças: classe de documento de devolução própria — o **Z111** informado pela Isabella é exatamente isso (tipo Z customizado do GrupoQ).
Ou seja: o time SAP vai definir **tipos de documento de devolução** (por domínio), sempre com referência ao documento original. O Salesforce espelha essa estrutura: uma solicitação vinculada ao pedido original, por linha.

## 2. As TRÊS opções nativas da plataforma (e o estado de cada uma na org)

| Opção | O que é | Estado na org GrupoQ | Veredito |
|---|---|---|---|
| **ReturnOrder / ReturnOrderLineItem** | Objetos padrão DEDICADOS a devolução — "represents the return of order products in Order Management, or return/repair of inventory in Field Service" (API 42+) | **Indisponível**: requer Order Management ou Field Service habilitados — e o OMS foi avaliado e DESCARTADO no programa (histórico da própria HU) | ❌ Fora, pela mesma decisão que descartou o OMS. Se um dia o programa licenciar FS/OMS, é a evolução natural |
| **Reduction Orders** | Capacidade do **Order padrão**: pedido de redução com `OriginalOrderId` + `IsReductionOrder`, **por linha** (as linhas de redução referenciam as OrderItems originais) | Setting **existe e está DESLIGADO** (print 12/08: Setup → Order Settings → "Enable Reduction Orders" desmarcado) — por isso não aparecia nada no Object Manager | ✅ **RECOMENDADO** — modelo de dados exato do requisito, zero objeto novo |
| **Negative Quantity** | Linhas de pedido com quantidade negativa (ajuste dentro do documento) | **JÁ LIGADO** na org (print) | ⚠ Não recomendado como modelo de devolução: não gera documento próprio, não vincula linha→linha original, mistura reversão dentro do pedido — perde trazabilidade e o espelho 1:1 com o documento SAP |

## 3. A solução recomendada (ponta a ponta)

1. **Habilitar Reduction Orders** (Setup → Order Settings — o checkbox do print).
2. **Solicitação nasce no Salesforce**: tela própria (LWC) sobre o pedido original — seleção das linhas, quantidade a devolver, **motivo obrigatório**, anexos; cria a **reduction order via Apex** (`IsReductionOrder`, `OriginalOrderId`, linhas referenciando as originais) em rascunho + aprovação + **notificação a Logística** (fila/Custom Notification). *(Nota honesta: a UI padrão do Lightning para reduction orders é incompleta — por isso a tela é nossa e a criação é via Apex/API, que suporta tudo.)*
3. **Mule → SAP**: a reduction order aprovada vira o documento de devolução no SAP (tipo por domínio: veículos = a definir pelo time SAP; peças = **Z111** confirmado; PA = exceção bidirecional), sempre com referência ao documento original — exatamente o padrão DBM.
4. **Retorno SAP → SF** pelo canal já deployado (Platform Event / update inbound): status e número do documento SAP na reduction order.
5. Record types por domínio (Veículos / Peças / PA) na MESMA modelagem.

## 4. Verificações antes de fechar (rodar na DevSales)

1. **Habilitar o setting** e confirmar os campos:
```sql
SELECT QualifiedApiName FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Order'
  AND QualifiedApiName IN ('IsReductionOrder', 'OriginalOrderId')
```
2. **Compatibilidade com Enhanced Commerce Orders** (o print mostra ECO ligado e travado — "You can't disable this setting"): o checkbox de Reduction Orders aparece habilitável, o que indica compatibilidade, mas é obrigatório provar na prática antes de escrever na HU. Smoke test (Execute Anonymous, com um pedido ATIVADO existente):
```apex
// trocar 801... por um Order ativado da sandbox
Order original = [SELECT Id, AccountId, EffectiveDate, Status, Pricebook2Id
                  FROM Order WHERE Id = '801XXXXXXXXXXXX'];
Order reducao = new Order(
    AccountId = original.AccountId, EffectiveDate = Date.today(),
    Status = 'Draft', OriginalOrderId = original.Id, IsReductionOrder = true,
    Pricebook2Id = original.Pricebook2Id);
insert reducao;
System.debug(LoggingLevel.ERROR, 'REDUCTION OK: ' + reducao.Id);
```
Se o insert passar, o modelo está confirmado na org; se der erro de incompatibilidade com ECO, me manda a mensagem que eu redesenho (plano B: objeto de solicitação próprio — mas aí é exceção justificada por limitação de plataforma, documentada).

## 5. URLs oficiais (abrir direto — meu proxy bloqueia esses domínios)

- Reduction Orders (Help): `https://help.salesforce.com/s/articleView?id=sf.orderreduction_overview.htm&language=en_US&type=5`
- Enable Reduction Orders: `https://help.salesforce.com/s/articleView?id=sales.customize_order_enable_ro.htm&language=en_US&type=5`
- Order — Object Reference (`IsReductionOrder`, `OriginalOrderId`): `https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_order.htm`
- ReturnOrder — Object Reference (a opção descartada, para citar o porquê): `https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_returnorder.htm`
- SAP Help — DBM Order Processing (returns order referenciando o original): `https://help.sap.com/docs/SAP_DEALER_BUSINESS_MANAGEMENT/54c1b516c0fa4eb7a893ff13dcf76e7d/4a1120ec2228101ce10000000a42189b.html`
