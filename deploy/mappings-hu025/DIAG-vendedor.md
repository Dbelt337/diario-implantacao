# HU-025 — Diagnóstico do Preferred Seller (não carrega na conversão)

Sintoma: conversão cria o produto (OLI) mas NÃO cria o OpportunityPreferredSeller.
Mapping LeadPrefToOppPrefOOBMappings agora tem AccountId/AccountRole/ContactId/
CurrencyIsoCode, mas o vendedor continua não aparecendo.

## Ferramenta: REST Explorer (a conversão engole o erro; a API cospe)

1) Pegar um LeadPreferredSeller:
   SELECT Id, AccountId, Account.Name, ContactId, AccountRole, CurrencyIsoCode
   FROM LeadPreferredSeller ORDER BY CreatedDate DESC LIMIT 5

2) POST /services/data/v65.0/connect/manufacturing/transformations
{
  "inputObjectIds": ["<LeadPreferredSeller Id>"],
  "inputObjectName": "LeadPreferredSeller",
  "usageType": "TransformationMapping",
  "outputObjectName": "OpportunityPreferredSeller",
  "outputObjectDefaultValues": {
    "OpportunityPreferredSeller": { "OpportunityId": "<Opp Id>", "CurrencyIsoCode": "CRC" }
  }
}

## Leitura do resultado
- INVALID_INPUT (derived mappings) -> remover o campo derivado do mapping.
- MISSING_ARGUMENT {...=[Campo]}   -> campo obrigatório: mapear/default.
- isSuccess:true                    -> mapping OK; faltou LeadPreferredSeller de
                                       origem ou o deploy não pegou.

Campos (describe): LeadPreferredSeller e OpportunityPreferredSeller compartilham
AccountId, AccountRole, ContactId, CurrencyIsoCode, Name. OppPrefSeller tem
OpportunityId (target). AccountId = o vendedor/dealer.
