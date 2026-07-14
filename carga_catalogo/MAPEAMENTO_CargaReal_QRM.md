# Carga Real de Precios — De-Para QRM → Salesforce (fontes: ReportesPreciovehiculo CR, Lista_precios_Hyundai CR, Flujo Carga QRM pptx/vsdx) · 14/07

## VALIDAÇÃO CENTRAL: a aba "Carga Masiva" do QRM bate 1:1 com os 7 campos deployados hoje
| Coluna QRM (Carga Masiva) | Salesforce | Status |
|---|---|---|
| Marca | `Product2.BusinessBrandId` (resolver por nome — 23 brands já na org) + `MakeName` | ✅ |
| Descripción QRM / Versión | `Product2.Name` | ✅ |
| Código (OCN) + Año | `Product2.ProductCode` = "Código Año" — **a convenção que usamos na demo JÁ é essa** | ✅ |
| Precio Lista / Precio QRM | `PricebookEntry.UnitPrice` (Standard + lista da sociedad) | ✅ |
| Precio Mínimo (PMV) | `PrecioMinimoAsesor__c` | ✅ |
| Precio Exonerado | `PrecioExonerado__c` | ✅ |
| Precio Exonerado Mínimo | `PrecioExoneradoMinimo__c` | ✅ |
| Gastos | `Gastos__c` | ✅ |
| Monto Cashback | `MontoCashback__c` | ✅ |
| Aplica Cashback | `AplicaCashback__c` | ✅ |
| Fecha Final Cashback ("Fecha Aplica") | ⚠️ GAP: nosso `VigenciaDesde__c` é vigência DESDE; o QRM manda a data FINAL da promo de cashback. Decidir: campo `CashbackFechaFin__c` novo (não há nativo) ou ressemantizar | ❌ decisão |
| Paquetes SVC | futuro (servicontratos) — fora da fase 1 | ⏳ |
| Colunas "Moneda Local" | só para países tipo GT. **No reporte CR estão TODAS zeradas → CR precifica em USD** | ⚠️ ver moeda |

## DECISÕES QUE O MATERIAL RESOLVE
1. **Moeda de CR = USD** (evidência: todas as colunas "moneda local" do reporte CR = 0; precios 18.900–40.500). → **Ativar USD em Manage Currencies ANTES da carga real** e recarregar as PBEs em USD (a demo de hoje está em CRC nominal — refazer é rodar os mesmos CSVs com moeda certa).
2. **Regra de aprovação de precio (do fluxo QRM, para espelhar na D-APR-02):** nova versão OU preço PARA BAIXO → requer VB do Director; preço para CIMA → NÃO requer; mudar só gastos → NÃO requer. Sem aprovação, o cotizador mostra "pendiente de autorización". Em SF: PBE history (auditoria) + orchestration disparada quando UnitPrice/PMV diminui.
3. **Tiers de alçada existem no QRM master** (Precio Gerente Venta / Precio Gerente Marca + exonerados equivalentes) mas NÃO viajam na Carga Masiva — são pisos de desconto por alçada. É insumo direto da **Discount_Rules_GrupoQ** (matriz de desconto do cockpit) e da conversa com Santiago, não campos de PBE.
4. **Regra do "X"**: na carga massiva QRM, coluna sem mudança = "X" → o upsert do Mule precisa de semântica de update parcial (não sobrescrever com nulo).
5. **Pré-requisito QRM = nosso**: modelo/versão/año criados antes dos preços (= Product2 antes de PBE, que já é nossa ordem 2→4→5).
6. **Montos nunca 0/vazio** no QRM — validação a replicar na entrada.
7. `Estado Versión` Activo/Inactivo → `IsActive` (Product2/PBE).
8. O reporte QRM traz a trilha Solicitud/Fecha/Autoriza — em SF isso é o PBE history + o approval; **não** recriar objeto (decisão mantida).

## Fluxo alvo (fase integração)
QRM/SAP (dono do preço hoje) → extrato tipo "Carga Masiva" → Mule → upsert Product2 (chave ProductCode; brand resolvida) → PBE Standard → PBE da sociedad (C101 autos / C105 motos — mapa `Brand_Sociedad_Map__mdt`) em USD. Enquanto a integração não existe: o MESMO Excel da Carga Masiva alimenta os CSVs do Inspector (o processo de hoje é o manual oficial).

## Pendências nomeadas
- CARGA-01: decidir campo p/ Fecha Final Cashback.
- CARGA-02: ativar USD + recarregar demo em USD (ou aceitar CRC até a carga real).
- ~~CARGA-03~~ ✅ DECIDIDO 14/07: chave de integração = **`StockKeepingUnit` (Product SKU, standard)** carregando o código de material SAP; `ProductCode` segue como identidade comercial (OCN+año). Zero campo custom. Nota: Product Class fica **Simple** (grão versão=produto); **Bundle** reservado para os Paquetes SVC (fase servicontratos — é aí que a aba Bundle Components passa a ser usada); Variation Parent/Variation NÃO usados (espec mora no VehicleDefinition).
- CARGA-04: tiers Gerente Venta/Marca → matriz de desconto (com Santiago/D-APR-02).
- CARGA-05 (fase estoque, FORA do escopo catálogo): VehicleDefinition = 1 por versão apontando aos Product2 existentes (gerável dos 223; requer describe do objeto — Q3b); Vehicle = unidades físicas com VIN vindas do extrato de estoque SAP/DMS (nunca da lista de precios). Decisão registrada 14/07: produtos NÃO se carregam no objeto Vehicle — catálogo (Product2) ≠ estoque (Vehicle).
