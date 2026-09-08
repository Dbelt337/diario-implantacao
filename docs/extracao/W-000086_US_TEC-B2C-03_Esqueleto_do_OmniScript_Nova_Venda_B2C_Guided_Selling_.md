# W-000086 — US TEC-B2C-03 — Esqueleto do OmniScript "Nova Venda B2C" (Guided Selling)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 14:56 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-03: Esqueleto do OmniScript "Nova Venda B2C" (Guided Selling)
Narrativa: Como time de implantação, quero o OmniScript backbone da venda guiada B2C com todos os steps e pontos de integração definidos, para as US funcionais plugarem em uma estrutura única.
Escopo técnico:
- Steps na ordem do processo: Identificação/Busca (US-02), Dados Cadastrais (US-03), Endereço + Flag de Débito (US-05), Viabilidade + Crédito em paralelo (US-06/07/09), Carrinho via TEC-01, Faturamento (US-NEW-01), Resumo e Assinatura (US-13).
- Padrão de Integration Procedures não bloqueantes para as chamadas externas, com timeout e fallback definidos por step.
- Botão "Perder Venda" visível em todos os steps até a assinatura (US-06/US-23).
- Persistência de estado entre steps (retomada da venda de onde parou).
Critérios de aceite: navegação completa E2E em sandbox com mocks; cada step com contrato de entrada/saída documentado.
Dependências: TEC-01, TEC-04.

## Critérios de Aceite (related list)

**1. Critério 2** (New)
cada step com contrato de entrada/saída documentado.

**2. Critério 1** (New)
navegação completa E2E em sandbox com mocks.

## Notas de Refinamento e Decisões Registradas

--- COMPLEMENTO DE ARQUITETURA 01/09/2026 (modelagem OmniScript pai/filhos) ---
Estrutura: um OmniScript PAI por jornada (Nova Venda B2C) com um nivel de filhos reutilizaveis, no criterio oficial (processo repetivel entre jornadas vira reusable OmniScript embutido no pai). Filhos: (1) Identificacao do Cliente (busca federada SF + Customer Core, B2C-15; reuso no B2B e no 360); (2) Endereco e Viabilidade (Premises/ServicePoint + TMF645, IP assincrona/continuation; reuso no B2B-02 e MACD); (3) Resumo e Aceite (ESTENDER os OmniScripts existentes bTecParPFSummary/bTecParPFAccept, nao duplicar). Carrinho: STEP DO PROPRIO PAI no padrao Guided Selling sobre as Cart APIs do Industries CPQ via Integration Procedures: postCartsItems (CpqAppHandler, aplica elegibilidade, validacao, pricing e promocoes com atomicidade), getCartsItems, reprice, e checkout (exige ContextId; cadeia Opportunity>Quote>Order>Assets). Pagamento/taxa so vira filho se reutilizado por bot/e-commerce. Performance (Help oficial): limite rigido de 750 elementos por script INCLUINDO os reutilizaveis embutidos (meta interna: manter cada script na casa de 200); uma IP consolidada por step; fire-and-forget para acoes nao bloqueantes; trim de Request e Response JSON; logica no servidor; LWC do OmniScript ate 4 MB; nao atribuir ContextId dentro do script. Roadmap: avaliar Standard Runtime com Enhanced Runtime Performance (Winter 26) e embedding de OmniScript em LWC custom. O POC btpCpq* (sandbox RadarDev) fica apenas como referencia de UX: o Apex BTP_CpqController calcula preco por Decision Matrix propria e aceita valores do navegador no addToCart (DML direto em OrderItem), motor paralelo descartado. Fontes: Omniscript Best Practices (Help xcloud.os_omniscript_best_practices), Guided Selling OmniScript Using CPQ APIs (Help ind.comms), Add Items to Cart / Checkout Items in Cart (developer.salesforce.com, CME guide), release notes Winter 26 (applyPriceAdjustments em Standard Cart APIs).

--- PADRAO DE RESPONSIVIDADE DA JORNADA (04/09) ---
Requisitos de UX obrigatorios do backbone: (1) nenhuma chamada externa sincrona bloqueando step - Integration Procedures non-blocking/chainable com timeout e fallback definidos por step; (2) respostas trimadas (a IP devolve apenas o que a tela consome); (3) step de proposta usa o elemento pub/sub do OmniScript assinando QuoteContractReady__e SOMENTE durante a janela de espera (assina ao entrar no step, desassina ao sair - cada assinatura conta como cliente CometD e consome cota diaria de entrega); (4) estado "em geracao" imediato apos o clique, com fallback de polling leve caso a assinatura caia.
