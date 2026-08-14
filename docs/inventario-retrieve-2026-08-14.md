# O que está construído hoje, retrieve de 14/08

Fonte: retrieve completo da DEV Sales com `deploy/retrieve-venta-guiada/package.xml`.
11 MB, 1544 arquivos. Este documento guarda só o que muda decisão.

---

## 1. Coisas que eu afirmei antes e o retrieve corrige

**Corrijo três, e duas são minhas.**

| Eu disse | O retrieve mostra |
|---|---|
| "`Vehicle` não tem nenhum campo custom na DEV Sales, confirmar com o Santiago" | **Existem os cinco:** `ActualMake__c`, `ActualModel__c`, `ActualModelYear__c`, `ActualTrimLevel__c`, `AcquisitionType__c`. A premissa da HU-045 estava certa |
| "Os campos de Reserva só existem em QA, não em DEV Sales" | **Existem na DEV Sales:** `ReservationDate__c`, `ReservationExpiration__c`, `PaymentMethod__c`, e as regras `Opp_Retail_Reserva` e `Opp_Motos_FormaPago` estão ativas aqui também |
| "`Lead.CurrencyType__c` não existe na DEV Sales, o flow está bloqueado" | **Existe**, e o `Lead_BS_DeriveCurrencyType` está **ativo com trigger order 15**. Esse item está fechado |

---

## 2. Campos duplicados no `Order`, três pares

O mesmo dado com duas convenções de nome:

| Par | O que é |
|---|---|
| `SapOrderNumber__c` e `SAP_OrderNumber__c` | Número do pedido no SAP |
| `SapStatus__c` e `SAP_SyncStatus__c` | Estado do ciclo |
| `SapInvoiceNumber__c` e `SAP_FacturaRef__c` | Fatura |

Seis campos para três dados. Vale escolher um de cada par, backfill, repontar e
aposentar o outro, que é a regra de 14/08. Nunca sincronizar os dois por Flow.

E há uma quarta duplicidade em outro objeto: **`Account.CurrencyCode__c`**
convive com o `CurrencyIsoCode` padrão e com o `Currency_Code__c` do
`Sociedad_Config__mdt`. Três lugares descrevendo moeda.

---

## 3. `Account` já tem campos que eu ia criar

Antes de deployar `deploy-account-sapcompanycode.zip`, **verificar dois campos
que já existem**:

- **`Account.Sociedad__c`**, que pode ser exatamente o código da sociedade que
  eu queria criar;
- **`Account.SAPCustomerCode__c`**, que é provavelmente o deudor do cliente e
  não a sociedade, mas precisa ser confirmado antes.

Se `Sociedad__c` já carrega C101 e C105, o `SapCompanyCode__c` não deve ser
criado: basta torná-lo único e External Id, ou usar o que existe. **É a regra de
14/08 me pegando de novo**, e desta vez com um pacote já montado.

`Account` tem 44 campos custom, 2 Record Types, `B2BSparePartsCustomer` e
`BusinessAccount`, e uma validation rule inativa.

---

## 4. A HU-038 está mais construída do que se supunha

`PricebookEntry` já tem **sete campos custom, e são exatamente os comerciais**
do desenho v2:

`PrecioMinimoAsesor__c`, `PrecioExonerado__c`, `PrecioExoneradoMinimo__c`,
`MontoCashback__c`, `AplicaCashback__c`, `Gastos__c`, `VigenciaDesde__c`.

Isso confirma que a v2 sem objeto custom não é proposta, é o que já existe.

**Não existem** `PricebookEntry.PriceKey__c` nem `Pricebook2.PricebookCode__c`,
então o pacote da chave do Mule continua pendente. E `Pricebook2` não tem
nenhum campo custom, então `MarcaPropietaria__c` e `AprobadorMarca__c` da camada
de administração ainda não foram criados.

---

## 5. Automação: 81 flows, 55 ativos

| Estado | Quantidade |
|---|---|
| Active | 55 |
| Obsolete | 18 |
| Draft | 7 |
| InvalidDraft | 1 |

O número de 39 que vinha sendo usado está desatualizado.

**Lead concentra 14 flows ativos**, sendo 7 before-save e 5 after-save.
Opportunity tem 5.

### Colisões de ordem, duas

| Objeto | Gatilho | Ordem | Flows |
|---|---|---|---|
| Lead | before-save | **30** | `Lead_BS_EstampaAsignado` e `Lead_SetStatusOnConversion` |
| Opportunity | after-save | **sem ordem** | `Opp_AS_EvaluarDescuento` e `Opp_RT_Discount_Approval` |

A segunda é a que preocupa, porque as duas mexem em desconto e nenhuma declara
ordem. Entre flows sem Trigger Order a execução não é previsível.

`Lead_AS_CrossFieldDuplicateAlert` também está sem ordem, convivendo com quatro
que têm.

### Um `InvalidDraft`

Existe um flow em estado inválido. Não roda, mas polui e vale apagar.

---

## 6. Opportunity, 12 validation rules ativas

`Currency_Matches_Country`, `Metodo_Preferido_Requerido_Creacion`,
`Opp_Block_Stage_Change_When_Won_Or_Lost`, `Opp_Marca_Requerida`,
`Opp_Motivo_Cierre_Requerido`, `Opp_Motos_Expediente`, `Opp_Motos_FormaPago`,
`Opp_Motos_TipoCilindrada`, `Opp_No_Saltar_Etapas_Autos`, `Opp_Retail_Anticipo`,
`Opp_Retail_Reserva`, `Opp_Retail_Vehiculo_Cotizacion`.

Doze regras mais 5 flows no mesmo objeto. A regra do time financeiro,
`Currency_Matches_Country`, **já está ativa aqui**, então a proposta deles não é
proposta, é o que está no ar.

São **6 Record Types** em Opportunity, incluindo `GQOpportunitiesFlotas` e
`GQOpportunitiesMayorista`, que o roteador do modal ainda não trata.

---

## 7. Código: 52 classes, e quatro que não estavam em nenhum pacote

`OmniChannelLeadRouter`, `HU025_VR_E2E_Test`, `MaterialSearchService` e
`FinancingService`.

O `OmniChannelLeadRouter` é relevante para a conversa de habilidades por marca,
porque é ele que enruta o lead.

**`CreateSapMaterialAction` não existe na org**, coerente com o pacote
`deploy-remocao-action-material`.

LWC: 13 bundles, sendo quatro de outros times, `crearCotizacionAction`,
`leadListaNegraAction`, `gqAutoCloudSchedulerOpportunityAction` e
`gqAutoCloudSchedulerDriverLicenseControl`.

---

## 8. `Product2` continua sem Record Type

Zero Record Types e só dois campos custom, `SapMaterialCode__c` e `Version__c`.
Confirma que o pacote da HU-039 não foi deployado e que o script de pós-deploy
continua obrigatório.

E confirma a revisão dos campos: os 43 padrão incluem `BusinessBrandId`,
`ProductCode`, `ManufacturerPartNumber`, `HarmonizedTariffSchedCode` e
`HarmonizedSystemCode`, todos livres.

---

## Ordem sugerida

1. Confirmar `Account.Sociedad__c` antes de deployar o pacote de chave;
2. Resolver as duas colisões de ordem, principalmente a de desconto na
   Opportunity;
3. Escolher um campo de cada par duplicado no `Order`;
4. Deployar o pacote v2 da HU-039, que não depende de nada disso.
