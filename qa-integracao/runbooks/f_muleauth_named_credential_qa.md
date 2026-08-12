# Runbook F — MuleAuth e endpoint do QA (depende de insumo do Victor)

## Contexto

- A automação `AccountGetSapIdQueueable` do QA dispara
  `callout:MuleCallout/btp-salesforce-eapi-prod/...` — a Named Credential do QA
  aponta para a **eAPI de PROD** (vazamento de ambiente identificado a tempo).
- A External Credential `MuleAuth` do QA está **sem principal** (o refresh de
  sandbox não copia segredos).

## Fundamentação (nível A — Salesforce Help, "Considerations for Named Credentials")

- No refresh/clone de sandbox, os **parâmetros** da Named/External Credential são
  copiados, mas valores sensíveis NÃO: "authentication parameters on an external
  credential's principal, such as an API key and value or a client ID and client
  secret, aren't available in the sandbox". É intencional: evita a sandbox
  conectada automaticamente a ambientes de produção.
- "To test callouts after you create, refresh, or clone a sandbox, you must
  authenticate or enter credentials for a non-production environment in the
  external credential. We also recommend reviewing the named credential's URL" —
  ou seja, os dois sintomas do QA (principal vazio + URL apontando para
  eapi-prod) são exatamente o que a doc manda corrigir pós-refresh.

## Passos (quando os insumos chegarem POR CANAL SEGURO — nunca chat)

1. Recadastrar o principal da External Credential `MuleAuth` no QA:
   Setup → Named Credentials → aba External Credentials → `MuleAuth` →
   Principals → editar → reinserir client id/secret → salvar (se OAuth, marcar
   "Start Authentication Flow on Save" para reautenticar).
   - Atenção: o secret do `troubleTicket-app` que circulou em chat em 11/08 está
     queimado — exigir o secret **rotacionado**.
2. Garantir o vínculo de acesso do usuário que executa o callout (doc "Enable
   External Credential Principals"):
   - No permission set: seção **External Credential Principal Access** (em Apps)
     → habilitar o principal `MuleAuth - <nome do principal>`.
   - Object Settings → **User External Credentials** → conceder Read/Edit
     (perfis standard já têm desde Winter '25; perfis/PS custom precisam de
     concessão manual).
3. Corrigir a Named Credential `MuleCallout` do QA: trocar o path
   `btp-salesforce-eapi-prod` pelo path não-prod confirmado pelo Victor.
4. Testar o ciclo: criar Account de teste no QA e verificar que o
   `AccountGetSapIdQueueable` completa sem erro de credencial e SEM tocar PROD.
5. Registrar no diário como "vazamento de ambiente evitado".

## Item G — pendências do Victor (acompanhar, não executar)

- [ ] Subir/health da sAPI-QAS (`btp-salesforce-sapi-qas:8081` — estava em timeout).
- [ ] Apontar o connector Salesforce do ambiente QAS do Mule para a org QA
      (validação nossa: LoginHistory do usuário de integração no QA).
- [ ] Adotar o JSON encadeado por chave de negócio (modelo já entregue).
- [ ] Path não-prod do Mule para a Named Credential (passo 2 acima).
- [ ] Client id/secret do MuleAuth por canal seguro (passo 1 acima).
- [ ] No reteste: enviar o correlationId; conferimos WorkOrder + IntegrationLog
      + login do usuário de integração.
