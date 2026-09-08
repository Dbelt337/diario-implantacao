# W-000096 — US B2B-01 — Escalonamento de Inatividade de Leads B2B e Enriquecimento via Econodata e Customer Core

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 15:08 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[LEAD & ACCOUNT MANAGEMENT]" do documento "Histórias refinadas B2B".

NARRATIVA DE NEGÓCIO
Como Consultor de Vendas B2B / SDR / Gestor de Relacionamento (GR)
Quero registrar e qualificar Leads B2B com enriquecimento automático de dados cadastrais/segmentação e regras de escalonamento por inatividade
Para que o funil de prospecção corporativa seja mantido sanitizado, garantindo a rápida conversão de prospects elegíveis e evitando o acúmulo de Leads abandonados.
CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2B)
Contexto: Entrada de prospects B2B por input manual, carga massiva ou integrações (Web-to-Lead, Econodata, QR Code), necessitando de qualificação de CNPJ/KNAI, identificação de grupo econômico e tratamento contra estagnação de atendimento no pipeline.
Mapeamento eTOM: 1.2.1.2 Sales Management, 1.2.1.1 Customer Relationship Management.
Regras de Negócio:
[Regra 1: Regra de Escalonamento por Inatividade] Se o Lead B2B ficar sem interação registrada (tarefas, e-mails, chamadas), o sistema acionará alertas progressivos: 10 dias de inatividade para o Vendedor/GR, 15 dias para o Gestor Imediato, 20 dias para o Diretor/Red, e após 30 dias de inatividade contínua o Lead será alterado automaticamente para o status "Perdido".
[Regra 2: Enriquecimento e Segmentação via Econodata] A validação do CNPJ buscará dados cadastrais e o ramo de atividade (KNAI) na base do Customer Core / Econodata via carga/sincronização diária (evitando dependência de chamadas síncronas bloqueantes), preenchendo automaticamente o Segmento e mapeando árvores de Matriz/Filiais/Grupo Econômico.
[Regra 3: Transição de Status e Motivo de Perda] O Lead nasce por padrão no status "Novo", transita para "Em Contato/Em Andamento" mediante interações, e o status "Perdido" exige o preenchimento obrigatório da lista padronizada de motivos e submotivos (ex: Preço, Concorrência, Sem Orçamento, Inviabilidade), sendo gravado para futuras campanhas de resgate pelo Marketing Cloud.
ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2B)
Objetos Impactados: Lead, Business Account (CNPJ), Contact, Individual Email Message, Task.
Automação / Front-end: Scheduled Apex / Flow Orchestrator para verificação diária de inatividade (LastActivityDate), Flow de Tela para conversão de Lead em Conta/Contato/Oportunidade B2B, FlexCards de visualização de Grupo Econômico.
Integração / APIs TM Forum: TMF622 (Product Order / Customer Onboarding prep), API REST de sincronização noturna do Customer Core/Econodata.
Segurança e Acessos: Sharing Rules baseadas em Carteira de Clientes/Territórios; trava de edição no Lead após marcação de "Perdido" (restrita a Supervisores/Administradores).
CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Escalonamento automático e encerramento por inatividade de 30 dias Dado que existe um Lead B2B ativo sem nenhuma tarefa ou e-mail registrado há 29 dias Quando o job de agendamento diário de inatividade for executado no 30º dia Então o sistema deve alterar o Status do Lead para "Perdido", preencher o Motivo da Perda como "Inatividade - Descarte Automático (30 dias)" e disparar notificação ao Gestor.
Cenário 2: Validação de duplicidade e vínculo de Grupo Econômico no Lead
Dado que o usuário insere um novo Lead informando um CNPJ corporativo
Quando o sistema consulta o Customer Core e identifica que a raiz do CNPJ ou o Grupo Econômico já possui cadastro de Conta ativa
Então o sistema deve exibir um alerta de "Cliente Base / Grupo Econômico Existente" e redirecionar a jornada para a criação de Oportunidade vinculada à Conta existente em vez de um novo Lead.
ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 8 Story Points (Lógica de escalonamento temporizado, manipulação batch de Leads e integração com Customer Core).
Dependências: Disponibilidade da rotina batch de sincronização diária do Econodata/Customer Core.
Governor Limits & Edge Cases: Execução de Batch Apex com tratamento de limites SOQL em grandes volumes de Leads (Database.QueryLocator), prevenindo bloqueios de registro (Record Locks) durante atualização em massa de status.
DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Cobertura de testes unitários mínima de 85% (sem violação de limites de Apex CPU/SOQL).
[ ] Validação E2E no ambiente de Sandbox/QA.
Massa de Teste Sugerida: CNPJ Matriz válido sem conta prévia no Salesforce; CNPJ de Filial com Matriz cadastrada; Lead sem atividade há 9, 14, 19 e 29 dias para validação dos gatilhos de escalonamento.

Nota de arquitetura BTP: escalonamento por inatividade via Scheduled Flow/Batch sobre LastActivityDate; enriquecimento por sincronização batch (sem callout síncrono bloqueante), conforme a própria US.

## Critérios de Aceite (related list)

**1. Cenário 2: Validação de duplicidade e vínculo de Grupo Econômico no Lead** (New)
Dado que o usuário insere um novo Lead informando um CNPJ corporativo
Quando o sistema consulta o Customer Core e identifica que a raiz do CNPJ ou o Grupo Econômico já possui cadastro de Conta ativa
Então o sistema deve exibir um alerta de "Cliente Base / Grupo Econômico Existente" e redirecionar a jornada para a criação de Oportunidade vinculada à Conta existente em vez de um novo Lead.

**2. Cenário 1: Escalonamento automático e encerramento por inatividade de 30 dias** (New)
Dado que existe um Lead B2B ativo sem nenhuma tarefa ou e-mail registrado há 29 dias
Quando o job de agendamento diário de inatividade for executado no 30º dia
Então o sistema deve alterar o Status do Lead para "Perdido", preencher o Motivo da Perda como "Inatividade - Descarte Automático (30 dias)" e disparar notificação ao Gestor.

## Notas de Refinamento e Decisões Registradas

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESCOPO: Onda 1 = B2C venda nova (Avare), ata 03/09; esta work B2B segue em refinamento e entra na onda B2B, a calendarizar.

## Comentários

- Diego Beltrão de Moraes 01/09/2026 15:44: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
- Diego Beltrão de Moraes 01/09/2026 15:47: Epic__c changed from Catálogo Comercial Unificado - B2B/B2C to B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente
