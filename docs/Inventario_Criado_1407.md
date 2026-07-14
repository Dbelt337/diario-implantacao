# Inventário — TUDO que foi criado no sprint precios/pedidos (14/07)

## A. NA ORG (DevSales) — deployado/carregado hoje

### Metadado ativo
| # | Componente | O quê | Origem | Status |
|---|---|---|---|---|
| 1 | `PricebookEntry` +7 campos | PrecioMinimoAsesor, PrecioExonerado, PrecioExoneradoMinimo, Gastos, MontoCashback, AplicaCashback, VigenciaDesde (Currency/Checkbox/Date) | spec precios | ✅ manter |
| 2 | `PricebookEntry` history | enableHistory + trackHistory nos 7 | spec precios F3 | ✅ manter (auditoria governante) |
| 3 | `PS_Precios_Catalogo` | FLS r/w dos 7 + (CRED do objeto extinto, auto-limpo) | spec precios | ✅ manter |
| 4 | `Order` +4 campos | SAP_OrderNumber (extId), SAP_FacturaRef, SAP_SyncStatus (picklist), **Quote__c** (lookup — não existe QuoteId standard nesta org) | spec cockpit F1.1 / precios F4 | ✅ manter (são os campos que o Mule vai usar) |
| 5 | **Flow `Opp_AS_GenerarPedido`** (ATIVO) | Opp ganha + quote Accepted → Order Draft + linhas | spec cockpit F4.1 + adendo | ⚠️ ANTECIPADO — decidir (ver C) |
| 6 | **Flow `Order_AS_ActivarPorFactura`** (ATIVO) | factura preenchida → Activated + notificação | spec cockpit F4.2 | ⚠️ ANTECIPADO — decidir (ver C) |
| 7 | `GQ_Order_Activated` | Custom Notification Type (usado só pelo flow 6) | spec cockpit F4.2 | acompanha a decisão dos flows |
| 8 | `Admin` profile | FLS dos 4 campos do Order | operacional | ✅ manter |

### Dados (carga demo)
| # | Registro | Qtde |
|---|---|---|
| 9 | Pricebook2 `C101 - Vehículos y Motos (CR)` | 1 — ⚠️ com C105 existindo, renomear p/ "C101 - Vehículos (CR)" (edit no registro) |
| 10 | Product2 Hyundai (chave ProductCode SAP) | 6 |
| 11 | PricebookEntry (Standard + C101, CRC) | 12 |

### Criado e JÁ REMOVIDO hoje (não existe mais)
- Objeto `Solicitud_Cambio_Precios__c` + 5 campos + lookup na PBE (veto "não criar objeto novo"; auditoria = history).
- `Product2.Make__c` (duplicava `MakeName` nativo — regra "não criar campo se existe nativo").
- ⚠️ **`Product2.Version__c` AINDA EXISTE na org** — mesma regra se aplica; conferir equivalente nativo (VersionName apareceu nas sugestões do Inspector!) e deletar + Erase.
- Fakes de teste: 6 produtos + PBEs + OLIs + Vehicle "Polo" + Order 0000000001.

## B. NO REPO (não afeta a org até alguém deployar)
| Pasta/arquivo | O quê |
|---|---|
| `pkg_precios/` + `deploy_precios_catalogo.zip` | pacote de PROMOÇÃO no estado final (7 campos+history+PS) p/ QA/UAT |
| `pkg_history/` + `deploy_history_pbe.zip` | já deployado; mantido como fonte |
| `deploy/cockpit_fase1_4/Cockpit_Fase1_4.zip` | campos Order + os 2 flows (fonte do que subiu) |
| `deploy/precios_ajuste/*` | destructives usados na remoção da Solicitud |
| `deploy/rollback_motores/Rollback_Motores.zip` | **NOVO** — remove os 2 flows + notification type (ver C) |
| `carga_catalogo/*.csv` | carga demo (finais) + `6_pricebook2_C105.csv` **NOVO** (sociedad C105 motos) |
| `build_cockpit/*` | Fase 0 (investigação) + desenho do OmniScript pai — SÓ DESENHO, nenhum OmniScript foi criado na org |
| `testes/roteiro_e2e_motores_pedido.md` · `docs/Resumo_Executivo_Precios_Pedidos_1407.md` · `package_report.md` · `runbook_workbench.md` · `ajuste_pos_deploy_report.md` | documentação/evidências |

## C. Decisão pendente do arquiteto — os 2 flows antecipados
A spec do cockpit mandava "Fase 4 construir agora", mas a ordem atual é não ter flows ainda. Opções:
1. **DESATIVAR (recomendado)**: Setup → Flows → abrir cada um → View Details and Versions → Deactivate. Zero comportamento em runtime, metadado fica pronto para religar quando a fase chegar. Reversível em 2 cliques.
2. **REMOVER de vez**: primeiro desativar os 2 (flow ativo não deleta — cicatriz), depois deploy do `Rollback_Motores.zip` (Check Only ☐, Rollback ✅). Os 4 campos do Order ficam (inofensivos sem os flows).
Enquanto ativos: qualquer Opp que vire Ganado com quote Accepted gera pedido — se ninguém está testando isso, desativar evita surpresa em demo alheia.

## D. C105 (novo hoje)
Sociedad C105 = Active Motors CR (motos). Modelo: pricebook próprio → importar `carga_catalogo/6_pricebook2_C105.csv` quando houver produtos moto; renomear a C101 para "C101 - Vehículos (CR)" (Edit no registro do pricebook). Produtos moto (ex.: futuros Yamaha/moto Hyundai) entram com PBE Standard + PBE C105.
