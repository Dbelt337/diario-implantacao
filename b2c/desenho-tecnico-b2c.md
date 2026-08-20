# Desenho Técnico B2C — do requisito à construção
- Documento de arquitetura: transforma cada work do refinamento B2C em instrução de construção, ancorada no inventário real do org de produção (retrieve de 19-20/08: 126 campos do Opportunity, 80 flows, 74+ páginas, jornada OmniScript PF completa, registro de interfaces do CPQ e lista de licenças).
- Princípio NATIVE-FIRST aplicado em toda work: 1º recurso padrão da plataforma/produto licenciado; 2º configuração/extensão suportada; 3º e último, código custom com justificativa registrada.
- Legenda por work: REQUISITO (o que o negócio pede) · REUSO (o que já existe no org, pelo nome) · CONSTRUIR (o que criar, com API name e tipo) · COMO (passo a passo) · DECISÕES (o que trava sem resposta).

### Fundamentos que valem para todas as works
1. INVENTÁRIO-CHAVE DO ORG
- Record Types do Opportunity: B2B, B2C (já existe), vlocity_cmt__MediaCampaign e vlocity_cmt__MobilePhoneOpportunity (caminho de venda móvel já modelado).
- Jornada PF completa em OmniScript já em produção: bTecParPFSalesJourney → AddressAndClientData → CPQConfigurator → Cart → PaymentMethod → Summary → Accept. O B2C novo é evolução dessa jornada, não construção do zero.
- Framework de log de integração já existe (campos RequestPayload__c/ResponsePayload__c/Attempts__c/Status__c vistos nos flows de Lead) — toda integração nova deve usá-lo.
- Framework de validação da casa: família BloqueiaAlteracao* + LossReasonRequired + ObrigaCampos* — padrões a estender, não recriar.
- Motor Vlocity: Promotion disponível; filtro de prateleira DESLIGADO (Availability/Eligibility nas implementações Default); Premises__c/ServicePoint__c existem zerados com hook ativo; context rules ativas só para preço.
- Licenças: Comms Cloud Plus (1.501 em uso), OmniStudio (156), BRE Designer, DocGen CME (422 em uso, 1M gerações/mês), FSL completo, PSL Service User com folga. Bloqueios: Messaging/Chatbot Salesforce desabilitados; franquia B2C do Industries OM zerada; Flow Orchestration limitada a 600 runs/ano (não usar em volume B2C).
2. PADRÕES TRANSVERSAIS DE CONSTRUÇÃO
- Eventos: entradas assíncronas (baixa bancária, aceite de contrato) entram por Platform Event (franquia 750 mil/mês, 16 usados) — nunca polling.
- Jobs de SLA (72h, 5 dias): scheduled flow com batch size controlado; carimbo de data em campo próprio, nunca cálculo sobre LastModifiedDate.
- Toda consulta externa grava snapshot no registro (score, viabilidade, débito) — decisão auditável vale mais que consulta refeita.
- Endereço sempre chaveado por CEP + número + código IBGE; complemento nunca entra em chave.

### W-B2C-01 — Lead & Triagem
1. REQUISITO
- Captura restrita a perfis autorizados, campos obrigatórios (incl. condomínio: Bloco/Apto), Unidade Operacional derivada do CEP, dedup e roteamento Omni-Channel por fila regional e skills.
2. REUSO (verificado no org)
- Lead já tem endereço custom: AddressNumber__c, AddressComplement__c, Neighborhood__c.
- Flows prontos: LeadGetAddress e Address_Get_Infos (consulta de CEP) — estender para gravar também o código IBGE (o ViaCEP já devolve); Get_CNPJ_Details (enriquecimento PJ, 106 KB de lógica pronta); LeadRequiredFields (obrigatoriedades).
- Página LeadRecordPageB2C existe; canal: avaliar reuso de vlocity_cmt__OriginatingChannel__c antes de criar campo novo.
- Duplicate/Matching Rules nativas cobrem Lead×Lead e Lead×Conta.
3. CONSTRUIR
- Lead.IsCondominium__c (Checkbox), Lead.Block__c (Text 20), Lead.ApartmentUnit__c (Text 20), Lead.IBGECode__c (Text 7), Lead.OperationUnit__c e Lead.Regional__c (Picklists espelhando os da Opportunity — OperationUnit__c já existe lá).
- Objeto de-para CEPOperationUnit__c (faixa de CEP → unidade/regional), mantido pelo Backoffice sem deploy.
- Validation rules: condomínio (Bloco/Apto obrigatórios se IsCondominium__c) e PJ (Razão Social + CPF do representante — campos a confirmar no inventário do Lead).
- Omni-Channel: filas regionais + skills; presença nos perfis de venda.
4. COMO
- Página padrão de Lead com Dynamic Forms cobre a captura; se o negócio exigir jornada guiada, estender o AddressAndClientData da jornada PF — não criar LWC.
- Record-triggered flow no Lead: após CEP preenchido, chama LeadGetAddress estendido → grava IBGE → resolve unidade no de-para → preenche OperationUnit__c/Regional__c.
5. DECISÕES
- OriginatingChannel__c atende como Canal de Entrada ou os valores exigem campo próprio? (Levantar valores atuais.)
- Confirmar Person Account habilitado para o funil PF.

### W-B2C-02 — Viabilidade técnica no Lead + oferta móvel obrigatória
1. REQUISITO
- Viabilidade geográfica na fase de Lead (padrão 200 m da CTO), reserva automática de porta, e inviabilidade proibida de virar perda sem oferta móvel expressa recusada.
2. REUSO
- Record Type vlocity_cmt__MobilePhoneOpportunity: o caminho de venda móvel JÁ EXISTE como tipo de Oportunidade — o fluxo alternativo móvel converte o Lead para esse RT, não inventa jornada.
- Padrão de viabilidade do B2B como referência de modelagem: ApprovedViability__c, ViabilityType__c, SLAViability__c já existem na Opportunity.
- Premises__c + ServicePoint__c: zerados, hook PremisesInterface ativo — adoção limpa.
- Framework de log de integração para a chamada ao GIS.
3. CONSTRUIR
- Lead.ViabilityStatus__c (Picklist: Viável/Inviável/Exceção regional), Lead.CTO__c (Text), Lead.PortReservationToken__c (Text), Lead.MobileOfferRejected__c (Checkbox).
- Integration Procedure de viabilidade no padrão TMF679 (Product Offering Qualification — certificado no Communications Cloud) contra o GIS/Ozimap.
- Na viabilidade positiva: criar/achar Premises__c (chave CEP+número+IBGE) e ServicePoint__c (tecnologia, CTO, token de reserva).
- Validation rule: bloqueia status de perda por inviabilidade sem MobileOfferRejected__c = TRUE.
4. COMO
- Botão/etapa da jornada chama a IP; decisão no retorno: viável → reserva porta + segue; inviável → tela de oferta móvel (etapa da jornada PF) → recusa expressa marca o checkbox e libera a perda.
5. DECISÕES
- Dono do SLA de expiração do token de reserva (inventário de rede, não Salesforce).
- Tratamento de exceção regional >200 m: fila? aprovação? — definir com Engenharia.

### W-B2C-03 — Análise de crédito: score por canal, 3 pilares, regra do 3º contrato
1. REQUISITO
- Crédito na fase de Lead: débitos internos + Serasa + contratos sem 1ª parcela; corte de score por canal de entrada; 2 contratos sem 1ª parcela paga → 3º contrato obrigatoriamente na Mesa; limite parametrizável; vendedor vê apenas mensagens genéricas.
2. REUSO
- Fila da Mesa já existe: CreditTable.
- BRE/Expression Sets licenciado e habilitado: a régua canal→score→taxa vira Decision Matrix editável pela Mesa, sem deploy (preferível ao Custom Metadata da especificação original).
- Framework de log de integração para Serasa/Customer Core.
3. CONSTRUIR
- Objeto CreditAnalysis__c: Lead__c/Opportunity__c, Score__c (Number), Bureau__c, ConsultedAt__c (DateTime), InternalDebts__c (Currency), ContractsWithoutFirstPayment__c (Number), Result__c (Picklist Aprovado/Mesa/Reprovado) — um registro por consulta = snapshot auditável.
- Decision Matrix "PoliticaCredito": canal | score mínimo isenção | taxa | limite de contratos.
- Flow pós-consulta: grava CreditAnalysis__c, consulta a matriz, decide rota; se ContractsWithoutFirstPayment__c >= limite → fila CreditTable.
- FLS: detalhe da análise restrito; vendedor enxerga só Result__c.
4. DECISÕES
- Score exatamente no corte (350/380): paga ou isenta? — pendência herdada da Política de Crédito, decide antes da matriz.
- API "contratos sem 1ª parcela" no Customer Core: dependência externa nomeada.

### W-B2C-04 — Flag de débito no endereço, sem trava (consolidada)
1. REQUISITO
- Consultar histórico de débito do endereço de instalação, exibir alerta visual sem bloquear a venda, e consolidar relatório gerencial pós-venda.
2. REUSO
- Modelo de endereço existente: Endereco__c + Address (com Neighborhood__c/Number) + junção EnderecoUtilizadoOpportunity__c.
- Relatórios nativos; perfis de coordenador/gerente para o acesso.
3. CONSTRUIR
- Opportunity.AddressDebtFlag__c (Checkbox) + Opportunity.AddressDebtSummary__c (Long Text — resumo devolvido pela API para contexto do painel).
- FlexCard de alerta na tela da jornada/Oportunidade (amarelo/vermelho + contratos anteriores).
- Relatório "Vendas Concluídas em Endereços Inadimplentes" (filtro: flag = true, fase ganha).
4. COMO
- A mesma chamada de viabilidade/endereço da W-02 consulta o histórico (uma viagem, dois usos); chave CEP+número+IBGE; flow grava a flag. Nenhuma aprovação, nenhuma trava — requisito explícito.
5. DECISÕES
- API de histórico por endereço no Customer Core (dependência externa, dono: TI/Davi).

### W-B2C-05 — Painel de vendas travadas + motivos de perda segregados
1. REQUISITO
- Dashboard de oportunidades paradas por etapa; botão de perda disponível até a assinatura; árvores de motivo distintas para Lead e Opportunity.
2. REUSO (a work é mais saneamento que construção)
- Motivos de perda JÁ EXISTEM nos dois objetos: Lead.LossReason__c + Lead.LossType__c; Opportunity.LossReason__c E Opportunity.Loss_Reason__c (DUPLICADOS — defeito real de hoje) + CancellationType__c/CancellationDetails__c.
- VR LossReasonRequired já ativa; ObrigaCamposFechadoPerdido e BloqueiaEdicaoFechadoPerdido ativas.
- Ações prontas: Lead.LossLead, Opportunity.LossOpportunity, CancelRecordAndRelateds (Lead/Opp/Order/Contract); flows CancelLeads, ModifyLostLead, CancelOpportunity_B2B.
3. CONSTRUIR
- SANEAMENTO: escolher entre LossReason__c e Loss_Reason__c, migrar dados e aposentar o perdedor — antes de qualquer árvore nova.
- Opportunity.StageEnteredAt__c (DateTime) + record-triggered flow de carimbo na troca de fase (base do "tempo na etapa").
- Dashboards por hierarquia de papéis (vendedor/coordenador/gerente) — nativos.
- Trava do botão de perda pós-assinatura: mesma mecânica de visibilidade condicional homologada na W0382, sobre IsContractSigned__c (W-09).
4. DECISÕES
- Árvores de motivos validadas pelo comercial BTP (dependência de negócio, não técnica).

### W-B2C-06 — Tipo de negociação + segmentação B2C/B2S por R$ 800
1. REQUISITO
- Tipo de negociação (Normal/Cortesia/Swap) definido no início; segmento B2C (<800) vs B2S (>=800) calculado automaticamente no carrinho, com recálculo dinâmico.
2. REUSO
- NegotiationType__c ("Tipo negociação", Picklist) JÁ EXISTE na Opportunity — a especificação original pedia Record Types novos; native-first recomenda reusar o picklist e manter os RTs B2B/B2C como estão (RT novo replica páginas, perfis e automações — custo alto para ganho baixo). Registrar o tradeoff com o negócio.
- Carrinho Vlocity (cfBTecParPF*): a segmentação entra como price rule/pricing plan step do pacote no reprice.
3. CONSTRUIR
- Opportunity.Segment__c (Picklist B2C/B2S) + regra no motor de preço: total < 800 → B2C; >= 800 → B2S; recálculo a cada alteração do carrinho.
- Valores Normal/Cortesia/Swap no NegotiationType__c (conferir valores atuais antes).
- Envio do Segment__c no payload de ordem (MuleSoft → Customer Core/ERP).
4. DECISÕES
- Aprovação do negócio para picklist em vez de Record Type (mudança consciente sobre a especificação da Sysmap).

### W-B2C-07 — Reagendamento 3 tentativas / cancelamento 72h
1. REQUISITO
- 3 tentativas de contato sem sucesso → ordem sai do Delivery para fila do Backoffice Comercial; 72h sem contato → cancela ordem e oportunidade automaticamente.
2. REUSO
- FSL completo e licenciado em produção (Dispatcher 324, Scheduling 878, Mobile 1.107 em uso).
- Cancelamento em cascata pronto: CancelRecordAndRelateds + Cancell_WO_SA; reagendamento: Order.NovoAgendamento, SA_Auto_Schedule, FlowOrderScheduleInstallation.
3. CONSTRUIR
- WorkOrder.ContactAttempts__c (Number) + ação de registro de tentativa (quick action ou etapa do app FSL) com flow contador; ao atingir 3 → owner = fila "Backoffice Comercial B2C" (Queue nova) + carimbo TransferredToBackofficeAt__c (DateTime).
- Scheduled flow diário: registros na fila há >= 72h → chama CancelRecordAndRelateds com motivo "Cancelado - Insucesso de Contato em 72h" (valor novo na árvore da W-05).
4. DECISÕES
- Validar gatilhos de tentativa com a gestão de Delivery (dependência nomeada no refinamento).

### W-B2C-08 — Unidade Operacional restrita por escopo regional
1. REQUISITO
- Contexto do usuário (empresa, gerência, canal, regional) carregado automaticamente; picklist de Unidade Operacional filtrada pela regional do usuário; Backoffice com visão ampliada.
2. REUSO
- OperationUnit__c JÁ EXISTE na Opportunity — não criar campo novo; replicar no Lead (W-01).
- Provisionamento de perfis já vem do Senior/Octa (SSO) — confirmar mecanismo.
3. CONSTRUIR
- UserRegionalMapping__c (objeto: User__c lookup, Regional__c, OperationUnit__c — um registro por usuário×unidade), mantido pelo Backoffice sem deploy.
- Na jornada/tela: choices da Unidade filtradas pelo mapping do $User (picklist dependente nativa não filtra por usuário — este é o único ponto onde configuração pura não atende, e o de-para já estava na própria especificação).
- Permission sets PS_B2C_Sales_User e PS_B2C_Backoffice_User (Backoffice: sem filtro).
4. DECISÕES
- SLA de atualização do de-para quando o Octa transfere o usuário de regional (risco apontado no refinamento).

### W-B2C-09 — Resumo do pedido + assinatura (digital / anexo / biometria)
1. REQUISITO
- Tela de resumo com todos os dados do pedido; seletor de modalidade de aceite; anexo obrigatório na modalidade evidência; botão de perda desabilitado após assinatura.
2. REUSO (o grosso já existe)
- bTecParPFSummaryPortugueseBrazil (resumo) e bTecParPFAcceptPortugueseBrazil (aceite) JÁ EXISTEM na jornada PF — a work é estender essas etapas, não criar tela.
- DocGen CME licenciado e em produção (422 usuários, 1M gerações/mês) para o contrato.
- Trava pós-evento: mecânica da W0382.
3. CONSTRUIR
- Order.SignatureMode__c (Picklist: Digital/Anexo/Biometria) + Order.IsContractSigned__c (Checkbox, gravado pelo retorno da assinatura).
- Ramo por modalidade na etapa Accept: Digital → IP dispara link (Docusign/Clicksign) via WhatsApp/e-mail; Anexo → File Upload obrigatório antes de avançar; Biometria → IP para o parceiro (unico/idwall/Datavalid — validade jurídica reconhecida; não é nativo).
- Webhook de aceite → Platform Event ContractSigned__e → marca IsContractSigned__c e desabilita perda (VR + visibilidade do botão).
4. DECISÕES
- Contratação do serviço de biometria (dependência comercial); plataforma de assinatura digital padrão da casa.

### W-B2C-10 — Régua de lembretes (3 disparos / 5 dias / janela 8h-20h)
1. REQUISITO
- Lembretes em 15 min, D+1 e D+3 via WhatsApp/e-mail; oportunidade expira no 5º dia como perdida por falta de assinatura; janela 08:00-20:00.
2. REUSO
- Franquia de flow gigantesca (20M interviews/mês) para o job de expiração; Platform Events ociosos para o aceite; motivo de perda entra na árvore saneada da W-05.
3. CONSTRUIR
- Jornada no Marketing Cloud com entrada por API Event (o sync padrão do MC Connect roda ~15 min e NÃO garante o 1º disparo — a entrada tem que ser evento); exit criteria: ContractSigned.
- Scheduled flow diário: Aguardando Assinatura há >= 5 dias → Closed Lost, motivo "Falta de Assinatura", tarefa para o vendedor.
- Templates WhatsApp aprovados pela Meta (lead time até 24h por template — planejar antes da UAT).
4. DECISÕES
- CONFIRMAR licença Marketing Cloud Engagement + canal WhatsApp (não aparece na lista de licenças do org — é contrato separado). Sem MC, o fallback nativo é e-mail via flow + WhatsApp pelo mesmo canal do chatbot (W-12).

### W-B2C-11 — Débito interno: ticket Zendesk + retomada por baixa
1. REQUISITO
- Débito interno identificado → ticket automático no Zendesk para Cobrança; oportunidade pausada até 5 dias; baixa bancária retoma automaticamente; sem baixa, perde.
2. REUSO
- Integração Zendesk JÁ EXISTE no org: WorkOrder_Update_Zendesk_Status (conferir a Named Credential usada e reaproveitá-la).
- Retomada de venda JÁ EXISTE: Order.RetomarVendaQuickAction.
- Framework de log de integração para o payload do ticket.
3. CONSTRUIR
- Status "Aguardando Pagamento de Débito Interno" no funil + flow de abertura do ticket (dados do débito vindos da CreditAnalysis__c da W-03).
- Platform Event DebtSettled__e (inbound do BSS/SAP) → flow retoma a oportunidade (reusa a lógica do RetomarVenda) + notifica o vendedor.
- Scheduled flow: 5 dias sem baixa → Closed Lost "Débito Interno Não Quitado".
4. DECISÕES
- Callback de baixa do BSS/SAP (dependência externa); boleto compensa em até 48h dentro de SLA de 5 dias — risco de negócio aceito ou prazo maior?

### W-B2C-12 — Desconto da taxa de ativação pela Mesa + agendamento via chatbot
1. REQUISITO
- Vendedor não altera a taxa (R$ 149,90); pedido de desconto (0-100%) vai à Mesa; agendamento técnico bloqueado até a taxa paga; pós-baixa, chatbot no WhatsApp oferece slots e agenda.
2. REUSO (a maior surpresa do inventário)
- O processo de isenção/desconto de taxa COM APROVAÇÃO JÁ EXISTE no B2B: FLW_Approval_InstallationFee, OrderInstallationFeeExemptionOrDiscount, OrderRequestExceptionDiscount, Order_Approver_Installation_Screen e a ação Order.RequestExceptionDiscountAction. A work B2C é ADAPTAR esse processo (fila de aprovação → Mesa de Crédito/CreditTable), não construir outro.
- Agendamento: btecparScheduleInstallation, SA_Auto_Schedule; slots via AppointmentBookingService.GetSlots (FSL, documentado) exposto por Integration Procedure.
3. CONSTRUIR
- Order.ActivationFeePaid__c (Checkbox, gravado pelo Platform Event de baixa) + gate: criação de ServiceAppointment bloqueada sem a flag (VR/flow).
- Rota da aprovação existente apontada para a fila CreditTable com alçada 0-100%.
- Ponte do chatbot: IP que consulta GetSlots e grava a escolha — o bot em si é EXTERNO (Zendesk/Meta): Messaging e Chatbot Salesforce estão desabilitados na lista de licenças.
4. DECISÕES
- Plataforma do bot (Zendesk bot? broker Meta?) — decisão de canal, não de Salesforce.

### W-B2C-13 — Catálogo guiado, combos via Promotion, filtro por endereço/IBGE
1. REQUISITO
- Prateleira filtrada por segmento+canal+documento+cidade(IBGE)+viabilidade; combos por Promotion sem produto duplicado; desconto fixo no SVA (razão fiscal); reprice em tempo real; Group Promotion ID rastreável na ordem.
2. REUSO
- vlocity_cmt__Promotion__c + ProductChildItem disponíveis; carrinho e configurador da jornada PF prontos (cfBTecParPFCart/CPQConfigurator); motor de preço já roda context rules (para preço).
3. CONSTRUIR / LIGAR
- FATO CENTRAL do inventário: o filtro de prateleira está DESLIGADO — ProductAvailability/ProductEligibility nas implementações Default; FilterAvailability/FilterEligibility/CtxRulesProductsOpen presentes e INATIVAS. A work inclui ligar e implementar o filtro, não configurá-lo. Caminho conforme a versão do pacote: interfaces novas de Availability & Eligibility (Summer '26) OU ativação das context rules de produto clássicas.
- Dimensão de zona: código IBGE como atributo de qualificação (fonte: Premises/endereço das W-01/W-02) + tabelas de preço regionalizadas no EPC.
- Promotions: combo = Promotion agregando produtos existentes; ajuste (adjustment) fixo aplicado na linha do SVA; herança do identificador da promoção nos itens da ordem (conferir campos de promoção do pacote nos order items antes de criar algo).
4. DECISÕES
- Versão do pacote CMT instalada [pendente — Setup > Pacotes instalados] decide o mecanismo do filtro.
- Confirmar com o AE o que os seats on-core presentes na lista (Product Catalog Management, Unified Catalog, Product Discovery, Revenue Management Promotions) destravam — pode mudar o caminho do catálogo B2C.

### W-B2C-14 — Acervo de contratos assinados (índice + repositório + API)
1. REQUISITO
- Consultar qualquer contrato assinado (legado ou novo) pela Conta, com cadeia de versões preservada, sem depender do monolito; Salesforce não é repositório de binário.
2. REUSO
- DocGen CME licenciado e em uso para o go-forward; MuleSoft como casa da API; FlexCard como painel de consulta.
3. CONSTRUIR
- DocumentoJuridico__c: Account__c, Contract__c, Type__c (TAS/TCS/TSE/TSA), SignedAt__c, FileHash__c (SHA-256), RepositoryURL__c, PreviousDocument__c (self-lookup — a cadeia PREVIOUS/BECOME do legado vira relacionamento consultável).
- API de Documentos (MuleSoft): GET /documentos/{id} → autentica, loga acesso (LGPD), devolve link pré-assinado com expiração. Todos os consumidores (Salesforce, legado, Zendesk, auditoria) usam a mesma porta.
- ETL de backfill: extração do monolito (binários + FKs) → repositório imutável (WORM) → índice com conferência de hash; job delta durante a coexistência; origem nunca apagada até o corte.
4. DECISÕES
- Repositório-alvo (S3/SharePoint/SAP DMS) e volumetria (nº de documentos e GB) — dimensionam o workstream.

### Inventário pendente — próximos retrieves
1. Este desenho usou o metadata completo do Opportunity e o catálogo de flows/páginas/LWCs de produção. Para fechar o nível de campo das demais works, falta retrievar:
- CustomObject: Lead, Account, Order, WorkOrder, ServiceAppointment, Endereco__c, EntryChannel__c, EnderecoUtilizadoOpportunity__c, vlocity_cmt__Promotion__c, vlocity_cmt__Premises__c, vlocity_cmt__ServicePoint__c.
- Flows citados como reuso, para leitura fina: LeadGetAddress, Get_CNPJ_Details, FLW_Approval_InstallationFee, OrderInstallationFeeExemptionOrDiscount, WorkOrder_Update_Zendesk_Status, Order.RetomarVenda (flow da action).
2. Com esse pacote em mãos, cada seção CONSTRUIR deste documento desce para o nível "campo a campo, valor a valor" — e as estimativas da Sysmap podem ser conferidas contra ele.
