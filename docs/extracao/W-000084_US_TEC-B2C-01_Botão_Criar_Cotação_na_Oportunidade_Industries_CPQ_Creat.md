# W-000084 — US TEC-B2C-01 — Botão "Criar Cotação" na Oportunidade (Industries CPQ Create Cart)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:50 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-01: Botão "Criar Cotação" na Oportunidade (Industries CPQ)
Narrativa: Como Vendedor B2C, quero acionar um botão na Oportunidade que crie a Cotação já contextualizada e abra o carrinho do Industries CPQ, para iniciar a montagem da oferta sem navegação manual.
Escopo técnico:
- Quick Action/LWC na Opportunity que invoca OmniScript ou Integration Procedure chamando a Cart-Based API Create Cart (interface CpqAppHandler) com header object Quote, herdando Account e Opportunity.
- Seleção/atribuição automática da Price List conforme contexto da venda (segmento, canal, empresa do grupo); se houver uma única elegível, aplicar sem perguntar.
- Passagem do contexto de qualificação (tetra-pé: Mercado, Canal, Tipo de Cliente, Cidade IBGE) e do endereço de instalação validado para o carrinho, para o filtro de elegibilidade da QUAL-01 atuar.
- Regras de visibilidade: botão disponível apenas em estágios anteriores à assinatura e para Record Types de venda (Normal, Cortesia, Swap).
- Tratamento de erro amigável (conta inativa, sem price list elegível, oportunidade sem endereço qualificado).
Critérios de aceite:
1. Dado uma Oportunidade qualificada, quando o vendedor clica em "Criar Cotação", então a Quote é criada vinculada à Opp e o carrinho abre com o catálogo filtrado pelo contexto.
2. Dado uma Oportunidade sem viabilidade confirmada, quando o vendedor clica no botão, então o sistema bloqueia com mensagem orientando concluir a qualificação.
3. Dado que já existe cotação ativa na Opp, quando o vendedor clica no botão, então o sistema pergunta se deseja abrir a existente ou criar nova versão.
Dependências: QUAL-01 (contexto tetra-pé), TEC-02 (ofertas modeladas), definição de price lists.

## Critérios de Aceite (related list)

**1. Critério 3** (New)
Dado que já existe cotação ativa na Opp, quando o vendedor clica no botão, então o sistema pergunta se deseja abrir a existente ou criar nova versão.

**2. Critério 2** (New)
Dado uma Oportunidade sem viabilidade confirmada, quando o vendedor clica no botão, então o sistema bloqueia com mensagem orientando concluir a qualificação.

**3. Critério 1** (New)
Dado uma Oportunidade qualificada, quando o vendedor clica em "Criar Cotação", então a Quote é criada vinculada à Opp e o carrinho abre com o catálogo filtrado pelo contexto.

## Notas de Refinamento e Decisões Registradas

--- COMPLEMENTO DE ARQUITETURA 01/09/2026 (motor nativo obrigatorio) ---
O botao Criar Cotacao abre o OmniScript pai Nova Venda B2C (TEC-B2C-03) com o carrinho no padrao Guided Selling sobre as Cart APIs (CpqAppHandler). Preco, elegibilidade e promocao SEMPRE calculados no servidor pelo motor do Industries CPQ; nenhum valor monetario aceito do front. O POC btpCpq* da sandbox RadarDev nao segue para produto (pricing paralelo em Decision Matrix propria e addToCart aceitando totais do navegador).

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #7).
REUSAR: criacao de pedido/carrinho em producao - BTecPar_PFCreateOrder (CPQAppHandler.createCart) e CPQ_CreateWorkingCart.
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecPar_PFCreateOrder | vlocity-backup/IntegrationProcedure/CPQ_CreateWorkingCart.
CONSTRUIR: o botao/Quick Action, a passagem do contexto tetra-pe e a selecao automatica de price list.
DIRETRIZ SYSMAP: invocar a cadeia createCart existente a partir do botao; nao criar segundo caminho de criacao de carrinho.

--- CONTEXTO DE PRECO NO CREATE CART (decisao 03/09) ---
Alem do tetra-pe, o Create Cart deve receber PriceZoneCode (derivado do IBGE do endereco de instalacao qualificado) no contexto de precificacao. Se a zona de preco nao for resolvida, bloquear com mensagem amigavel (mesmo padrao dos demais erros desta work), pois sem zona o carrinho precificaria pela PLE default.
