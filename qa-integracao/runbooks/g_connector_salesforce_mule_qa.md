# Guia — Apontar o Salesforce Connector do Mule (QAS) para a org QA

Para o Victor. Fonte: Salesforce Connector 12.0 Reference / Using Anypoint
Studio to Configure Salesforce Connector (docs.mulesoft.com) — nível A.

## O problema

O connector vem com defaults de **produção** (`login.salesforce.com`). Com o
usuário `.qa` da sandbox, autenticar em `login.salesforce.com` falha — e é
consistente com o sintoma observado: zero logins do usuário de integração no
LoginHistory do QA no dia do teste.

## Ajuste por tipo de conexão (campo exato → valor para a sandbox QA)

| Tipo de conexão | Campo | Default (PROD) | Valor para o QA |
|---|---|---|---|
| Basic Username Password | Authorization URL | `https://login.salesforce.com/services/Soap/u/<versão>` | `https://test.salesforce.com/services/Soap/u/<versão>` |
| OAuth v2.0 | Authorization Url / Access Token Url | `https://login.salesforce.com/services/oauth2/authorize` e `.../token` | trocar host por `test.salesforce.com` |
| OAuth JWT | Token Endpoint / Audience Url | `https://login.salesforce.com/services/oauth2/token` | `https://test.salesforce.com/services/oauth2/token`; Audience = `https://test.salesforce.com` (a doc lista test.salesforce.com como audience válido) |
| OAuth Client Credentials | Token URL | `https://{domain}.my.salesforce.com/services/oauth2/token` | `https://qabrasiltecpar--qa.sandbox.my.salesforce.com/services/oauth2/token` |
| OAuth SAML | Token Endpoint | `https://login.salesforce.com/services/oauth2/token` | `https://test.salesforce.com/services/oauth2/token` |

Observações da doc:

- **Basic auth só é suportada até a API v64.0** ("Supported by Salesforce API
  v64.0 and below"). O fluxo usa v63.0, então funciona — mas é mais um motivo
  para migrar para OAuth (JWT ou Client Credentials) no médio prazo.
- Basic auth: `Security Token` é obrigatório **a menos que o IP esteja
  allowlisted** no Salesforce ("It can be omitted if your IP is allowlisted") —
  e o security token muda a cada refresh/reset de senha da sandbox. Com o item
  E.3 (Login IP Ranges) implementado, o token deixa de ser necessário.
- JWT/SAML: o campo `Principal` é o **username** do usuário Salesforce — usar o
  username com sufixo `.qa` da sandbox.
- Usuário: `svc_sales_integracao@brasiltecpar.com.br.qa` (após o item B, com o
  PS `Integracao_Field_Service`).

## Validação objetiva

Após o ajuste, chamar o endpoint de teste e conferir no QA:

```sql
SELECT LoginTime, SourceIp, Application, Status, LoginType
FROM LoginHistory
WHERE UserId IN (SELECT Id FROM User WHERE Username = 'svc_sales_integracao@brasiltecpar.com.br.qa')
ORDER BY LoginTime DESC LIMIT 10
```

Login presente = connector na org certa. Sem login = ainda apontando errado,
independente do que o payload retorne.
