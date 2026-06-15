# Botão "Consultar Lista Negra" no Lead (Quick Action LWC)

Wrapper LWC que aparece no Highlights Panel do Lead (ao lado de Edit/Delete/Clone)
e abre o OmniScript `LeadListaNegra/CheckUI` num modal.

## Por que precisa de wrapper
O OmniScript ativo **não** aparece sozinho no dropdown "Lightning Web Component" da
New Action (não tem o target `lightning__RecordAction`). No OmniStudio **Standard
Runtime** também NÃO existe um LWC gerado por OmniScript (isso era do pacote Vlocity).
Este wrapper:
- tem o target `lightning__RecordAction` → aparece no dropdown da Action;
- embute o OmniScript pelo componente base padrão **`lightning-omnistudio-omniscript`**
  (existe em toda org OmniStudio → o deploy compila, sem dependência de componente gerado);
- identifica o script por `type=LeadListaNegra`, `sub-type=CheckUI`, `language=English`;
- injeta o Id do Lead via `prefill` (`ContextId`/`leadId`).

## Pré-requisito
O OmniScript `LeadListaNegra/CheckUI` precisa estar **Ativo** (já está).

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
