# -*- coding: utf-8 -*-
# Extração do Agile Accelerator (agf__ADM_Work__c), 24/08/2026, via Salesforce Inspector.
# Texto de agf__Details__c limpo de artefatos de aspas duplicadas do import.

COMMON = {
    'status': 'New', 'sprint': '', 'product_tag': 'Salesforce', 'team': 'SysMap',
    'points': '', 'assignee': 'Davi Israel de Abreu', 'tipo': 'User Story',
    'created_by': 'Diego Beltrão de Moraes', 'modified_by': 'Diego Beltrão de Moraes',
    'modified': '2026-08-21T20:34:54',
}

EPIC_B2C = 'B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente'
EPIC_CAT = 'Catálogo Comercial Unificado - B2B/B2C'

WORKS = [
{
 'id': 'W-000056',
 'subject': 'US QUAL-01 (P) — Qualificação de catálogo de ofertas comerciais via contexto de elegibilidade (Tetra-pé)',
 'epic': EPIC_CAT, 'created': '2026-08-19T22:13:26',
 'details': '''Como Consultor de Vendas ou Cliente da jornada de autosserviço (E-commerce/App),
quero que o motor de regras do Salesforce filtre dinamicamente as ofertas do catálogo usando o contexto de qualificação Tetra-pé — Mercado/Segmento, Canal de Venda, Tipo de Cliente (CPF/CNPJ) e Cidade (código IBGE) —
para que apenas as opções elegíveis ao perfil e localização sejam exibidas, sem duplicação de ofertas por contexto.

ESTRUTURA DE CATÁLOGOS DESTA WORK (Manual v2.2 §9.1): catálogos por mercado — CAT_B2C_EVO, CAT_B2S_EVO, CAT_B2B_EVO, CAT_B2G_EVO, CAT_WHOLESALE_EVO. Famílias (Internet, TV, Streaming etc.) são Categorias de navegação dentro dos catálogos, não catálogos próprios. Proibido catálogo por canal (§28.3) e por família. Publicação N:N: a mesma oferta pode estar em múltiplos catálogos. CAT_B2G_EVO não é publicado no e-commerce (venda assistida apenas; CreditPolicyCode = CREDIT_NOT_REQUIRED, sem análise de crédito).

ESCOPO PARCIAL DESTA WORK: criar os 5 catálogos, as categorias por família e os Rule Sets globais de qualificação (máx. 4, reutilizáveis — QUAL_MERCADO, QUAL_CANAL, QUAL_TIPO_CLIENTE, QUAL_CIDADE), aplicados a Products e Promotions. A resolução cidade→zona usa a GeographicCommercialPolicy (P-17, modelo do §37.2). Os domínios de valores de mercado, canal e segmento aguardam formalização do Joel (P-19) — entram como "a confirmar". Diferenciação de preço B2C/B2B via Price Lists separadas (PL_B2C_EVO, PL_B2B_EVO), produto único no catálogo.

Dependências: P-19 (domínios de qualificação — Joel); P-17 (solução técnica IBGE); EPC-01/EPC-04 (estrutura base). Não depende da EPC-02 (picklists de produto).

Fonte: US original "Qualificação de Catálogo de Ofertas Comerciais via Contexto de Elegibilidade (Tetra-pé)"; Manual v2.2 §9, §14.2, §28.3, §37.''',
},
{
 'id': 'W-000057',
 'subject': 'US B2C-01 — Captura, Triagem, Roteamento Omni-Channel e Regras de Condomínio',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:11:31',
 'details': '''Como Consultor de Vendas, Atendente (AR/Central) ou Agente de Backoffice
Quero realizar a captura de leads com restrição de input manual a perfis autorizados, validação cadastral obrigatória e atribuição automatizada da Unidade Operacional
Para que a triagem de duplicidades e o roteamento Omni-Channel ocorram de forma assertiva por skill/região, eliminando entradas inconsistentes no funil comercial.

SOLUÇÃO TÉCNICA (inventário do org 19-20/08, native-first): captura na página padrão de Lead com Dynamic Forms + validation rules — sem LWC. REUSO: Lead já tem AddressNumber__c, AddressComplement__c, Neighborhood__c, DocumentNumber__c (CPF/CNPJ), LegalEntityType__c, CNAE__c e RT B2C; flows LeadGetAddress/Address_Get_Infos (CEP — estender para gravar IBGE, o ViaCEP já devolve) e Get_CNPJ_Details; VRs de qualidade já construídas e INATIVAS (ValidaCPFeCNPJ, DocumentValidation, PhoneValidationFormat) — reativar/ajustar antes de criar novas.
CONSTRUIR: Lead.IsCondominium__c, Block__c, ApartmentUnit__c, IBGECode__c, OperationUnit__c/Regional__c (espelhando Opportunity.OperationUnit__c existente); objeto CEPOperationUnit__c (de-para CEP→unidade, mantido pelo Backoffice); Matching Rule custom Lead×Account por DocumentNumber__c (hoje só standard); filas de Lead + Omni-Channel com skills (Lead.assignmentRules hoje VAZIO — roteamento é greenfield).

Dependências: eleger fonte única de Canal de Entrada (hoje 3 casas: Account.EntryChannel__c, objeto EntryChannel__c, vlocity_cmt__OriginatingChannel__c); Person Account [CONFIRMAR]; de-para CEP×Unidade (negócio); licenças Omni por perfil de venda.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-01.''',
},
{
 'id': 'W-000058',
 'subject': 'US B2C-02 — Análise de Viabilidade Técnica no Lead e Oferta Móvel Obrigatória',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:12:55',
 'details': '''Como Consultor de Vendas B2C
Quero executar a análise de viabilidade técnica e ser direcionado obrigatoriamente para a Oferta Móvel em caso de inviabilidade
Para que eu identifique precocemente a disponibilidade de rede fixa e converta o cliente para serviços móveis antes de registrar a perda do contato.

SOLUÇÃO TÉCNICA: Integration Procedure de viabilidade no padrão TMF679 (certificado no Communications Cloud) contra o GIS/Ozimap. REUSO: gravar o Premises no campo EXISTENTE Lead.vlocity_cmt__PremisesId__c; Premises__c/ServicePoint__c zerados com hook PremisesInterface ativo (adoção limpa); inviabilidade converte para o RT EXISTENTE vlocity_cmt__MobilePhoneOpportunity.
CONSTRUIR: Lead.ViabilityStatus__c (Viável/Inviável/Exceção), CTO__c, PortReservationToken__c, MobileOfferRejected__c; criação on-demand de Premises (chave CEP+número+IBGE) e ServicePoint (tecnologia, CTO, token); VR que bloqueia perda por inviabilidade sem MobileOfferRejected__c = TRUE.

Dependências: API GIS/inventário; dono do SLA de expiração do token (rede, não Salesforce); tratamento de exceção regional >200 m (Engenharia).

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-02.''',
},
{
 'id': 'W-000059',
 'subject': 'US B2C-03 — Análise de Risco',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:14:10',
 'details': '''Como Consultor de Vendas B2C ou Analista de Crédito
Quero realizar a análise de crédito automatizada (com réguas de escore associadas ao Canal de Entrada) e encaminhar solicitações para a Mesa de Crédito
Para que a empresa estabeleça travas de segurança contra fraudes e inadimplência crônica sem comprometer a fluidez das vendas comerciais.

SOLUÇÃO TÉCNICA: régua canal→score→taxa→limite em Decision Matrix (BRE licenciado e habilitado), editável pela Mesa sem deploy. REUSO: fila CreditTable EXISTE (hoje atende Order — adicionar Lead aos objetos suportados); score corrente no campo EXISTENTE Account.vlocity_cmt__CreditScore__c; framework de log de integração do Lead (IntegrationStatus__c/Attempts__c/Error__c) para Serasa/Customer Core.
CONSTRUIR: objeto CreditAnalysis__c (Lead__c/Opportunity__c, Score__c, Bureau__c, ConsultedAt__c, InternalDebts__c, ContractsWithoutFirstPayment__c, Result__c) — um registro por consulta, snapshot auditável; flow pós-consulta decide rota (>= limite → Mesa); FLS restrita — vendedor vê só Result__c.

Dependências: API "contratos sem 1ª parcela" no Customer Core; score exatamente no corte (350/380) [DEFINIR — pendência herdada da Política de Crédito]; mesma fonte de canal da W-B2C-01.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-03.''',
},
{
 'id': 'W-000060',
 'subject': 'US B2C-04 — Sinalização de Débito no Endereço (Flag/Relatório) e Histórico sem Trava Impeditiva',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:15:53',
 'details': '''Como Vendedor e Analista de Compliance
Quero que o sistema identifique se o endereço de instalação possui histórico de débitos ou reincidência de inadimplência (cruzando CEP, número e vínculos) e exiba uma sinalização visual (Flag) sem bloquear a venda
Para que o atendimento comercial siga de forma fluída e as propostas realizadas em locais inadimplentes sejam consolidadas em relatórios estratégicos pós-venda para análise de risco.

SOLUÇÃO TÉCNICA: consulta de histórico do endereço na MESMA viagem da viabilidade (W-B2C-02); chave CEP + número + IBGE — nunca complemento. Sem trava e sem alçada (requisito explícito). REUSO: modelo Endereco__c + Address + junção EnderecoUtilizadoOpportunity__c; Reports nativos.
CONSTRUIR: Opportunity.AddressDebtFlag__c (Checkbox) + AddressDebtSummary__c (Long Text com o resumo da API); FlexCard de alerta na jornada; relatório "Vendas Concluídas em Endereços Inadimplentes" (acesso: coordenadores/gerentes).

Dependências: API de histórico de inadimplência por endereço no Customer Core (dono: TI). Consolidação: substitui as DUAS histórias duplicadas do refinamento original (H4 e H8).

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-04.''',
},
{
 'id': 'W-000061',
 'subject': 'US B2C-05 — Painel de Controle de Vendas Travadas e Gestão de Perdas Segregada',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:16:50',
 'details': '''Como Gerente Comercial, Coordenador B2C e Vendedor
Quero visualizar um Painel de Controle (Dashboard) de oportunidades paradas no fluxo e registrar os motivos de perda com segregação entre Leads e Oportunidades
Para que a equipe gerencial execute intervenções ativas de resgate e o marketing analise com precisão as causas de perda em cada estágio do funil.

SOLUÇÃO TÉCNICA — SANEAMENTO ANTES DE CONSTRUÇÃO: a Opportunity tem LossReason__c E Loss_Reason__c DUPLICADOS (escolher um, migrar dados, aposentar o outro); o Lead usa LossType__c (picklist) + LossReason__c (texto) — nomenclatura INVERTIDA em relação à Opportunity, documentar nas automações. REUSO: VR LossReasonRequired ativa; ações Lead.LossLead, Opportunity.LossOpportunity e CancelRecordAndRelateds; flows CancelLeads/ModifyLostLead/CancelOpportunity_B2B; OWD da Opportunity é Private — visibilidade hierárquica dos dashboards é nativa (Role Hierarchy). Lead é Public Read: visibilidade restrita para Lead sai por filtro de relatório, não por OWD.
CONSTRUIR: Opportunity.StageEnteredAt__c + flow de carimbo na troca de fase (base do tempo-na-etapa); dashboards por papel; trava do botão de perda pós-assinatura = mecânica da W0382 sobre IsContractSigned__c.

Dependências: árvores de motivos validadas pelo comercial BTP.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-05.''',
},
{
 'id': 'W-000062',
 'subject': 'US B2C-06 — Tipo de Negociação no Início da Oportunidade e Segmentação B2C/B2S por Ticket Médio',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:19:23',
 'details': '''Como Vendedor B2C e Administrador do Catálogo (CPQ)
Quero selecionar o Tipo de Negociação no início da criação da Oportunidade e ter a segmentação automática entre B2C e B2S aplicada no carrinho por Ticket Médio
Para que o sistema direcione o fluxo correto (Normal, Cortesia ou Swap) e carimbe automaticamente a categoria comercial sem intervenção manual do operador.

SOLUÇÃO TÉCNICA (native-first): REUSAR NegotiationType__c ("Tipo negociação", picklist EXISTENTE na Opportunity) para Normal/Cortesia/Swap em vez dos Record Types novos da especificação original — RT novo replica páginas/perfis/automações; tradeoff a registrar com o negócio. VERIFICAR os campos EXISTENTES Quote.MarketSegment__c e Quote.MarketType__c antes de criar Opportunity.Segment__c — a segmentação pode já ter casa. Cálculo no reprice do carrinho Vlocity (price rule/pricing plan do pacote, não SF CPQ): total < R$ 800 → B2C; >= R$ 800 → B2S; recálculo a cada alteração do carrinho; Segment no payload de ordem (MuleSoft → Customer Core/ERP).

Dependências: aprovação do negócio para picklist vs Record Type; levantamento dos valores atuais de MarketSegment__c/MarketType__c.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-06.''',
},
{
 'id': 'W-000063',
 'subject': 'US B2C-07 — Regra de Reagendamento e Cancelamento de Instalação por Insucesso de Contato (72h / 3 Tentativas)',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:20:19',
 'details': '''Como Despachante de Field Service e Agente de Backoffice
Quero que o sistema controle as tentativas de contato para agendamento de instalação, transferindo a ordem para o Backoffice após 3 tentativas sem sucesso e cancelando a proposta após 72 horas
Para que as agendas das equipes técnicas de campo não fiquem bloqueadas com ordens ociosas e as propostas inativas sejam limpas do pipeline.

SOLUÇÃO TÉCNICA: REUSO do FSL licenciado e em produção (Dispatcher 324, Scheduling 878, Mobile 1.107 usuários) + cancelamento em cascata EXISTENTE (CancelRecordAndRelateds, Cancell_WO_SA) + reagendamento EXISTENTE (Order.NovoAgendamento, SA_Auto_Schedule, FlowOrderScheduleInstallation).
CONSTRUIR: WorkOrder.ContactAttempts__c (Number) + ação de registro de tentativa com flow contador; na 3ª tentativa → owner = fila "Backoffice Comercial B2C" (criar) + TransferredToBackofficeAt__c (DateTime); scheduled flow diário (batch controlado): >= 72h na fila → CancelRecordAndRelateds com motivo "Cancelado - Insucesso de Contato em 72h" (valor novo na árvore da W-B2C-05).

Dependências: validação dos gatilhos de tentativa com a gestão de Delivery.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-07.''',
},
{
 'id': 'W-000064',
 'subject': 'US B2C-08 — Edição Restrita de Unidade Operacional por Escopo Regional',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:23:21',
 'details': '''Como Consultor de Vendas ou Agente de Backoffice B2C
Quero que os dados do meu perfil (Empresa do Grupo, Regional, Canal de Entrada) sejam carregados automaticamente no início do fluxo, mantendo o campo "Unidade Operacional" editável apenas para as unidades pertencentes à minha regional.
Para que a Brasil TecPar garanta o cumprimento das regras de compliance corporativo do COI/Octa, evitando que vendedores registrem vendas em unidades operacionais fora da sua alçada de atendimento.

SOLUÇÃO TÉCNICA: Opportunity.OperationUnit__c JÁ EXISTE — não criar campo; replicar no Lead (W-B2C-01). Picklist dependente nativa NÃO filtra por usuário: o caminho é o objeto UserRegionalMapping__c (User__c, Regional__c, OperationUnit__c — mantido pelo Backoffice sem deploy) + choices filtradas pelo $User na jornada/tela. Permission sets PS_B2C_Sales_User (filtrado) e PS_B2C_Backoffice_User (visão ampliada). Carga automática do contexto (empresa, gerência, canal, regional) a partir do usuário logado.

Dependências: SLA de atualização do de-para quando o Octa/Senior transfere o usuário de regional; mecanismo de provisionamento (SSO/SCIM) [CONFIRMAR com TI].

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-08.''',
},
{
 'id': 'W-000065',
 'subject': 'US B2C-09 — Resumo do Pedido e Seleção da Modalidade de Assinatura',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:24:25',
 'details': '''Como Consultor de Vendas B2C
Quero visualizar a tela de Resumo da Venda com a consolidação de todos os dados do pedido e selecionar a modalidade de aceite do contrato (Digital, Evidência/Anexo ou Biometria Facial).
Para que eu possa conferir as informações junto ao cliente antes do envio e garantir a formalização jurídica adequada da contratação.

SOLUÇÃO TÉCNICA: ESTENDER as etapas EXISTENTES da jornada PF — bTecParPFSummaryPortugueseBrazil (resumo) e bTecParPFAcceptPortugueseBrazil (aceite) — não criar tela. Order.AttachmentSignature__c JÁ EXISTE (avaliar no lugar de campo novo). Geração do contrato via DocGen CME (licenciado, 422 usuários, 1M gerações/mês).
CONSTRUIR: Order.SignatureMode__c (Digital/Anexo/Biometria) + IsContractSigned__c; ramo por modalidade no Accept: Digital → IP dispara link (plataforma de assinatura) via WhatsApp/e-mail; Anexo → File Upload obrigatório antes de avançar; Biometria → IP para parceiro externo (unico/idwall/Datavalid — validade jurídica ok; NÃO é nativo). Webhook de aceite → Platform Event ContractSigned__e → trava do botão de perda (mecânica W0382).

Dependências: plataforma de assinatura padrão da casa; contratação do serviço de biometria.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-09.''',
},
{
 'id': 'W-000066',
 'subject': 'US B2C-10 — Régua Automática de Lembretes de Assinatura e Expiração da Oportunidade (SLA 5 Dias)',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:25:16',
 'details': '''Como Gestor Comercial B2C
Quero que o Salesforce e o Marketing Cloud executem uma régua de comunicação com até 3 disparos automatizados durante um período máximo de 5 dias no pipeline para propostas aguardando assinatura, cancelando automaticamente a Oportunidade caso não haja aceite.
Para que a operação automatize a cobrança do cliente, reduza o tempo de ciclo da venda e evite propostas pendentes acumuladas no pipeline dos vendedores.

SOLUÇÃO TÉCNICA: jornada no Marketing Cloud com ENTRADA POR API EVENT — o sync padrão do MC Connect roda em ciclos de ~15 min e NÃO garante o 1º disparo em 15 minutos; janela 08h-20h na configuração da jornada; exit criteria no aceite (Platform Event ContractSigned__e da W-B2C-09). Templates WhatsApp exigem aprovação da Meta (até 24h por template — planejar antes da UAT). O cancelamento no 5º dia é NATIVO e independe do MC: scheduled flow diário → Closed Lost, motivo "Falta de Assinatura" (árvore saneada da W-B2C-05) + tarefa ao vendedor.

Dependências: [CONFIRMAR] licença Marketing Cloud Engagement + canal WhatsApp — NÃO consta na lista de licenças do org (contrato separado). Fallback sem MC: e-mail via flow + WhatsApp pelo canal do bot.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-10.''',
},
{
 'id': 'W-000067',
 'subject': 'US B2C-11 — Abertura de Ticket de Débito Interno via Zendesk e SLA de Regularização',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:27:38',
 'details': '''Como Consultor de Vendas B2C
Quero que, ao identificar um débito interno de um cliente durante a análise de elegibilidade, o Salesforce abra automaticamente um chamado de renegociação no Zendesk para a equipe de Cobrança e mantenha a Oportunidade em meu pipeline por até 5 dias.
Para que a cobrança atue na regularização financeira do cliente sem que eu precise sair do ambiente do CRM, permitindo a retomada automática da venda após a confirmação da baixa bancária.

SOLUÇÃO TÉCNICA: REUSO da integração Zendesk EXISTENTE (flow WorkOrder_Update_Zendesk_Status — aproveitar a mesma Named Credential) e da retomada de venda EXISTENTE (Order.RetomarVendaQuickAction).
CONSTRUIR: status "Aguardando Pagamento de Débito Interno" no funil; flow de abertura do ticket com os dados da CreditAnalysis__c (W-B2C-03); Platform Event DebtSettled__e inbound (BSS/SAP) → flow retoma a venda + notifica o vendedor; scheduled flow: 5 dias sem baixa → Closed Lost "Débito Interno Não Quitado".

Dependências: callback de baixa financeira do BSS/SAP; risco de negócio: boleto compensa em até 48h dentro de SLA de 5 dias — aceitar ou alargar o prazo [DEFINIR].

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-11.''',
},
{
 'id': 'W-000068',
 'subject': 'US B2C-12 — Solicitacão de Desconto na Taxa de Ativação e Agendamento pós-Baixa via Chatbot',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:29:25',
 'details': '''Como Consultor de Vendas B2C
Quero solicitar aprovação da Mesa de Crédito quando um cliente negativado recusar o valor integral da Taxa de Ativação (R$ 149,90), e garantir que o agendamento da instalação pelo Chatbot ocorra apenas após a confirmação da baixa bancária dessa taxa.
Para que a empresa mantenha a alçada de descontos centralizada na Mesa de Crédito e garanta que o time de campo (Field Service) seja despachado apenas para clientes financeiramente regularizados.

SOLUÇÃO TÉCNICA — REUSO MAIOR DO INVENTÁRIO: a família da taxa JÁ EXISTE no Order (InstallationFeeAmount__c, InstallationFeeStatus__c, InstallationFeeDueDate__c, DiscountedInstallationFee__c, DiscountedInstallFeeApproved__c, FeeBillingType__c) e o processo de desconto/isenção COM APROVAÇÃO JÁ EXISTE (FLW_Approval_InstallationFee, OrderInstallationFeeExemptionOrDiscount, Order_Approver_Installation_Screen, Order.RequestExceptionDiscountAction). A work é ADAPTAR: rota de aprovação apontada para a fila CreditTable (Mesa) com alçada 0-100%; GATE do agendamento = Order.InstallationFeeStatus__c (campo existente, não criar) bloqueando criação de ServiceAppointment; baixa via Platform Event. Chatbot: IP expondo AppointmentBookingService.GetSlots (FSL) para consulta/gravação de slots — o bot em si é EXTERNO (Messaging e Chatbot Salesforce estão DESABILITADOS na lista de licenças).

Dependências: plataforma do bot WhatsApp (Zendesk/broker Meta); callback de baixa do BSS.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-12.''',
},
{
 'id': 'W-000069',
 'subject': 'US B2C-13 — Seleção Guiada de Produtos, Formação de Combos/Promoções e Filtro Dinâmico por Endereço',
 'epic': EPIC_B2C, 'created': '2026-08-20T21:30:17',
 'details': '''Como Consultor de Vendas B2C ou Cliente da jornada de autosserviço (E-commerce / App)
Quero visualizar e adicionar ao carrinho de cotação apenas as ofertas e combos promocionais elegíveis e com viabilidade técnica para o endereço selecionado, podendo compor e customizar pacotes (Internet + SVAs/Streaming)
Para que a Brasil TecPar garanta uma venda guiada sem erros de oferta, evite a comercialização de serviços indisponíveis na região e aumente o Ticket Médio/ARPU de forma automatizada e segura.

SOLUÇÃO TÉCNICA — integra com a US QUAL-01 (W-000056) já criada: os 5 catálogos por mercado, as categorias por família e os Rule Sets globais de qualificação (QUAL_MERCADO, QUAL_CANAL, QUAL_TIPO_CLIENTE, QUAL_CIDADE) são daquela work; esta cobre a EXECUÇÃO do filtro no funil B2C. FATO VERIFICADO no registro de interfaces de produção: o filtro de prateleira está DESLIGADO — ProductAvailability/ProductEligibility rodam nas implementações Default e as alternativas (FilterAvailability, FilterEligibility, CtxRulesProductsOpen) estão presentes e INATIVAS; context rules ativas só para preço. A work inclui LIGAR e implementar o filtro — mecanismo conforme a versão do pacote CMT [DEFINIR]: interfaces Availability & Eligibility (Summer '26) ou context rules clássicas. Combos: vlocity_cmt__Promotion__c agregando produtos existentes, adjustment FIXO na linha do SVA (razão fiscal), identificador da promoção herdado nos itens da ordem. Dimensão cidade→zona (IBGE) alimentada pelo Premises (W-B2C-02), alinhada à GeographicCommercialPolicy (P-17). Preço B2C/B2B por Price Lists separadas, produto único.

Dependências: P-19 (domínios de qualificação — Joel); P-17 (IBGE); US QUAL-01/EPC-01/EPC-04; versão do pacote; confirmar com o AE o que os seats on-core (Product Catalog Management, Unified Catalog) destravam.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-13.''',
},
]
