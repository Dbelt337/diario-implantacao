# A-01 — Criar BusinessProfiles dos dealers (P0) — NÃO EXECUTADO

Referência: Salesforce Help "Create Business Profiles in Automotive Cloud". Cada dealer
tem um BusinessProfile filho do Account do dealer. 17 dos 21 Accounts nível-dealer da
DevSales estão sem BP `Sales Dealer` (evidência bloco 3).

## Pré-condições (do guia oficial)
1. **Permission set `Automotive Foundation`** no usuário que cria os BPs.
2. Valores de picklist definidos em Object Manager para **Region** no objeto BusinessProfile
   (o admin também pode definir valores de **Service Type** e **Business Partner Type**).
3. Se usar Automotive Scheduler (test drives / service appointments), **Service Territory é
   obrigatório** no BP — alinhado ao default de território = ServiceTerritory (A-07). Nesse caso,
   os ServiceTerritory precisam existir antes (Bloco 4.1 do plano).

## Mapeamento campo (label -> API name) — CONFIRMAR via describe
Rode `describe_businessprofile.apex` (abaixo) para confirmar os API names antes de montar a carga.
Confirmados pelo uso na auditoria e pela Sec 4.2: `AccountId`, `BusinessPartnerType`,
`ExternalReferenceNumber`, `BusinessPartnerCode`, `BusinessPartnerRegisteredName`, `ServiceType`.

| Label (UI) | API name provável | Observação |
|---|---|---|
| Account | `AccountId` | filho do Account do dealer |
| Name | `Name` | ex.: BP-00045 |
| Business Operating Name | `BusinessOperatingName` | confirmar |
| Business Partner Code | `BusinessPartnerCode` | código oficial |
| Business Partner Registered Name | `BusinessPartnerRegisteredName` | razão social |
| External Reference Number | `ExternalReferenceNumber` | **código SAP — chave do dealerCode lookup** |
| Business Partner Type | `BusinessPartnerType` | usar `Sales Dealer` |
| Service Type | `ServiceType` | multipicklist (Sales, Spare Parts Sales, Repair & Maintenance, Consultation, Vehicle Sales) |
| Business Tax Identifier | `BusinessTaxIdentifier` | confirmar |
| Region | `Region` | picklist (exige valores em Object Manager) |
| Service Territory | `ServiceTerritoryId` | opcional; obrigatório se Automotive Scheduler |

## Caminhos de execução
- **Manual (poucos registros):** App Launcher > Business Profiles > New, seguindo o guia.
- **Carga em massa (recomendado p/ os 17):** `A-01_bp_salesdealer_TEMPLATE.csv` +
  `sf data upsert bulk -o <alias> -s BusinessProfile -f A-01_bp_salesdealer.csv -i ExternalReferenceNumber`
  (upsert por `ExternalReferenceNumber` evita duplicar a chave SAP).

## Snippet de describe (somente leitura) — confirmar API names
Salvo também como `describe_businessprofile.apex`.
```apex
for(Schema.SObjectField f:BusinessProfile.SObjectType.getDescribe().fields.getMap().values()){
 Schema.DescribeFieldResult d=f.getDescribe();
 System.debug('BPF> '+d.getName()+' | '+d.getLabel()+' | '+d.getType()+' | ref='+d.getReferenceTo());
}
```
