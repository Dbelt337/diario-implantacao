# Autorização de Test Drive — Geração declarativa via Document Builder (spike 29–30/07/2026)

**Resultado: validado na sandbox DevSales.** Screen Flow `Generate Test Drive Authorization` gera o PDF da autorização a partir de um Service Appointment usando a ação `createServiceDocument` (Field Service Document Builder) e o exibe para conferência — **sem Visualforce e sem Apex**. Debug end-to-end executado com sucesso em 30/07/2026.

## Contexto (HU test drive / hand-off HU-009)

No dia da prueba, a recepção imprime a autorização (cliente, carro, asesor, sucursal, horário, licença) para firma física. Requisitos que o desenho atende:

- **RN 4.2 / troca de veículo**: o documento é gerado na hora, sempre com os dados atuais do SA — troca de carro no Modify nunca imprime autorização desatualizada.
- **Template custom** (objeção ao Service Report clássico): Document Builder tem editor visual de template próprio.
- **Sem código**: motor OOTB + configuração declarativa, alinhado à classificação FIT da HU.

## O que foi construído (branch `claude/file-preview-screen-flow-hmze3b`)

| Item | Descrição |
|---|---|
| `deploy/flows/Generate_Test_Drive_Authorization.flow` | Screen flow: valida template → `createServiceDocument` (inputs `recordId`, `templateId`, `title`) → tela de espera com re-consulta (geração é **assíncrona**) → poll no `ServiceReport` (output `pdfReportId`) até `ContentVersionDocumentId` preencher → tela de conferência. Fault path com `$Flow.FaultMessage`. |
| Resolução de template | Campo padrão **`ServiceDocumentTemplate`** do SA (sem sufixo "Id"!), com input `documentTemplateId` como override. Permite template por sucursal/Work Type via automação, sem tocar no flow. |
| ~~`Preview_Record_File.flow`~~ | Utilitário descartado em 30/07 — a funcionalidade de preview será embutida na tela final do flow principal quando o nome do componente File Preview for confirmado (pendência 1). |
| Template de teste | Document Builder → `Test Drive Authorization` sobre ServiceAppointment, ativado e org default. ID de teste: `0M0WK000000OeKT0A0`. |

Nomenclatura conforme **GRPQM Naming Conventions** (metadata em inglês, elementos em Natural Text, resources camelCase, textos de tela em espanhol).

## Setup necessário (checklist para outras sandboxes e PRODUÇÃO)

A investigação consumiu horas por dependências de provisionamento não óbvias. Na ordem:

1. **Field Service Settings → Enable Document Builder → SAVE** (o save falha silenciosamente se só marcar o checkbox; a confirmação é o aviso "look for an email... Document Builder is ready" e um e-mail em ~10 min — o provisionamento é assíncrono).
2. **Permission set com License = `Field Service Standard`** (a permissão *Document Builder* é gated pela PSL — não aparece em permission set com License = None). Marcar em System Permissions: **Document Builder** + **Field Service Standard**. Atribuir à persona da recepção (HU-009). A org tem 420 PSLs Field Service Standard.
3. **Template ativado** no Document Builder, criado sobre **Service Appointment** (template de Work Order não serve para recordId de SA).
4. O campo **Service Document Template** do SA populado por automação (ou org default como fallback).
5. Após mudanças de permissão, **relogar** (sessões não recarregam permissões — inclui Workbench).

## Armadilhas descobertas (para não repetir)

- Deploy "We can't find the createServiceDocument action" = feature não provisionada **ou** usuário de deploy sem a permissão (a validação usa o usuário logado no Workbench).
- Campo do SA é `ServiceDocumentTemplate` (o sufixo `Id` derruba o deploy com "field does not exist").
- **Não habilitar o input `documentType`** na ação — KB 005167190: causa "Something went wrong" em runtime; o default `ServiceDocument` é o correto.
- Template default traz componente **Signature** com "Signature Type" inválido se a picklist do objeto Digital Signature não tiver valores — configurar valor ou remover o componente.
- `locale` aceita só idioma ("es"); "es_ES" dá erro.

## Pendências

1. **Componente File Preview (Spring '26) embutido na tela final** — hoje a tela mostra link "Abrir la autorizacion". O `extensionName` do componente não é público (`flowruntime:filePreview` foi rejeitado no deploy). Ação: criar flow de teste na UI com o componente e fazer retrieve para capturar o nome real; substituir o link pelo preview embutido nos dois flows.
2. **Template real do GrupoQ** — recriar o layout no Document Builder (não importa Word/PDF) usando o mapper de dados já elaborado; avaliar componente Signature com linha de firma. Trocar o ID no campo do SA/org default.
3. **Botão/ação "Imprimir Autorización"** na página do SA chamando o flow (recordId entra automático).
4. **Flow RN 4.2** (`AssignedResource` after handler) estampando também o `ServiceDocumentTemplate` por sucursal/Work Type.
5. Renomear o flow legado `Buscar_Lead_GrupoQ_FA` para o padrão GRPQM (fora do escopo deste branch).

## Referências

- Create Service Document Actions (Actions Developer Guide) — inputs/outputs da ação
- Set Up Document Builder: Licensing and Enablement / Give Users Access to Document Builder (Salesforce Help)
- KB 005167190 — erro de runtime com documentType
- Setting the Service Document Template Field (Salesforce Help)
