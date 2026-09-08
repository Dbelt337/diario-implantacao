# W-000094 — US B2C-28 — Geração e Despacho de Work Order para Instalação Física B2C (OM + Field Service)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 10:26 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[ORDER MANAGEMENT / FIELD SERVICE]" de 01/09/2026 do documento Histórias Refinadas B2C.

[ORDER MANAGEMENT / FIELD SERVICE] - Geração e Despacho de Ordem de Serviço (Work Order) para Instalação Física B2C
1. NARRATIVA DE NEGÓCIO
Como Sistema de Orquestração (Salesforce Comms Cloud OM) / Plataforma de Workforce
Quero Decompor o pedido de serviços fixos (Banda Larga Residencial/TV) em atividades de campo, criando uma Work Order e despachando-a para o técnico
Para que O técnico de campo (delivery) receba os dados precisos da instalação, vá até a residência do cliente (Person Account) e realize a ativação física do serviço no prazo agendado (SLA), melhorando a satisfação do cliente (CSAT/NPS) e evitando retrabalhos.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2C)
Contexto: Em jornadas de produtos fixos (FTTH, IPTV), o provisionamento não é exclusivamente lógico/sistêmico. Requer a visita física de um técnico na casa do cliente (B2C) para passagem de fibra, instalação de ONT/Modem e configuração do Wi-Fi. O Order Management deve acionar a plataforma de Field Service no momento correto do fluxo de orquestração.
Mapeamento eTOM: 1.2.2.2 Resource Provisioning & Allocation, 1.2.1.5 Service Configuration & Activation (Workforce Management).
Regras de Negócio:
Regra 1 (Gatilho de Despacho): A Ordem de Serviço (WorkOrder) só deve ser despachada ao técnico após a confirmação sistêmica de viabilidade lógica na central (OLT/Splitter) e desde que o agendamento prévio (ServiceAppointment) tenha sido validado no momento do checkout.
Regra 2 (Dados de Campo): O aplicativo do técnico (Field Service Mobile App) deve exibir os dados essenciais do cliente B2C em conformidade com a LGPD: Nome, Endereço de Instalação, Telefone/WhatsApp (mascarado ou via click-to-call) e os Equipamentos (CPEs) previstos na Ordem original.
Regra 3 (Tratamento de Exceção de Campo): Caso o técnico não encontre o cliente (Cliente Ausente) ou haja inviabilidade física (Ex: tubulação obstruída), a plataforma de campo deve retornar o status de falha para o Salesforce OM, gerando uma tarefa de Fallout (Reagendamento ou Cancelamento).
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2C)
Objetos Impactados: Order, vlocity_cmt__OrchestrationPlan__c, vlocity_cmt__OrchestrationItem__c, WorkOrder, WorkOrderLineItem, ServiceAppointment, PersonAccount, Asset.
Automação / Front-end: Auto Task no Orchestration Plan chamando uma Integration Procedure (IP) ou invocável Apex para criar a WorkOrder nativa (via Salesforce Field Service - SFS) ou Callout Task para integração com sistema legado de Workforce/Delivery.
Integração / APIs TM Forum:
TMF646 (Appointment API): Consulta e reserva de janelas no momento da venda (pré-requisito para esta etapa).
TMF652 (Resource Order Management) / TMF641 (Service Ordering): Integração com o sistema externo de despacho e gestão de técnicos (ex: TOA), enviando o payload da atividade de campo.
Segurança e Acessos: Permission Set para SFS_Dispatcher e SFS_Technician (se usar SFS nativo) ou Integration_User_Workforce. Regras de FLS rigorosas aplicadas ao endereço de instalação e contato no objeto PersonAccount para o perfil técnico móvel.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Despacho com Sucesso da Work Order para a Equipe de Delivery (Caminho Feliz)
Dado que um pedido B2C de Banda Larga Residencial (FTTH) atingiu a etapa de "Instalação Física" no Salesforce OM
Quando a Auto/Callout Task de provisionamento de campo for executada pelo sistema
Então uma WorkOrder e um ServiceAppointment associados devem ser criados/atualizados com o status "Dispatched" para a rota do técnico
E o técnico visualiza as informações de endereço e equipamentos da Order no seu dispositivo de campo.
Cenário 2: Fallout no Despacho (Inconsistência de Endereço ou Falta de Janela)
Dado que o sistema de orquestração tenta realizar o callout de despacho para o técnico
Quando o sistema de Field Service retornar um erro de "Área de Risco" ou "Técnico Indisponível" (400 Bad Request / 422 Unprocessable Entity)
Então a task de orquestração no Salesforce OM deve entrar no status "Fatally Failed"
E ser roteada para a fila de Suporte/Backoffice de Delivery para contato proativo com o cliente B2C (reagendamento).
5. ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 8 Story Points (Fibonacci) — Implementação de IPs e mapeamento JSON/Payload complexo entre o modelo do OM (Order) e o modelo do Workforce (WorkOrder / TMF652).
Dependências: Sistema externo de Workforce Management (ex: Oracle TOA, ClickSoftware) ou pacote nativo do Salesforce Field Service (SFS) ativado e configurado.
Governor Limits & Edge Cases: Evitar gargalos (Locks de registro) ao criar WorkOrders massivas em períodos de promoção (Black Friday). As atualizações assíncronas de status vindas do celular do técnico devem ser geridas via eventos de plataforma (Platform Events) ou Callbacks em Bulk para proteger os limites de DML e SOQL.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Fluxo de orquestração (Orchestration Plan) atualizado com a etapa de Field Service.
[ ] IP/Apex ou Callout de integração desenvolvido, validando a conversão de Order para WorkOrder.
[ ] Cobertura de testes unitários mínima de 85%, incluindo classes mock para APIs de Workforce.
[ ] Validação E2E (Status transition de "Dispatched" até "Completed") via API / SFS App.
Massa de Teste Sugerida: Person Account com endereço validado para Fibra (FTTH), pedido de Banda Larga Residencial com agendamento confirmado (janela associada), e status sistêmico apto para despacho (Sem restrição de crédito e porta/CTO reservada logicamente).

Nota de arquitetura: usar o Salesforce Field Service nativo já ativo na org (native first); integração com workforce externo somente se confirmada pela operação. Fundações: TEC-B2C-05 e TEC-B2C-04.

## Critérios de Aceite (related list)

**1. Cenário 2: Fallout no Despacho (Inconsistência de Endereço ou Falta de Janela)** (New)
Dado que o sistema de orquestração tenta realizar o callout de despacho para o técnico
Quando o sistema de Field Service retornar um erro de "Área de Risco" ou "Técnico Indisponível" (400 Bad Request / 422 Unprocessable Entity)
Então a task de orquestração no Salesforce OM deve entrar no status "Fatally Failed"
E ser roteada para a fila de Suporte/Backoffice de Delivery para contato proativo com o cliente B2C (reagendamento).

**2. Cenário 1: Despacho com Sucesso da Work Order para a Equipe de Delivery (Caminho** (New)
Dado que um pedido B2C de Banda Larga Residencial (FTTH) atingiu a etapa de "Instalação Física" no Salesforce OM
Quando a Auto/Callout Task de provisionamento de campo for executada pelo sistema
Então uma WorkOrder e um ServiceAppointment associados devem ser criados/atualizados com o status "Dispatched" para a rota do técnico
E o técnico visualiza as informações de endereço e equipamentos da Order no seu dispositivo de campo.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO COM B2B (decisão pendente) ---
Modelo de endereço: a US B2B-02 usa vlocity_cmt__Premise__c (modelo nativo do pacote para sites), enquanto a jornada em produção usa o modelo custom Endereco__c + Location + Address (origem do incidente de ParentId). Decidir o modelo alvo único de endereço/site para B2B e B2C antes de construir as viabilidades, e planejar convivência ou migração do modelo atual.

--- DECISÃO DE ARQUITETURA 01/09/2026 (substitui a pendência acima) ---
Modelo de site/endereço em dois domínios nativos: (1) domínio comercial/rede usa vlocity_cmt__Premises__c (local de entrega do serviço, geocodificado) + ServicePoint (ponto de rede/porta) para viabilidade, qualificação e carrinho, em B2C e B2B; (2) domínio de execução de campo usa Location + Address padrão (exigência do Field Service), criados/garantidos pela orquestração do OM na etapa de instalação, vinculados 1:1 ao Premise. O objeto custom Endereco__c fica DESCONTINUADO: fase de convivência com de-para (external ID) e carga de migração das cascas existentes; nenhuma função nova nasce nele. Fundamento: definições do data model CME (Premises/ServicePoint) e padrão TM Forum TMF673 (endereço postal) x TMF674 (site de serviço, mapeado para Premises).

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #12) + inventario para a migracao de endereco.
REUSAR: WorkOrder/ServiceAppointment em producao (FlowOrderScheduleInstallation, BTecparFSLAvailabilityController) e o relatorio geral de Field Service existente (Relatrio_Geral_Field_Service_Delivery_RCX).
PARA A DECISAO Endereco__c DESCONTINUADO (ja registrada nesta work): o AS-IS inventaria os componentes a migrar - EnderecoHandler.cls, ExtractPremisesForUpdate, ExtractServiceAccountsByAddress - usar como escopo objetivo da fase de convivencia/migracao.
EVIDENCIA: force-app/main/default/classes/EnderecoHandler.cls | vlocity-backup/DataRaptor/ExtractPremisesForUpdate | vlocity-backup/DataRaptor/ExtractServiceAccountsByAddress.
DIRETRIZ SYSMAP: nenhuma funcao nova nasce em Endereco__c; toda leitura/escrita nova vai para Premises/ServicePoint com de-para por external id.--- ESCOPO DE PRODUTOS NA INSTALACAO (decisao 03/09) ---
Sem IPTV/TV Box no portfolio (somente streaming, sem visita tecnica). A Work Order cobre fibra + CPE/roteador/Wi-Fi e, quando houver, cameras (equipamento com baixa de estoque, 1 a 10 unidades por pedido, servico de nuvem 7/30 dias sem visita adicional). Movel nao gera Work Order (SIM/eSIM, sem aparelho).
