# Resumo Executivo — Catálogo de Precios & Pedidos Automáticos (DevSales) · 14/07/2026

## O que existe agora na org (números — ATUALIZADO após carga completa 14/07 noite)
- **2 catálogos de preço (pricebooks):** Standard (lista) e **C101 Costa Rica** (comercial). Modelo: 1 pricebook por sociedad (C105 motos preparado).
- **223 produtos — o catálogo de vendas REAL da Costa Rica**: 113 Hyundai + 55 Chevrolet + 45 Isuzu + 10 Cadillac (fontes oficiais: Carga Masiva QRM + ReportesPreciovehiculo, só versões ativas), todos com Business Brand associada e ProductCode canônico (OCN + año).
- **446 entradas de preço**: 223 no Standard + 223 no C101 com os precios de negócio reais (Precio Mínimo Asesor, Exonerado, Exonerado Mínimo, Gastos, Cashback) — carregados por pipeline programático com validação de integridade (21 spot-checks), **zero célula digitada à mão**.
- **7 campos novos de precio na PricebookEntry** (Currency 16,2 / checkbox / data), com **field history ligado** — toda alteração de preço fica auditada (quem, quando, de → para). Acesso controlado pelo permission set `PS_Precios_Catalogo`.
- **2 automações de pedido (flows)**: ao **ganhar** uma oportunidade com cotização sincronizada e aceita, o **pedido (Order) nasce sozinho** em Draft com as linhas copiadas; quando o SAP devolve a **factura** (via integração), o pedido **ativa sozinho** e o vendedor recebe notificação. Exclusão única: RT Mayorista. Falhas nunca quebram a venda — viram Task para o dono.

## Decisões de arquitetura do dia (governança)
1. **Não criar objeto novo**: o objeto "Solicitud Cambio Precios" foi criado e **removido no mesmo dia** por decisão; a auditoria de cambios de precio é feita pelo **field history nativo** da PricebookEntry (a plataforma aceitou — validado por deploy).
2. **Não criar campo custom quando existe nativo**: `Make__c` descartado — o Automotive Cloud já tem `MakeName` no produto (mesma regra que já tinha matado o ChannelCode em favor do LeadSource).
3. **Moeda**: org multicurrency com **CRC** única ativa (fase 1 = CR). A amostra entrou em CRC com valores nominais — para a carga real, a lista de moedas por país decide (valores reais em CRC ou ativar USD antes, se CR precifica em dólar).

## Como será a carga real vinda do SAP (desenho)
**Fluxo em 4 ondas, sempre nesta ordem e sempre idempotente (upsert por chave, nunca insert cego):**
1. **Product2** ← material master SAP: chave `ProductCode` (definir um **External Id** dedicado, ex. `SAP_MaterialCode__c`, para o Mule fazer upsert); marca no campo nativo `MakeName`; Family por línea (Autos/Motos/Repuestos).
2. **PricebookEntry no Standard** (preço de lista) — pré-requisito da plataforma.
3. **PricebookEntry na lista da sociedad** (C101 CR; depois C105 motos, e as demais sociedades no rollout) com os precios de negócio (PMV, Exonerado, Gastos, Cashback, Vigencia).
4. **VehicleDefinition/Vehicle** (estoque físico por VIN, para test drive e reserva de unidad) — pendente do describe do objeto na org.
**Canal:** MuleSoft (mesma malha das integrações L34/L73 de pedidos/facturas) gravando via API com o usuário de integração (PS_Api); a carga demo de hoje validou o caminho manual (Inspector) e o modelo de dados.
**Pendências para essa carga:** extrato de materiais do SAP (planilha modelo), decisão do External Id, decisão de moeda por país, e volume/frequência (full diário vs delta).

## Validado hoje em DevSales
- Deploy dos campos + history + permission set + motores: **verde** (20/20 e pacotes subsequentes).
- Carga demo: 6 produtos + 12 preços **ok** — o preço de lista aparece automaticamente ao cotizar.
- Roteiro E2E pronto (`testes/roteiro_e2e_motores_pedido.md`): cotizar Accent 2025 a 28.900 → ganhar → pedido automático → factura SAP → pedido ativo + notificação. Execução em andamento.

## Próximos passos
1. Executar o E2E dos motores (roteiro pronto) e registrar evidências.
2. Cockpit de venta (OmniScript guiado): esqueleto do pai desenhado; aguarda export do CrearCotizacion (molde) + 4 queries de investigação.
3. Alinhar com o negócio: moeda por país na carga real, External Id do material, e a planilha modelo do catálogo SAP.
