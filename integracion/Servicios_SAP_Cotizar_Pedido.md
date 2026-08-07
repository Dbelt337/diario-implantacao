# Serviços SAP existentes para cotizar e criar pedido (doc do time SAP, sessão 22/07 — recebido 07/08)

Fonte: "Integraciones para cotizar y crear un pedido" (PDF do time SAP/Flavio). **SANITIZADO: credenciais e hosts do documento original NÃO estão aqui e não devem entrar no repo** (recomendado rotacionar a senha do SFTP exposta no PDF). Herança C4C (Cloud for Customer) — validar na tarefa técnica se os payloads têm amarras ao C4C antes de assumir reuso via MuleGateway.

## A. VEÍCULOS — família ZQEV (ciclo Z301/Z300) ⭐
| RFC | Papel | Pluga em |
|---|---|---|
| `ZQEV_ASIG_CLIENTE` | **Pré-requisito obrigatório** antes de qualquer ordem | QuoteOrderService (passo 0) |
| `ZQEV_MONEDA_CLIENTE` | **Pré-requisito obrigatório** (moeda do cliente) | QuoteOrderService (passo 0) |
| `ZQEV_SSA_CREA_ORD_VEH` | Cria a **Z301 = oferta/reserva** | **Reserva Confirmada** → SAP (a interface que o Luis disse que pedirá o CENTRO) |
| `ZQEV_SSA_MOD_ORD_VEH` | Modifica Z301 e Z300 | Alterações de reserva/pedido |
| `ZQEV_SSA_COPIA_ORD_VEH` | Copia **Z301 → Z300 (pedido de venta)** | Fechamento da venda |
| Tabela de preços de veículos no QRM por sociedad (versión, modelo+año: lista, bruto, exonerado, gasto, precio vendedor, precio gerente) | Fonte de preço de veículos | **HU-054 (PRU)** + pricing Venta Guiada |

## B. PA — fluxo standard SD
| Serviço | Papel | Pluga em |
|---|---|---|
| `ZHYB_SD_PARAM_CLIENTE` | Parâmetros do cliente pré-pedido | QuoteOrderService |
| `cod_salesorder_simulate` (SOAP **síncrono**) | **Simulação = preço calculado pelo SD** (impostos/descontos/redondeo do SAP) | **PricingService / HU-028** — paridade de redondeo vem do SAP, SF exibe e congela |
| IDoc `SALESORDER_CREATEFROMDAT2` | Criar pedido (assíncrono) | SapOrderService (ida) |
| IDoc `/ERP/COD/COD_REPLICATE_SALES_ORDER01` + `/ERP/YMKT_SALES_ORDER` | Réplica de ordem/cotización (Quotations-Orders-Returns) | Retorno → padrão SapOrderResponse__e |
| `SalesOrderConfirmationMessage` | Confirmação/fechamento da ordem | idem |
| IDoc `/ERP/COD/MATMAS_CFS_MATMAS05` | Réplica de materiais (catálogo) | MaterialSearchService / HU-039/047 |

## C. REPUESTOS — fluxo DBM (Dealer Business Management)
| RFC | Papel | Pluga em |
|---|---|---|
| `ZHYB_C4C_CONSULTA_MATERIALES` (**tem modo MASSIVO**) / `ZQEV_C4C_CONSULTA_MATERIALES` / `ZQEV_SD_CONSULTA_GENERAL_MAT` | Consulta de materiais 1-a-1 ou em lote | **HU-047 RN-18: a chamada multi-material JÁ EXISTE** |
| **`TDET_SALDOS = PISO − RESERVA` (pode ser NEGATIVO)** | Regra de composição do saldo | **HU-047 RN-12** — pergunta nova ao cliente: exibição de saldo negativo |
| `ZHYB_DBM_COTIZA_REP_RFC` | Cotização de repuestos | HU-028 / contraventaRepuestos |
| `ZHYB_DBM_TEXTO_EXISTENCIA_RFC` | Texto de existência | HU-047 (detalhe de disponibilidade) |
| `ZHYB_DBM_MOD_DET_ORDEN` / `ZHYB_DBMPOSICIONES` | Modificar/consultar posições da ordem | Pedido de repuestos |
| `ZHYB_DBM_DESCUENTO_DE_VENDEDOR` (nota do doc: "validar scheduler em vez de consulta por pedido") | Descontos por vendedor | aprobacionDescuentoModal — decisão de cadência ABERTA |
| `ZHYB_MONEDA_CLIENTE` / `ZHYB_SD_PARAM_CLIENTE` | Pré-requisitos de cliente | passo 0 |

## D. B2C (e-commerce) — avenida separada
Estratégia (Flavio, 22/07): B2C gera XML → deposita em **SFTP** (Marketing Cloud) → MuleSoft lê por scheduler → executa no SAP pedidos + compensação de pagamento. Direções: Precio SAP↔B2C · Catálogo SAP↔B2C · Pedido B2C→SAP. Padrão batch de arquivo — NÃO confundir com o fluxo on-line da Venta Guiada (MuleGateway síncrono/eventos).

## Decisões/perguntas que este doc gera
1. **Reuso via envelope MuleSoft** dos serviços C4C vs construir novos — validar amarras C4C nos payloads (pergunta ao Luis/SAP).
2. **Reserva Confirmada ↔ Z301**: formalizar o mapeamento no desenho da reserva (e o payload pedirá CENTRO, não almacén — gravação do Luis 04/06).
3. **Saldo negativo** (TDET_SALDOS) — comportamento de exibição na HU-047.
4. **Cadência do descuento de vendedor** — scheduler vs por pedido (nota do próprio doc).
5. MATMAS é **05** (não 01) — ajustar referências de catálogo.
6. Simulação como fonte do preço → HU-028: SF exibe/congela, não recalcula waterfall (POC vira validação de payload).


## E. ENCAIXE NO FLUXO DE VENDAS GUIADO (mapeado 07/08)

**Autos/Motos (`ventaVehiculo`)**: unidade ← inventário replicado (HU-047, fora deste doc) → preço ← `PricingService` → `cod_salesorder_simulate` (síncrono, SD calcula, SF congela na QLI) → desconto ← `aprobacionDescuentoModal` → `ZHYB_DBM_DESCUENTO_DE_VENDEDOR` → **Cotización Confirmada = documento só SF (gate OLI)** → **Reserva Confirmada = `QuoteOrderService`/`SapOrderService`: ZQEV_ASIG_CLIENTE + ZQEV_MONEDA_CLIENTE → `ZQEV_SSA_CREA_ORD_VEH` cria Z301** (payload com CENTRO do dealer) → retorno IDoc → `SapOrderResponse__e` → **venta fechada = `ZQEV_SSA_COPIA_ORD_VEH` Z301→Z300** (mods: `ZQEV_SSA_MOD_ORD_VEH`). **Gates HU-025 ↔ documentos SAP 1:1.**

**Repuestos (`contraventaRepuestos`, DBM)**: buscar ← `MaterialSearchService` → CONSULTA_MATERIALES massivo/GENERAL_MAT; saldo ← TDET_SALDOS + TEXTO_EXISTENCIA; cotizar ← `ZHYB_DBM_COTIZA_REP_RFC`; pedido ← MONEDA+PARAM_CLIENTE → MOD_DET_ORDEN/DBMPOSICIONES.

**PA (`ventaPA`, SD standard)**: PARAM_CLIENTE → simulate (preço) → IDoc SALESORDER_CREATEFROMDAT2 → réplicas/confirmação async → `SapOrderResponse__e`.

**3 PERGUNTAS ABERTAS do encaixe**: (1) Usados: família ZQEV/Z301 serve ou há doc type próprio? (2) `ZHYB_DBM_COTIZA_REP_RFC` cria doc no SAP na cotización — confirmar que NÃO compromete estoque (RN-07 HU-047: cotizar no reserva); (3) momento da Z301: Reserva Confirmada (leitura adotada) ou cotización? — "oferta O reserva", negócio decide.
