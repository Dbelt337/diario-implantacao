# Consulta de débitos (internos e externos) de prospect — modelagem nativa Sales Cloud + Communications Cloud

**Data:** 26/08/2026 · **Premissa (diretriz Diego):** sem objeto custom — usar o modelo do produto (Vlocity CMT/SID) e Sales Cloud.

## Fundamento (documentação e padrão Telco)

- O modelo de dados do Communications Cloud é **fisicamente aderente ao SID do TM Forum** (doc oficial: "TM Forum SID-compliant physical data model", com o Party Model do pacote CME).
- No SID/TM Forum, **`CreditProfile` é atributo do `Customer`** (papel de cliente de uma Party) — TMF629 Customer Management expõe `creditProfile[]` (creditScore, creditRiskRating, validFor) no recurso Customer; há registro público da discussão TMF632×TMF629 confirmando o posicionamento no Customer.
- Tradução para o pacote: **Account (Customer) + Party Model do CMT** carregam o perfil de crédito; a consulta é processo OmniStudio (o próprio material de Communications Cloud lista *credit check* como caso canônico de OmniStudio, com APIs TMF de fábrica).

## Onde cada peça mora (sem objeto custom)

| Peça | Onde | Observação |
|---|---|---|
| Consulta runtime (interno: billing/ERP; externo: bureau) | **Integration Procedure** com um bloco por fonte + Named Credential | Dado vivo, nada de copiar faturas para o CRM |
| Exibição | **FlexCard** na record page da Account (reusado na Opportunity) | Consulta sob demanda; sem persistir extrato |
| Perfil de crédito persistido | **Account/Party (modelo do pacote)** — conforme SID: Customer.creditProfile | Rodar o discovery abaixo para usar o que o pacote da org já entrega antes de criar qualquer campo |
| Veredito no funil | Campos já existentes da Opportunity: `NeedFinancialApproval__c`, `FinancialApproval__c` | Consumidos pela etapa "Aprovação - Crédito" (fila Auditoria) da orquestração |
| Débito interno da base instalada | Assets/Contracts/Orders (Comms Cloud) + billing externo via IP | "Interno" só existe se o CNPJ tem billing account; para prospect puro só há externo |
| Débito do grupo econômico | Lookup `EconomicGroup__c` da Account | Régua de crédito por grupo: consultar débitos de todas as empresas do grupo |

## Discovery — o que o pacote da org já tem (rodar antes de decidir qualquer campo)

```sql
SELECT QualifiedApiName, Label FROM EntityDefinition
WHERE QualifiedApiName LIKE 'vlocity_cmt__%'
  AND (QualifiedApiName LIKE '%Credit%' OR QualifiedApiName LIKE '%Financ%'
       OR QualifiedApiName LIKE '%Party%' OR QualifiedApiName LIKE '%Risk%')
ORDER BY QualifiedApiName
```

```sql
SELECT QualifiedApiName, Label, DataType FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Account'
  AND (QualifiedApiName LIKE '%Credit%' OR QualifiedApiName LIKE '%Risk%'
       OR QualifiedApiName LIKE 'vlocity_cmt__%')
ORDER BY QualifiedApiName
```

Regra de decisão: existir objeto/campo do pacote para crédito → usar; não existir → campos em objeto **padrão** (Account), nunca objeto custom.

## Fluxo no funil

1. Entrada em "Análise cliente": IP roda (interno por CNPJ + grupo; externo por bureau) → preenche perfil na Account → seta `NeedFinancialApproval__c` pela régua (valor do débito × valor da opp).
2. "Aprovação crédito": Auditoria decide com o FlexCard aberto; reconsulta disponível se o dado venceu (validade do bureau — consulta é paga).
3. Decisão registrada pela orquestração (`UpdateApproved/Rejected_AprovacaoCredito`), como já implementado na W0382.

## Anti-padrões

- Objeto custom de "análise de crédito" com o Party Model/SID disponível.
- Copiar faturas do billing para o Salesforce (usar IP on-line; se precisar de lista, Salesforce Connect/external object read-only).
- Consulta ao bureau a cada abertura de página (custo por consulta; respeitar validade).
- Pendurar o perfil de crédito na Opportunity (morre com ela; o SID o coloca no Customer).

## Fontes

- Communications Cloud data model SID-compliant: help.salesforce.com (Communications Cloud / CME package) e visão geral do produto salesforce.com/communications/cloud
- TMF629 Customer Management (creditProfile no Customer): tmforum.org — especificações R17–R19 e discussão "CreditProfile on TMF632 and TMF629 Resource Models" (engage.tmforum.org)
- OmniStudio para credit check / TMF APIs de fábrica: material de parceiros Communications Cloud (Summit Technologies; Apex Hours — Salesforce Communications Cloud)
