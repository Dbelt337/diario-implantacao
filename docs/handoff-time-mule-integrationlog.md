# Handoff — Erro de integração IntegrationLog__c / composite (QAS)

**Data:** 2026-08-11 · **Ambiente:** QAS · **correlationId de referência:** `d5d75960-9592-11f1-9568-565f73f73f51`

## Resumo

A chamada composite da integração falhou por **dois problemas independentes**:

1. **Timeout entre camadas Mule** — a papi/eapi desistiu de esperar a sapi
   (`HTTP POST on resource 'http://btp-salesforce-sapi-qas:8081/.../api/composite'
   failed: Timeout exceeded`). É o erro `HTTP:TIMEOUT` do HTTP Requester do
   Mule 4, cujo `responseTimeout` padrão é **10 segundos** — pouco para uma
   chamada Composite do Salesforce.
2. **Campos inexistentes no Salesforce QAS** — o payload de log envia 9 campos,
   mas 7 deles não existem no objeto `IntegrationLog__c` do QAS. Qualquer
   insert falharia com `INVALID_FIELD`, e com `allOrNone: true` o composite
   inteiro (incluindo o `UpdateAccount`) sofre rollback.

Permissões foram verificadas e **estão OK** — não são causa.

## Evidências (queries executadas no QAS)

### Campos do objeto (EntityParticle)

| Campo enviado pelo Mule | Existe no QAS? |
|---|---|
| IntegrationName__c | Sim (string 255, gravável) |
| Name | Sim (string 80, aceita null) |
| RelatedRecordId__c | **Não** |
| IntegrationType__c | **Não** |
| TargetSystem__c | **Não** |
| RequestPayload__c | **Não** |
| ResponsePayload__c | **Não** |
| Status__c | **Não** |
| Timestamp__c | **Não** |

### Acesso de escrita (ObjectPermissions + PermissionSetAssignment)

| Usuário | Username | Acesso |
|---|---|---|
| Usuário de Integração | integration.user@brasiltecpar.com.br.qa | PS "Integraçao BTecpar" + "Integration" — CRUD completo |
| User Integration | userintegration@brasiltecpar.com.br.qa | Perfil Administrador do sistema — CRUD completo |
| Integracao Ordem Manual | guilhermecarvalho@brasiltecpar.com.br.integracao(.2).qa | PS admin + Admin BrasilTecpar — CRUD completo |

## Ações — lado Salesforce (nós)

- [ ] Criar/deployar os 7 campos faltantes no `IntegrationLog__c` do QAS
      (sugestão: `RequestPayload__c`/`ResponsePayload__c` Long Text Area 131072,
      `Status__c` picklist Sucesso/Erro, `Timestamp__c` Date/Time, demais Text).
- [ ] Confirmar com o time Mule **qual username** a connected app usa
      (provável: `integration.user@brasiltecpar.com.br.qa`).
- [ ] Conferir `PermissionsEdit` em `Account` para esse usuário (subrequest
      `UpdateAccount`).
- [ ] Avisar o time Mule quando os campos estiverem no ar para reteste conjunto.

## Pedidos — lado Mule (vocês)

1. **Timeouts em cascata**: subir o `responseTimeout` do HTTP Request que chama
   a sapi (padrão Mule 4 = 10s). Sugestão: sapi→Salesforce ~60s; camadas acima
   70–90s (quem está na frente sempre com timeout maior que quem está atrás).
2. **Investigar a lentidão** pelo correlationId acima nos logs da
   `btp-salesforce-sapi-qas`: a requisição chegou ao Salesforce? Quanto levou?
   Concluiu depois do timeout do chamador?
3. **Corrigir o error handler** que monta o log — hoje ele grava quase tudo
   nulo:
   - Capturar `integrationName`, `integrationType`, `targetSystem`,
     `relatedRecordId` e o payload original em `vars` **antes** do request,
     para estarem disponíveis no `on-error`.
   - `"RequestPayload__c": "null"` (string) indica `write()` de variável
     inexistente — usar `vars.requestPayload default {}`.
   - Preencher `Name` (ex.: `integrationName ++ " - " ++ correlationId`).
   - Mapear `HTTP:TIMEOUT` para **504** (gateway timeout) em vez de 500,
     para facilitar troubleshooting futuro.
4. **Retry com idempotência**: se adicionarem `until-successful`, atenção — o
   timeout é do chamador, então a operação pode ter **concluído** no Salesforce
   depois do estouro; retry cego pode duplicar o `UpdateAccount`. Usar external
   ID/upsert ou chave de deduplicação.

## Teste conjunto (após deploy dos campos)

```bash
# Validar o insert do log direto no Salesforce (sf CLI, org QAS):
sf data create record -o <alias-qas> -s IntegrationLog__c \
  -v "Name='Teste handoff' IntegrationName__c='TesteManual' Status__c='Erro' \
      TargetSystem__c='SAP' Timestamp__c='2026-08-11T14:42:23.000Z'"

# Depois, reteste ponta a ponta pela sapi (endpoint /api/composite) e
# acompanhar o novo correlationId nos dois lados.
```

## Referências

- MuleSoft — HTTP Connector (responseTimeout padrão 10s):
  https://docs.mulesoft.com/http-connector/latest/http-request-ref
- MDN — 504 Gateway Timeout: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/504
- Salesforce — Composite (25 subrequests, allOrNone):
  https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/requests_composite.htm
- Limites Salesforce (25 chamadas concorrentes >20s):
  https://blog.coupler.io/salesforce-api-limits/
