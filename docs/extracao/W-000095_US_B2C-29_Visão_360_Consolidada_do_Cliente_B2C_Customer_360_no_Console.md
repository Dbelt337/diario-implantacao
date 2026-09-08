# W-000095 — US B2C-29 — Visão 360 Consolidada do Cliente B2C (Customer 360 no Console de Atendimento)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 10:26 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[SERVICE CLOUD / OMNISTUDIO]" de 01/09/2026 do documento Histórias Refinadas B2C.

[SERVICE CLOUD / OMNISTUDIO] - Visão 360 Consolidada do Cliente B2C (Customer 360)
1. NARRATIVA DE NEGÓCIO
Como Atendente de Call Center (Inbound) ou Agente de Loja
Quero Visualizar uma interface única (Console) contendo todas as informações relevantes do cliente B2C (dados cadastrais, produtos ativos, status da rede, histórico de faturas, chamados e ofertas pré-aprovadas)
Para que Eu possa resolver a demanda do cliente rapidamente no primeiro contato (First Contact Resolution - FCR), oferecendo um atendimento hiper-personalizado e reduzindo drasticamente o Tempo Médio de Atendimento (AHT).
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2C)
Contexto: Após o onboarding e a ativação dos serviços no Customer Core, o cliente passa a interagir com os canais de atendimento (Service). Atualmente, os operadores precisam navegar por múltiplos sistemas legados (BSS de Faturamento, OSS de Rede, CRM antigo) para entender o status do cliente. A Visão 360 unifica esses silos no Salesforce usando o conceito de Customer Interaction e painéis declarativos (FlexCards).
Mapeamento eTOM: 1.3.1.1 Customer Interaction Management, 1.3.4.1 Customer Information Management, 1.3.8.1 Customer Behavior & Insight.
Regras de Negócio:
Regra 1 (Dados Transacionais em Tempo Real): O saldo de faturas abertas, consumo da franquia de dados (Mobile) e status de conectividade do modem (FTTH) não devem ser armazenados no Salesforce; devem ser consultados em tempo real (via chamada de API ao BSS/OSS) no momento da abertura da conta.
Regra 2 (Privacidade e LGPD): Dados sensíveis da PersonAccount (CPF, número completo do Cartão de Crédito) devem ser mascarados na interface do usuário (ex: ***.***.***-89), com opção de revelação apenas para perfis autorizados mediante auditoria.
Regra 3 (Next Best Action / Ofertas): A interface deve sugerir a melhor ação (ex: Upgrade para Pós-Pago, Compra de Pacote Adicional) baseada no perfil de consumo e propensão à compra, impulsionando upsell/cross-sell.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2C)
Objetos Impactados: PersonAccount, Asset, vlocity_cmt__Subscription__c, Case, Order, vlocity_cmt__CustomerInteraction__c.
Automação / Front-end: Console App do Service Cloud estruturado com OmniStudio FlexCards (Profile Card, Billing Card, Asset/Subscription Card, Open Tickets Card). Integration Procedures (IPs) orquestrando DataRaptors (Extração interna) e chamadas HTTP (Sistemas Legados).
Integração / APIs TM Forum:
TMF629 (Customer Management API): Para verificação e atualização de dados de contato do cliente no sistema core.
TMF678 (Customer Bill Management API): Consulta on-demand do histórico de faturas e código de barras/PIX para pagamento.
TMF637 (Product Inventory API): Verificação de status de rede e estado comercial da assinatura (ex: Suspenso por Fraude, Ativo, Bloqueado).
Segurança e Acessos: Perfis B2C_CallCenter_Agent e B2C_Store_Agent. Compartilhamento (OWD) configurado como Private para Contas. Field-Level Security (FLS) restrito nos campos de identificação governamental e dados de pagamento.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Carregamento com Sucesso da Visão 360 (Caminho Feliz)
Dado que o atendente busca o cliente por CPF, Número de Telefone (MSISDN) ou Nome
Quando o atendente clica no registro da PersonAccount para abrir o painel de atendimento (Customer 360 Console)
Então os FlexCards carregam e exibem com sucesso: Dados Pessoais mascarados, Status de Assinaturas (Assets), Histórico de Interações, Faturas Recentes (TMF678) e Chamados (Cases) em aberto.
Cenário 2: Tratamento de Timeout na Integração de Faturas (Resiliência UI)
Dado que a Visão 360 está sendo carregada para um cliente
Quando o sistema de Billing (BSS Core) apresentar instabilidade, demorando mais de 5 segundos para retornar via API (TMF678)
Então o Salesforce não deve travar a tela ou apresentar "Apex Error"
E o FlexCard de Faturamento deve renderizar um estado de erro amigável ("Falha ao carregar faturas momentaneamente") com um botão de "Tentar Novamente", permitindo que o atendente continue visualizando os outros componentes da conta (Assets, Cases).
5. ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 8 Story Points (Fibonacci) — Implementação centrada na construção de UI declarativa via FlexCards e orquestração de APIs via Integration Procedures (IP), sem necessidade de código Apex complexo.
Dependências: Estabilidade dos microsserviços legados expostos no Barramento de Integração (API Gateway/MuleSoft) para consulta de Billing e Network Usage.
Governor Limits & Edge Cases: Risco de atingir Concurrent API Requests Limit em operações de Call Center de alto tráfego. Mitigação: Habilitar Lazy Loading (carregamento sob demanda) nos FlexCards secundários (ex: Faturas mais antigas) para evitar que a IP dispare múltiplos Callouts simultâneos no page load (OnLoad) inicial da conta.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] FlexCards desenvolvidos com padrão de interface corporativa (Lightning Design System - SLDS).
[ ] Integration Procedures testadas lidando com retornos de sucesso e erros (Mocks implementados).
[ ] Testes unitários para classes Apex auxiliares (se houver) com 85% de cobertura.
[ ] Navegação completa testada dentro do Service Console (sem refresh indesejado da página).
Massa de Teste Sugerida: Person Account válida (CPF) contendo 1 Asset de Banda Larga (FTTH), 2 Assets de Linha Móvel (Postpaid), no mínimo 1 Case em aberto (Reclamação) e histórico mockado de 3 meses de faturas pagas e 1 pendente.

Nota de arquitetura: consultas de fatura, consumo e status de rede em tempo real via Integration Procedures (sem persistir no Salesforce), com lazy loading nos FlexCards secundários. Fundações: TEC-B2C-04 e TEC-B2C-07.

## Critérios de Aceite (related list)

**1. Cenário 2: Tratamento de Timeout na Integração de Faturas (Resiliência UI)** (New)
Dado que a Visão 360 está sendo carregada para um cliente
Quando o sistema de Billing (BSS Core) apresentar instabilidade, demorando mais de 5 segundos para retornar via API (TMF678)
Então o Salesforce não deve travar a tela ou apresentar "Apex Error"
E o FlexCard de Faturamento deve renderizar um estado de erro amigável ("Falha ao carregar faturas momentaneamente") com um botão de "Tentar Novamente", permitindo que o atendente continue visualizando os outros componentes da conta (Assets, Cases).

**2. Cenário 1: Carregamento com Sucesso da Visão 360 (Caminho Feliz)** (New)
Dado que o atendente busca o cliente por CPF, Número de Telefone (MSISDN) ou Nome
Quando o atendente clica no registro da PersonAccount para abrir o painel de atendimento (Customer 360 Console)
Então os FlexCards carregam e exibem com sucesso: Dados Pessoais mascarados, Status de Assinaturas (Assets), Histórico de Interações, Faturas Recentes (TMF678) e Chamados (Cases) em aberto.

## Notas de Refinamento e Decisões Registradas

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESPECIFICO: faturas, status de rede e dados cadastrais vem dos endpoints proprietarios do Customer Core, com timeout curto e carregamento assincrono por painel (o cenario ">5 segundos" ja previsto vale para todos os paineis).
