# W-000098 — US B2B-03 — Cotação Multi-Site, Alçadas de Desconto/Trading e Geração de Proposta via Document Generator

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 15:08 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[ENTERPRISE CPQ / PROPOSAL & CLM]" do documento "Histórias refinadas B2B".

NARRATIVA DE NEGÓCIO
Como Consultor de Vendas B2B / Gestor de Relacionamento (GR)
Quero montar cotações B2B multi-site, aplicar regras de desconto/trading com aprovação por alçadas e gerar o documento formal de proposta comercial
Para que as negociações corporativas garantam a margem de contribuição, exijam o de acordo formal do cliente e mantenham rastreabilidade total no processo de Quote-to-Contract.
CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2B)
Contexto: Configuração de ofertas no Enterprise CPQ, aplicação de descontos comerciais e degustações (trading), controle de aprovação gerencial compulsória e geração padronizada de propostas formais em PDF/DOCX.
Mapeamento eTOM: 1.2.1.6 Quotation Management, 1.2.1.7 Contract Lifecycle Management.
Regras de Negócio:
[Regra 1: Aprovação Obrigatória de Desconto por 6 Meses] Qualquer concessão de desconto comercial ou aplicação de trading/degustação (período promocional a valor zero configurado via Subscription Type no CPQ) exige aprovação mandatória do Gestor Imediato no Salesforce por um período de maturação operacional de 6 meses, servindo para coleta de métricas e relatórios de auditoria antes da concessão de alçadas autônomas ao vendedor.
[Regra 2: Aceite Formal Obrigatório da Proposta] A apresentação da proposta comercial exige o envio formal e registro do "De Acordo / Aceite" do cliente no sistema. Caso o cliente solicite alterações após o aceite, a cotação atual deve ser abandonada e uma nova cotação clonada criada na Oportunidade.
[Regra 3: Geração de Documentos via DocGen e Alerta de Compras] A proposta técnica/comercial deve ser gerada nativamente via Salesforce Document Generator (DocGen) integrando parâmetros da Quote/Opportunity. Quando a temperatura da Oportunidade atingir 90%, o sistema disparará um alerta automático para a equipe de Suprimentos/Compras para provisionamento preventivo de hardware (CPEs).
ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2B)
Objetos Impactados: Opportunity, Quote, QuoteLineItem, vlocity_cmt__QuoteMember__c, Contract, Document / ContentVersion.
Automação / Front-end: Enterprise CPQ Cart, Advanced Approvals / Approval Process, Salesforce Document Generator (DocGen), Flow de Notificação para Suprimentos (Temperatura 90%).
Integração / APIs TM Forum: TMF648 (Quote Management), TMF651 (Agreement Management).
Segurança e Acessos: Record Lock da Cotação durante o fluxo de aprovação gerencial; Field Level Security (FLS) restritivo para margem financeira e custos de Capex/Opex.
CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Aprovação gerencial de desconto e disparo de alerta para Suprimentos Dado que o GR aplica um desconto de 15% em uma linha de cotação corporativa Quando submete a cotação para aprovação e a temperatura da Oportunidade atinge 90% Então o sistema bloqueia o registro (Record Lock), envia a solicitação de aprovação ao Gestor Imediato e dispara um alerta automático para o setor de Compras para reserva preventivas de CPEs.
Cenário 2: Exigência de Aceite Formal e bloqueio de alteração pós-aceite
Dado que o cliente recebeu a proposta comercial gerada via DocGen
Quando o GR registra o Aceite Formal do cliente no sistema
Então a cotação é congelada contra edições de valores; caso uma renegociação seja necessária, o sistema obriga o abandono desta cotação e a criação de uma nova cotação filha sob a mesma Oportunidade.
ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 13 Story Points (Desenvolvimento de templates DocGen, regras CPQ Advanced Approvals e manipulação de cotações volumosas).
Dependências: Parametrização do Catálogo de Produtos e Subscription Types (CPQ) pelas equipes de Catálogo.
Governor Limits & Edge Cases: Limites de compilação de documentos e tamanho de PDF/ContentVersion no Salesforce; otimização do CPQ Pricing Engine em cotações Large Cart (acima de 100 linhas de produtos).
DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Cobertura de testes unitários mínima de 85% (sem violação de limites de Apex CPU/SOQL).
[ ] Validação E2E no ambiente de Sandbox/QA.
Massa de Teste Sugerida: Cotação Multi-site com 3 Premises; Cotação com produto do tipo Trading (valor zero por 60 dias); Cotação submetida para aprovação por desconto com temperatura em 90%.

Nota de arquitetura BTP: onde a US cita Advanced Approvals, implementar com Approval Process padrão + Record Lock (Advanced Approvals é recurso do Salesforce CPQ SteelBrick, fora do nosso stack). Proposta gerada por Document Generation a partir da Quote aprovada, nunca upload manual.

## Critérios de Aceite (related list)

**1. Cenário 2: Exigência de Aceite Formal e bloqueio de alteração pós-aceite** (New)
Dado que o cliente recebeu a proposta comercial gerada via DocGen
Quando o GR registra o Aceite Formal do cliente no sistema
Então a cotação é congelada contra edições de valores; caso uma renegociação seja necessária, o sistema obriga o abandono desta cotação e a criação de uma nova cotação filha sob a mesma Oportunidade.

**2. Cenário 1: Aprovação gerencial de desconto e disparo de alerta para Suprimentos** (New)
Dado que o GR aplica um desconto de 15% em uma linha de cotação corporativa
Quando submete a cotação para aprovação e a temperatura da Oportunidade atinge 90%
Então o sistema bloqueia o registro (Record Lock), envia a solicitação de aprovação ao Gestor Imediato e dispara um alerta automático para o setor de Compras para reserva preventivas de CPEs.

## Notas de Refinamento e Decisões Registradas

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESCOPO: Onda 1 = B2C venda nova (Avare), ata 03/09; esta work B2B segue em refinamento e entra na onda B2B, a calendarizar.

--- GERACAO DE PROPOSTA NA COTACAO, ASSINCRONA (decisao 04/09) ---
A proposta via DocGen segue a MESMA arquitetura da B2C-25/TEC-B2C-06: gatilho na cotacao, geracao server-side disparada pelo Platform Event QuoteContractRequested__e (consumido pelo MuleSoft) e retorno por QuoteContractReady__e (US TEC-INT-01, W-000105). O clique do GR nunca aguarda a compilacao do PDF. Multi-site: um documento por cotacao com anexo de sites. Campos fiscais por linha (W-000088) ja entram no documento quando aplicavel (contratos estaduais/federais: RS, Banco do Brasil, Caixa).

## Comentários

- Diego Beltrão de Moraes 01/09/2026 15:44: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
- Diego Beltrão de Moraes 01/09/2026 15:47: Epic__c changed from Catálogo Comercial Unificado - B2B/B2C to B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente
