# Package Report — deploy_precios_catalogo.zip (14/07/2026)

## Gate da spec (regras 1–2) — adaptação registrada
- `sf org list`: **impossível** — sf CLI inexistente neste ambiente e instalação bloqueada (npm 403); rede nega CONNECT a `*.salesforce.com` (proxy 403, verificado hoje). Não há alias DevSales.
- Consequência: Fase 1 (describes) **não pôde rodar aqui** → convertida no **Paso 0 do runbook** (3 queries anti-colisão no Inspector, com regras de decisão). Fase 3.2 (`sf ... --dry-run`) → convertida em **Workbench Check Only** (Paso 1), mesma semântica de validação sem gravação, executada pelo arquiteto (que é quem a regra 2 autoriza a deployar).
- **O pacote foi gerado assumindo ZERO colisão.** O Paso 0 é obrigatório antes do deploy; havendo colisão eu regenero.

## Conteúdo final (16 componentes)
| Componente | Tipo | Observação |
|---|---|---|
| `Solicitud_Cambio_Precios__c` | CustomObject | AutoNumber SCP-{0000}, ReadWrite, history ON |
| `…Estado__c` | Picklist | Pendiente (default) / Aprobado / Rechazado — **restrita** (ver divergência D3) |
| `…Marca__c` | Text(50) | |
| `…Sociedad__c` | Text(10) | |
| `…Tipo__c` | Picklist | Individual / Masiva — restrita (D3) |
| `…Comentario__c` | LongTextArea(1000, 3 linhas) | |
| `PricebookEntry.PrecioMinimoAsesor__c` | Currency(16,2) | precision 18/scale 2 no metadado (D2) |
| `PricebookEntry.PrecioExonerado__c` | Currency(16,2) | |
| `PricebookEntry.PrecioExoneradoMinimo__c` | Currency(16,2) | |
| `PricebookEntry.Gastos__c` | Currency(16,2) | |
| `PricebookEntry.MontoCashback__c` | Currency(16,2) | |
| `PricebookEntry.AplicaCashback__c` | Checkbox default false | |
| `PricebookEntry.VigenciaDesde__c` | Date | |
| `PricebookEntry.Solicitud__c` | Lookup(Solicitud_Cambio_Precios__c) | relationshipName `PricebookEntries`, SetNull |
| `Product2.Make__c` / `Product2.Version__c` | Text(80) | INCLUÍDOS por não haver como verificar 1.2 daqui — Paso 0.2 decide (remover se existirem) |
| `PS_Precios_Catalogo` | PermissionSet | CRED no objeto (sem ViewAll/ModifyAll) + FLS r/w dos 13 campos |

Arquivo PBE contém APENAS `<fields>` (não sobrescreve outras seções — regra 3 ok). Formato Metadata API tradicional, package.xml na raiz do zip, API 63.0.

## Campos omitidos por já existirem
Nenhum — verificação impossível deste ambiente; delegada ao Paso 0 (ver acima).

## Resultado do dry-run
Não executado aqui (gate). Substituto: Workbench **Check Only** antes do deploy real.
Validação local executada: **parse XML dos 5 arquivos OK** (Fase 3.1 ✅).

## Resultado do DEPLOY (14/07 17:32 UTC) — success: true, 20/20
Todos os componentes `created: true`: 8 CustomField PricebookEntry (ids 00NWK0000067u2J…u2Q) · 2 CustomField Product2 (Make__c/Version__c — não existiam, colisão zero) · 5 CustomField + CustomObject `Solicitud_Cambio_Precios__c` (01IWK000001pMQw2AM) · PermissionSet `PS_Precios_Catalogo` (0PSWK0000019NzJ4AU).
⚠️ Critério final continua sendo o Paso 3 (query nos FieldDefinition) — relatório de deploy não é prova (cicatriz Check Only 10/07). Pendências pós-deploy: atribuir o PS, layouts, tab.

## Divergências / decisões documentadas
- **D1 — Nome do objeto standard:** spec grafa `PriceBookEntry`; o API name real é `PricebookEntry` — usado o real (não é invenção de nome, é o nome).
- **D2 — Currency:** "precision 16, scale 2" da spec interpretado como Currency(16,2) da UI = `precision 18/scale 2` no metadado (precision = dígitos totais). Literal 16/2 geraria Currency(14,2).
- **D3 — Picklists restritas:** a spec não especifica; gerei `restricted=true` (padrão de governança do projeto). Reverter é trivial se precios "Masiva" exigir valores dinâmicos.
- **D4 — Product2.Make__c/Version__c: DUPLICAÇÃO CONFIRMADA (14/07).** O Product2 desta org tem o standard `MakeName` (Automotive Cloud). Decisão: a carga do catálogo usa `MakeName`; `Make__c` (e conferir `Version__c` vs equivalente standard) viram candidatos a destructive — alinhar com o dono da FO-10 antes de remover. Lição de carga: campo recém-criado/permissionado só aparece no Data Import do Inspector após F5 (cache de describe).
