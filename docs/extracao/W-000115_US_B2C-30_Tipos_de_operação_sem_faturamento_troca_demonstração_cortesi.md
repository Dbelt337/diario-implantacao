# W-000115 — US B2C-30 — Tipos de operação sem faturamento (troca, demonstração, cortesia)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 15:52 por Diego Beltrão de Moraes | Alterado: 08/09/2026 15:52 por Diego Beltrão de Moraes

US B2C (agenda presencial 03/09: ação "Configurar Operações" e tema "Tratamento Contábil e Operacional de Itens com Valor Zero").

NARRATIVA
Como Consultor de Vendas ou Backoffice, quero classificar uma venda ou pedido como Normal, Troca, Demonstração ou Cortesia, para que o sistema saiba quando não gerar fatura, como tratar itens de valor zero e como reportar essas operações separadamente.

CONTEXTO E CENÁRIO DE NEGÓCIO
Existem operações que geram pedido, instalação e ativo, mas não geram cobrança (cortesia comercial, demonstração, troca de equipamento). Hoje isso é tratado manualmente. O TEC-B2C-01 já prevê Record Types de venda (Normal, Cortesia, Swap); falta a regra de negócio de cada tipo e o comportamento em faturamento, contabilidade e relatórios.

REGRAS DE NEGÓCIO
RN-01 Tipos permitidos: Normal, Troca, Demonstração e Cortesia; o tipo é obrigatório e escolhido antes do carrinho.
RN-02 Cortesia e Demonstração: não geram fatura; exigem alçada de aprovação do gestor e prazo máximo definido (demonstração tem data de término obrigatória).
RN-03 Troca: não gera fatura nova; mantém o contrato e o ciclo de faturamento vigentes; gera Work Order e movimenta estoque (baixa e retorno).
RN-04 Itens de valor zero: são permitidos apenas nos tipos Cortesia e Demonstração ou como componente de combo; em venda Normal um item de valor zero fora de combo bloqueia o carrinho.
RN-05 Contabilidade: cortesia e demonstração são enviadas ao ERP com marcação própria para tratamento contábil, mesmo sem cobrança.
RN-06 Conversão: uma demonstração pode virar venda Normal ao término, gerando contrato e fatura a partir daquela data, sem nova instalação.
RN-07 Relatórios: cada tipo é visível separadamente na árvore de perdas e nos indicadores comerciais.

ESPECIFICAÇÃO TÉCNICA
Campo de tipo de operação na Opportunity/Order (Record Type ou picklist, decisão em conjunto com TEC-B2C-01); Approval Process para Cortesia e Demonstração; validação de valor zero no carrinho; flag no payload de handoff ao Customer Core/ERP (W-000088) indicando "não faturar"; scheduled flow para término de demonstração.

DEPENDÊNCIAS E RISCOS
Dependências: TEC-B2C-01 (W-000084); TEC-B2C-05 (W-000088) para o payload; regra contábil validada com o financeiro.
Riscos: uso indevido de cortesia sem alçada; itens zero quebrando integrações de billing que rejeitam valor nulo.

CRITÉRIOS DE ACEITE
Cenário 1: Cortesia aprovada. Dado uma venda marcada como Cortesia, quando aprovada pelo gestor, então o pedido segue para instalação e o handoff vai com a marcação de não faturar.
Cenário 2: Valor zero em venda normal. Dado uma venda Normal, quando um item fora de combo ficar com valor zero, então o carrinho bloqueia.
Cenário 3: Demonstração encerrada. Dado uma demonstração com data de término, quando a data chegar, então o sistema notifica o vendedor e permite converter em venda Normal sem nova Work Order.
Cenário 4: Troca. Dado um pedido de Troca de equipamento, quando concluído, então não há fatura nova, o contrato permanece e o estoque registra saída e retorno.
