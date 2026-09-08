# W-000085 — US TEC-B2C-02 — Modelagem EPC das Ofertas Comerciais B2C (planos, SVAs, Promotions, taxa)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:50 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-02: Modelagem EPC das Ofertas Comerciais B2C
Narrativa: Como Administrador do Catálogo, quero as ofertas B2C modeladas no EPC (planos por velocidade, SVAs, combos e taxa de ativação), para o carrinho vender apenas ofertas governadas pelo catálogo.
Escopo técnico:
- Product Specs e ofertas comerciais de banda larga por velocidade (herdando as specs da Onda 1 já em EPC-05).
- SVAs/Streaming como produtos avulsos com preço próprio.
- Combos via objeto Promotion (vlocity_cmt__Promotion__c), sem criar produto unificado; desconto como adjustment fixo aplicado na linha do SVA (exigência tributária da US-11); herança do Group Promotion ID para rastreio no BSS/OMS.
- Taxa de Ativação como encargo não recorrente (one-time) obrigatório de R$ 149,90 com edição de preço travada para vendas (US-12; o doc traz 149,90 na regra e 149,99 no critério, pedir confirmação do valor ao negócio).
- Attribute-based pricing por velocidade onde aplicável e jobs de manutenção (compilação já coberta em EPC-09).
Critérios de aceite: combo adiciona os itens com desconto na linha do SVA e valor cheio na internet; taxa entra automática e não editável; Group Promotion ID presente nas linhas.
Dependências: EPC-01/03/04/05/09; confirmação do valor da taxa; lista oficial de SVAs e matriz de preços por velocidade.

## Critérios de Aceite (related list)

**1. Critério 3** (New)
Group Promotion ID presente nas linhas.

**2. Critério 2** (New)
taxa entra automática e não editável.

**3. Critério 1** (New)
combo adiciona os itens com desconto na linha do SVA e valor cheio na internet.

## Notas de Refinamento e Decisões Registradas

--- COMBOS COM VARIACAO DRASTICA DE PRECO (04/09, ata de 03/09) ---
Nuance de precificacao decidida em reuniao: combos cuja variacao de preco entre niveis e expressiva (ex.: internet 600M + Sky Full de R$ 189 por R$ 150) NAO usam desconto generico por atributo - cada combinacao ganha linha dedicada na matriz de preco. A Promotion permanece como mecanismo de agrupamento; o VALOR do beneficio vem do cadastro explicito na matriz. Mapear cada combinacao de combo e SKU de forma dedicada nas tabelas de preco.

--- PRECO POR ZONA E PRAZO DE CONTRATO (decisao 03/09) ---
Complemento de modelagem obrigatorio (nao consta na work): (1) PRECO POR ZONA - uma Price List por macro-segmento (PL_B2C_EVO) e VARIAS Price List Entries por produto, diferenciadas por Pricing Context Rule sobre a dimensao PriceZoneCode (zonas de preco A/B/C, ~40-50 regioes, nivel unico), resolvida a partir do IBGE do endereco via GeographicCommercialPolicy. Zona de PRECO e distinta da zona de DISPONIBILIDADE da QUAL-01 (uma habilita/oculta, a outra precifica). (2) PRAZO DE CONTRATO - atributo de produto (picklist PL_PRAZO_MESES: 12/24/36/48/60, categoria CAT_CONTRATO) usado como dimensao de preco (matriz velocidade x zona x prazo x segmento; fonte: planilha mestre US CAT-TPL-01). (3) CAMADAS - PL do segmento -> PLE da zona -> Promotion (combo) -> Discount contratual. Restricoes documentadas do Digital Commerce: regras de contexto com valores absolutos (sem faixa de CEP), operadores == e != apenas, valores case-sensitive; validar o limite de combinacoes do cache ao gerar a matriz.
