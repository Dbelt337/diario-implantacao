# W-000083 — US B2C-26 — Guarda de Dados para Abordagens Futuras e Gestão de LGPD

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 08/09/2026 17:57 por Diego Beltrão de Moraes

Referência: US-NEW-03 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

[US-NEW-03] Guarda de Dados para Abordagens Futuras e Gestão de LGPD
1. NARRATIVA DE NEGÓCIO
Como Equipe de Marketing e Relacionamento,
Quero que os dados de leads e oportunidades classificados como "Perdidos" sejam gravados com os motivos específicos e opt-in/opt-out de comunicação,
Para que possamos executar campanhas automatizadas de reengajamento (ex.: quando a área ganhar cobertura de fibra) em total conformidade com a LGPD.
2. CONTEXTO E REGRAS DE NEGÓCIO
Sempre que o funil for interrompido (Viabilidade negativa, recusa de crédito, desistência), os dados de contato (Nome, E-mail, Telefone, CEP) não devem ser deletados. Eles recebem o status "Perdido" e obrigam a escolha de um Motivo. Além disso, uma flag de "Consentimento LGPD para Ofertas" deve ser preenchida (Sim/Não). Caso Sim, os dados entram em jornadas futuras de nutrição.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Lead, Account, Contact, Opportunity.
Automação: Sincronização de campos de Consentimento (Opt-in) via Marketing Cloud Connect.

## Critérios de Aceite (related list)

**1. Cenário 6: Sincronização de consentimento com o Marketing Cloud** (New)
Dado que consentimentos foram criados ou alterados no Salesforce
Quando o sincronismo do Marketing Cloud Connect executar
Então o status de assinante no Marketing Cloud reflete o consentimento por canal, sem divergência entre as plataformas

**2. Cenário 5: Revogação de consentimento (direito do titular)** (New)
Dado que um titular solicita a revogação do consentimento ou a exclusão dos seus dados
Quando o atendimento registra a solicitação
Então o consentimento é atualizado para opt-out cessando as comunicações, e o pedido de exclusão segue o processo de anonimização definido pela empresa, com trilha de auditoria

**3. Cenário 4: Reengajamento por ganho de cobertura** (New)
Dado que uma região com perdas por inviabilidade técnica passou a ter cobertura de fibra
Quando a campanha de reengajamento é criada
Então somente registros Perdidos com motivo de Inviabilidade Técnica e consentimento Sim entram na jornada do Marketing Cloud

**4. Cenário 3: Opt-out respeitado em qualquer jornada** (New)
Dado que o cliente respondeu Não ao consentimento
Quando qualquer audiência de campanha ou jornada de nutrição for montada
Então o registro não é incluído nas audiências de marketing e nenhuma comunicação de oferta é disparada para os pontos de contato dele

**5. Cenário 2: Registro no modelo nativo de consentimento** (New)
Dado que o cliente respondeu Sim ao consentimento para ofertas
Quando o registro é salvo
Então o sistema cria ou atualiza o Individual vinculado ao Lead/Contato e grava o consentimento por canal (ContactPointTypeConsent para e-mail, telefone e SMS) associado ao Data Use Purpose "Ofertas e Reengajamento"

**6. Cenário 1: Retenção de dados e coleta do consentimento no descarte** (New)
Dado que um Lead ou Oportunidade é encerrado como Perdido (inviabilidade, crédito recusado ou desistência)
Quando o operador confirma o encerramento
Então o sistema exige o Motivo da Perda e a resposta da flag Consentimento LGPD para Ofertas (Sim/Não), e os dados de contato (nome, e-mail, telefone, CEP) permanecem gravados, sem exclusão

## Notas de Refinamento e Decisões Registradas

--- COMPLEMENTO DE ARQUITETURA (BTP) ---
Implementar o consentimento com o modelo nativo de Consent Management da plataforma, e não com checkbox custom isolado: Individual (registro de privacidade da pessoa, campo IndividualId em Lead e Contact), ContactPointTypeConsent (consentimento por canal: e-mail, telefone, SMS) e DataUsePurpose (finalidade "Ofertas e Reengajamento"). O modelo nativo é a base consultada pelo Contact Point Filtering e pelas integrações de marketing. Referências: Data Model Privacy Consent e Object Reference ContactPointTypeConsent (developer.salesforce.com). Critérios de aceite definidos pela arquitetura na related list Acceptance Criteria.

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: gap confirmado (matriz #17, confianca baixa no AS-IS - sem automacao e sem base legal definida em producao).
CONSTRUIR: modelo nativo de Consent Management completo, como esta work ja especifica (Individual, ContactPointTypeConsent, DataUsePurpose) - resolve o risco apontado pela consultoria.
DIRETRIZ SYSMAP: projetar somente apos decisao de dados/consentimento formalizada (diretriz da propria matriz); nenhum checkbox custom isolado.
