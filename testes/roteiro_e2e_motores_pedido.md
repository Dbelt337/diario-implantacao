# E2E — Motores de Pedido + Catálogo Precios (DevSales) · 14/07

**Pré-carga concluída:** 6 Product2 Hyundai + 12 PricebookEntry (Standard + C101 com precios, CRC). Motores `Opp_AS_GenerarPedido` (universal) e `Order_AS_ActivarPorFactura` deployados. Pré-requisito de FLS: Admin já tem (profile no pacote); PS_Api ainda pendente de FLS manual (só afeta o Mule real, não este teste).

## Cenário feliz (deixar os registros — são a demo)
| # | Ação | Esperado |
|---|---|---|
| 1 | Nova **Opportunity**: RT **GQ Oportunidades Autos**, Name "Demo Cockpit — Accent Sport", Account de teste, Close Date futura, etapa inicial do funil GQ | Opp criada com RT certo (o motor exclui só Mayorista) |
| 2 | Na Opp → related **Quotes → New Quote**: Name "Cot Accent Sport 2025", **Price Book = C101 - Vehículos y Motos (CR)** | Quote no pricebook C101 |
| 3 | Na Quote → **Add Products** → "Accent Sedan Sport 1.500 cc Gas T/A 2WD" (ProductCode `0YS4D661V D D319 2025`), Qty 1 | **UnitPrice = 28.900 vem sozinho da lista** (o precio do catálogo funcionando) |
| 4 | Na Quote → botão **Start Sync** | Quote vira SyncedQuote da Opp (OLI espelhada) |
| 5 | Editar **Quote.Status = Accepted** | salvo (se 'Accepted' não existir na picklist da org, anotar o valor equivalente — risco mapeado) |
| 6 | **Opp → etapa Ganado** → salvar | **MOTOR 1**: Order **Draft** nasce sozinho: `SAP_SyncStatus=Pendiente`, `Quote__c` preenchido, pricebook C101, **1 OrderItem a 28.900** |
| 7 | Verificar: `SELECT Id, OrderNumber, Status, SAP_SyncStatus__c, Quote__c, (SELECT PricebookEntryId, Quantity, UnitPrice FROM OrderItems) FROM Order ORDER BY CreatedDate DESC LIMIT 1` | Draft/Pendiente/1 linha 28900 |
| 8 | Simular retorno SAP: editar o Order (Inspector edit ou UI): `SAP_FacturaRef__c = FAC-CR-000123` (+ `SAP_OrderNumber__c = 4500001234` opcional) | **MOTOR 2**: `Status=Activated` + `SAP_SyncStatus=Confirmado` + **notificação no sininho** "Pedido activado: 00000XXX" para o owner da Opp |

## Negativos (2 min)
| # | Ação | Esperado |
|---|---|---|
| N1 | Opp Autos **sem** SyncedQuote → Ganado | NENHUM Order + **Task** "Pedido NO generado: sin cotización sincronizada" no owner |
| N2 | Opp **Mayorista** → Ganado | nada acontece (exclusão limpa, sem Task) |
| N3 | Quote sincronizada mas **Status ≠ Accepted** → Ganado | Task "no está Accepted", sem Order |

## Bônus auditoria
Editar `PrecioMinimoAsesor__c` de qualquer PBE do C101 → `SELECT Field, OldValue, NewValue, CreatedBy.Name, CreatedDate FROM PricebookEntryHistory ORDER BY CreatedDate DESC LIMIT 5` mostra a trilha (history governante em ação).

## Resultados (colar aqui)
- [ ] Passo 3 UnitPrice 28900:
- [ ] Passo 6/7 Order Draft + item:
- [ ] Passo 8 Activated + notificação:
- [ ] N1/N2/N3:
