# Cockpit de Venta — Esqueleto do OmniScript pai `GrupoQ / VentaVehiculoCockpit`

**Padrão:** LENTE SEM ESTADO (arquitetura decidida). O pai não guarda nada: a cada abertura lê a verdade dos registros via `IP_LeerEstadoVenta`, mostra onde a venda está e oferece só o próximo passo válido. Fechou no meio? Nada se perde — reabrir = reler. Espera (aprovação, pago, SAP)? O filho informa e SAI; motores/record-triggered movem a etapa por trás. É isso que o torna robusto (nunca trava esperando), escalável (cada filho evolui sozinho) e simples para o vendedor (um painel, um botão de próxima ação).

**Convenção da org (Q7):** Type=`GrupoQ`, Language=`English` (rótulos em espanhol nos labels), SubType=`VentaVehiculoCockpit`. Filhos reusáveis: SubTypes `CockpitCotizar`, `CockpitUnidad`, `CockpitDescuento`, `CockpitAnticipo`, `CockpitFinanciamiento`, `CockpitCierre`.

## Elementos do pai (10 de 12 permitidos)

| # | Elemento | Tipo | Config essencial |
|---|---|---|---|
| 1 | `IPLeerEstado` | Integration Procedure Action | `GrupoQ_LeerEstadoVenta`, input `OpportunityId={ContextId}`, executa no load (1º elemento, fora de Step) |
| 2 | `SVFlags` | Set Values | normaliza a resposta em flags booleanas (abaixo) |
| 3 | `StepPanel` | Step (único sempre visível) | painel "Venta de {NombreOpp}" — Text Blocks condicionais mostram estado: cotización, descuento, unidad, anticipo, financiamiento, e O QUE ESTÁ BLOQUEANDO (ex.: "Esperando aprobación de descuento — te avisaremos") |
| 4 | `StepCotizar` | Step condicional `tieneQuote == false` | embute filho `GrupoQ:CockpitCotizar` (Reusable) |
| 5 | `StepUnidad` | Step condicional `tieneQuote && !unidadEnHold` | embute `GrupoQ:CockpitUnidad` |
| 6 | `StepDescuento` | Step condicional `tieneQuote && !descuentoPendiente && !quoteAceptada` | embute `GrupoQ:CockpitDescuento` (opcional — o vendedor pula se não há desconto) |
| 7 | `StepAnticipo` | Step condicional `tieneQuote && !anticipoConfirmado` | embute `GrupoQ:CockpitAnticipo` (stub 3.2) |
| 8 | `StepFinanciamiento` | Step condicional `financia == true` | embute `GrupoQ:CockpitFinanciamiento` (stub 3.3, slot sp_CotizarWS) |
| 9 | `StepCierre` | Step condicional `quoteAceptada && !descuentoPendiente` | embute `GrupoQ:CockpitCierre` |
| 10 | `StepFin` | Step final | "Pedido en generación automática" (o Order é do motor `Opp_AS_GenerarPedido`, NUNCA do wizard) |

Step Chart: OCULTO (propriedade Hide Step Chart) — os passos são condicionais, a barra confundiria.

## Contrato do `IP_LeerEstadoVenta` (Response → flags do pai)
Fontes confirmadas no describe (Q6): tudo já existe menos anticipo/financiamiento.
```json
{
  "oppId": "…", "nombreOpp": "Opportunity.Name",
  "rt": "RecordType.DeveloperName", "etapa": "StageName",
  "tieneQuote": "SyncedQuoteId != null",
  "quoteStatus": "Quote.Status (via SyncedQuoteId)",
  "quoteAceptada": "quoteStatus == 'Accepted'",
  "descuentoSolicitado": "DiscountRequested__c",
  "descuentoPendiente": "DiscountRequested__c != null && DiscountApprovalDecision__c vazio",
  "anticipoConfirmado": "STUB=false (org sem campo — Q6)",
  "financia": "STUB=false (org sem campo — Q6)",
  "unidadEnHold": "STUB até Q3b (describe do Vehicle)",
  "handOffStatus": "HandOffStatus__c"
}
```
2 DataRaptor Turbo Extract (Opportunity+RT; Quote) + 1 Response Action. Testável isolado via Connect API: `POST /services/data/v63.0/connect/omni-global/integration-procedure/execute/GrupoQ_LeerEstadoVenta`.

## Contrato dos filhos (regras fixas)
- Input: `OpportunityId` (ContextId propaga). Output: nenhum — filho grava em REGISTRO, nunca devolve estado ao pai (o pai relê).
- Filho que dispara espera (aprovação D-APR-02, link de pago) mostra "listo, te avisaremos" e TERMINA. Proibido passo de polling.
- Gate por filho: ≤25 elementos, 100% declarativo, Standard Runtime.
- `CockpitCotizar`: REUSAR o que já existe — a org tem `CrearCotizacion` OS ativo v2 e IP `CrearQuote` (inativo) + `DRQuoteInsert`/`DRFindPricebook`/`DRTurboExtractPricebookEntry`. Decidir "embutir vs recriar" depois do export (pendência E1).
- `CockpitDescuento`: grava `DiscountRequested__c`, chama **ação nativa Decision Matrix** do IP sobre `Discount_Rules_GrupoQ` (não existe flow LeadScore para copiar — achado 14/07), dentro do limite grava `DiscountApprovalDecision__c='Auto-Aprobado'`; acima, submete a D-APR-02 (contrato com Santiago — pendência E2) e SAI.
- `CockpitCierre`: DR Post Quote.Status='Accepted' → DR Post StageName=etapa ganada do sales process do RT (pendência Q11; até lá assumir 'Ganado', funil GQ) → o motor 4.1 faz o resto.

## Leitura do anti-exemplo b2bSalesQuote (regra 5 — 14/07)
Formato: DataPack vlocity managed (107 packs, 46k refs `%vlocity_namespace%`) → **NÃO serve de molde para o metadado Standard Runtime da nossa org** (E1 continua necessário). O que aproveitamos:
- **Inventário de elementos** (todos existem no Standard Runtime, exceto Remote Action=Apex, que é proibido mesmo): Conditional Block, Response Action, DR Extract/Post/Transform/Turbo, Set Values, IP Action, Rest Action (só dentro de IP), Loop Block, List Merge, Cache Block. Vocabulário 100% suficiente para o cockpit declarativo.
- **Padrão Cache Block de token** (`CAB_getToken*` + `IP_callGetToken*`): guardar para a integração GET /disponibilidad-sap do filho Unidad (3.1) — token cacheado, HTTP em IP separada da transação Connect API.
- **Confirmação do anti-padrão**: 93 Conditional Blocks em cascata, 31 Remote Actions, 13 refs CpqAppHandler — exatamente o que os gates (≤25 elementos, 100% declarativo) existem para impedir.

## Decisão do arquiteto (14/07) — Cotizar
"Tirar a criação de cotação nativa de dentro do wizard": o filho `CockpitCotizar` NÃO cria quote — **reusa o botão/OS `CrearCotizacion` v2 já construído**; SAP é o dono do preço. Pergunta aberta que muda o motor 4.1: a Quote de SF continua existindo como espelho com QLIs (SyncedQuote)? Se SIM, nada muda (motor copia QLIs→OrderItems). Se a cotização passar a viver SÓ no SAP, o motor precisa de outra fonte de linhas — decidir antes da Fase 2.

## O que ainda preciso (nada bloqueia o esqueleto, mas destrava os filhos)
| # | Item | Destrava |
|---|---|---|
| E1 | **Export do `CrearCotizacion` v2** (Designer → botão Export → JSON) e/ou retrieve Workbench do member `OmniScript: GrupoQ_CrearCotizacion_English` | molde EXATO do XML/JSON desta org p/ eu gerar os OmniScripts por metadado com segurança + decisão de reuso no Cotizar |
| E2 | Contrato D-APR-02 do Santiago (nome da orchestration + como submeter) | filho Descuento |
| Q3b | Describe do Vehicle | flag unidadEnHold + filho Unidad |
| Q5 | CalculationMatrix (2 queries separadas) | colunas de entrada/saída da matriz de desconto |
| Q4b | Lista completa de flows ativos (sem filtro "Lead") | existe flow de Link de Pago? colisões |
| Q11 | RT → BusinessProcess | etapa ganada certa no Cierre |
