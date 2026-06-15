# Botão "Consultar Lista Negra" no Lead (Quick Action LWC)

Wrapper LWC que aparece no Highlights Panel do Lead (ao lado de Edit/Delete/Clone)
e abre o OmniScript `LeadListaNegra/CheckUI` num modal.

## Por que precisa de wrapper
O LWC gerado pelo OmniScript **não** tem o target `lightning__RecordAction`, então
não aparece no dropdown "Lightning Web Component" da New Action. Este wrapper tem o
target e **embute** o OmniScript, repassando o Id do Lead como `ContextId`.

## ⚠️ ANTES de deployar — confirmar o nome do LWC gerado
O wrapper referencia o componente gerado pelo OmniScript. **Se a tag não bater, o
deploy falha** (dependência de compilação).

1. Garanta que o OmniScript `LeadListaNegra/CheckUI` está **Ativo**.
2. **Setup → Custom Code → Lightning Components**, filtre por `LeadListaNegra`
   (ou `CheckUI`). Anote o **nome exato** do componente gerado.
3. Convenção esperada (Standard Runtime): `cfLeadListaNegraCheckUIEnglish`
   → tag em `leadListaNegraAction.html`: `<c-cf-lead-lista-negra-check-u-i-english>`.
4. Se o nome for diferente, edite a tag em `lwc/leadListaNegraAction/leadListaNegraAction.html`.

## Deploy
```bash
sf project deploy start --metadata-dir deploy/lead-lista-negra-action --target-org DevSales
# ou Workbench (zipar a pasta) — recomendado CHECK-ONLY primeiro
```

## Criar o botão no Lead
1. **Setup → Object Manager → Lead → Buttons, Links, and Actions → New Action**
   - Action Type: **Lightning Web Component**
   - Lightning Web Component: **c:leadListaNegraAction** (agora aparece no dropdown)
   - Label: `Consultar Lista Negra`
2. **Object Manager → Lead → Page Layouts** (ou Lightning Record Page no App Builder)
   → arraste a ação para **Salesforce Mobile and Lightning Experience Actions**
   → Save. O botão aparece no Highlights Panel, ao lado de Edit/Delete/Clone.

## Observações
- `recordId` é injetado automaticamente no contexto de Record Action; o wrapper
  passa `{ ContextId, leadId }` pro OmniScript via `prefill`.
- Os atributos do componente gerado (`layout`, `record-id`, `prefill`) seguem a
  convenção do Standard Runtime; se o OmniScript não receber o ContextId, ajustar
  o nome do atributo de prefill conforme a versão do OmniStudio.
