# W-000097 — US B2B-02 — Endereçamento Geocodificado, Viabilidade Expressa e Roteamento de Pré-Projeto Técnico

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 15:08 por Diego Beltrão de Moraes | Alterado: 01/09/2026 16:49 por Diego Beltrão de Moraes

Referência: US "[ENTERPRISE CPQ / FEASIBILITY]" do documento "Histórias refinadas B2B".

NARRATIVA DE NEGÓCIO
Como Engenheiro de Soluções / Arquiteto de Soluções / Gestor de Relacionamento (GR)
Quero realizar a validação de endereço com geocodificação (Latitude/Longitude) e executar a análise de viabilidade técnica por site corporativo
Para que cotações de prateleira sigam diretamente via Viabilidade Expressa e projetos complexos ou com alto volume de locais sejam roteados automaticamente para a raia de Pré-Projeto Técnico, prevenindo erros de instalação e gargalos operacionais.
CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2B)
Contexto: Validação de viabilidade de rede fixa/dedicada por Premise/Site, integrando motores de viabilidade (Ozmap/Mapa de Calor) e estabelecendo regras de triagem entre vendas de prateleira e arquitetura customizada.
Mapeamento eTOM: 1.2.1.5 Service Qualification, 1.2.1.4 Order Handling.
Regras de Negócio:
[Regra 1: Geocodificação Obrigatória] A inclusão do endereço de instalação (Premise) exige a captura ativa de Latitude e Longitude via API de mapas ou marcação manual (Pin Drop) antes de disparar a verificação de viabilidade técnica.
[Regra 2: Gatilho de Roteamento para Pré-Projeto/Arquitetura] Produtos padronizados de prateleira (Viabilidade Expressa) dispensam aprovação manual da Arquitetura, EXCETO quando a cotação contiver mais de 20 viabilidades expressas no mesmo pedido (ex: grandes contas/LPU multi-site) ou contiver produtos customizados, o que torna obrigatório o direcionamento para a fila de Pré-Projeto Técnico.
[Regra 3: Requisitos Obrigatórios de Escopo] Solicitações enviadas à Arquitetura exigem o preenchimento do campo de texto rico "Descritivo da Necessidade do Cliente" e tipo de link (dedicado, banda larga, MPLS, rede própria/terceiros), mantendo upload de anexos (TR/RFP/Topologia) como campos opcionais de suporte.
ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2B)
Objetos Impactados: Opportunity, Quote, QuoteLineItem, vlocity_cmt__Premise__c, vlocity_cmt__ServiceAccount__c, Task.
Automação / Front-end: OmniScript de Venda Guiada (Guided Selling), Integration Procedure para chamada ao Motor de Viabilidade, LWC de Geocodificação, Trava de Estágio (Validation Rule).
Integração / APIs TM Forum: TMF645 (Service Qualification), API REST externa do Motor de Viabilidade / Ozmap.
Segurança e Acessos: Permissão de edição do catálogo e dados técnicos restrita aos perfis de "Arquiteto de Soluções" e "Pré-Vendas".
CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Viabilidade Expressa aprovada automaticamente para cotação simples
Dado que o GR configura uma cotação com 5 pontos de instalação de link padronizado de prateleira com coordenadas geográficas validadas
Quando dispara a ação "Verificar Viabilidade"
Então o sistema executa a consulta via API TMF645, recebe o retorno positivo e avança automaticamente a Cotação para o estágio "Proposta Comercial", sem passar pela fila da Arquitetura.
Cenário 2: Envio compulsório para Pré-Projeto por volume superior a 20 sites Dado que o GR configura uma Cotação B2B contendo 25 pontos de instalação de Viabilidade Expressa Quando clica em "Solicitar Viabilidade" Então o sistema identifica que a quantidade de sites excede o limite de 20 pontos, altera o estágio para "Pré-Projeto Técnico", bloqueia a edição comercial e cria uma tarefa na fila do time de Arquitetura de Soluções.
ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 13 Story Points (Complexidade de integração TMF645, processamento de múltiplos Premises em Large Carts e lógica de roteamento).
Dependências: Motor de Viabilidade (Ozmap/API de mapas) ativo e responsivo em ambiente de produção.
Governor Limits & Edge Cases: Chamadas HTTP assíncronas (Continuation/Queueable) para evitar timeouts de requisição na validação de múltiplos locais e ultrapassagem do limite de 100 callouts por transação Apex.
DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Cobertura de testes unitários mínima de 85% (sem violação de limites de Apex CPU/SOQL).
[ ] Validação E2E no ambiente de Sandbox/QA.
Massa de Teste Sugerida: Cotação B2B com 1 Premise viável; Cotação com 21 Premises em lote; Cotação com produto customizado exigindo preenchimento de Descritivo de Necessidade.

Nota de arquitetura BTP: TMF645 é API consumida do motor de viabilidade externo (Ozmap), o Salesforce é cliente. Callouts assíncronos (Continuation/Queueable) para lotes de sites.

## Critérios de Aceite (related list)

**1. Cenário 2: Envio compulsório para Pré-Projeto por volume superior a 20 sites** (New)
Dado que o GR configura uma Cotação B2B contendo 25 pontos de instalação de Viabilidade Expressa
Quando clica em "Solicitar Viabilidade"
Então o sistema identifica que a quantidade de sites excede o limite de 20 pontos, altera o estágio para "Pré-Projeto Técnico", bloqueia a edição comercial e cria uma tarefa na fila do time de Arquitetura de Soluções.

**2. Cenário 1: Viabilidade Expressa aprovada automaticamente para cotação simples** (New)
Dado que o GR configura uma cotação com 5 pontos de instalação de link padronizado de prateleira com coordenadas geográficas validadas
Quando dispara a ação "Verificar Viabilidade"
Então o sistema executa a consulta via API TMF645, recebe o retorno positivo e avança automaticamente a Cotação para o estágio "Proposta Comercial", sem passar pela fila da Arquitetura.

## Notas de Refinamento e Decisões Registradas

--- DECISÃO DE ARQUITETURA 01/09/2026 (substitui a pendência acima) ---
Modelo de site/endereço em dois domínios nativos: (1) domínio comercial/rede usa vlocity_cmt__Premises__c (local de entrega do serviço, geocodificado) + ServicePoint (ponto de rede/porta) para viabilidade, qualificação e carrinho, em B2C e B2B; (2) domínio de execução de campo usa Location + Address padrão (exigência do Field Service), criados/garantidos pela orquestração do OM na etapa de instalação, vinculados 1:1 ao Premise. O objeto custom Endereco__c fica DESCONTINUADO: fase de convivência com de-para (external ID) e carga de migração das cascas existentes; nenhuma função nova nasce nele. Fundamento: definições do data model CME (Premises/ServicePoint) e padrão TM Forum TMF673 (endereço postal) x TMF674 (site de serviço, mapeado para Premises).

## Comentários

- Diego Beltrão de Moraes 01/09/2026 15:44: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
- Diego Beltrão de Moraes 01/09/2026 15:47: Epic__c changed from Catálogo Comercial Unificado - B2B/B2C to B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente
