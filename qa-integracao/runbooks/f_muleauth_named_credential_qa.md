# Runbook F — MuleAuth e endpoint do QA (depende de insumo do Victor)

## Contexto

- A automação `AccountGetSapIdQueueable` do QA dispara
  `callout:MuleCallout/btp-salesforce-eapi-prod/...` — a Named Credential do QA
  aponta para a **eAPI de PROD** (vazamento de ambiente identificado a tempo).
- A External Credential `MuleAuth` do QA está **sem principal** (o refresh de
  sandbox não copia segredos).

## Passos (quando os insumos chegarem POR CANAL SEGURO — nunca chat)

1. Recadastrar o principal da External Credential `MuleAuth` no QA com o
   client id/secret enviados pelo Victor.
   - Atenção: o secret do `troubleTicket-app` que circulou em chat em 11/08 está
     queimado — exigir o secret **rotacionado**.
2. Corrigir a Named Credential `MuleCallout` do QA: trocar o path
   `btp-salesforce-eapi-prod` pelo path não-prod confirmado pelo Victor.
3. Testar o ciclo: criar Account de teste no QA e verificar que o
   `AccountGetSapIdQueueable` completa sem erro de credencial e SEM tocar PROD.
4. Registrar no diário como "vazamento de ambiente evitado".

## Item G — pendências do Victor (acompanhar, não executar)

- [ ] Subir/health da sAPI-QAS (`btp-salesforce-sapi-qas:8081` — estava em timeout).
- [ ] Apontar o connector Salesforce do ambiente QAS do Mule para a org QA
      (validação nossa: LoginHistory do usuário de integração no QA).
- [ ] Adotar o JSON encadeado por chave de negócio (modelo já entregue).
- [ ] Path não-prod do Mule para a Named Credential (passo 2 acima).
- [ ] Client id/secret do MuleAuth por canal seguro (passo 1 acima).
- [ ] No reteste: enviar o correlationId; conferimos WorkOrder + IntegrationLog
      + login do usuário de integração.
