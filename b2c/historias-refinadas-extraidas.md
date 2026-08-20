### US de B2C[SALESFORCE B2C / LEAD & TRIAGEM] - Captura, Triagem, Roteamento Omni-Channel e Regras de Condomínio
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas, Atendente (AR/Central) ou Agente de Backoffice
- Quero realizar a captura de leads com restrição de input manual a perfis autorizados, validação cadastral obrigatória e atribuição automatizada da Unidade Operacional
- Para que a triagem de duplicidades e o roteamento Omni-Channel ocorram de forma assertiva por skill/região, eliminando entradas inconsistentes no funil comercial.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Alinhamento nacional do processo padrão BTP para entrada e qualificação de Leads B2C/B2S no Salesforce.
- Regras: * Restrição do Input Manual: O cadastro manual de vendas/leads é restrito aos perfis de Backoffice (Inside, PAP, Agentes Comerciais e Autorizados), Agentes de Relacionamento (ARs/Lojas) e Central de Atendimento.
- Campos Cadastrais Obrigatórios: Preenchimento obrigatório de CPF, Nome Completo, Telefone, CEP, Endereço, Número, Complemento, Formato de Prospecção e Seleção Manual do Canal de Entrada e Empresa do Grupo.
- Regra de Condomínio: Ao marcar a opção de Condomínio, os campos Bloco e Apartamento passam a ser estritamente obrigatórios no cadastro de endereço para evitar sinalizações incorretas de viabilidade ou débitos.
- Atribuição de Unidade Operacional e Regional: A Unidade Operacional e Regional deve ser derivada automaticamente pelo sistema com base no CEP do endereço de instalação do cliente , sendo editável apenas para as Unidades contidas no escopo permitido do perfil do usuário.
- Deduplicação e Roteamento: Deduplicação automática com Leads abertos ou Contas ativas na base e roteamento automático via Omni-Channel por fila regional e habilidades (skills) do agente.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Lead, Account (Person Account), Contact, Group (Queues).
- Automação / Lógica: * Screen Flow / LWC (Nova Venda): Interface unificada de entrada.
- Validation Rules: Exigência de Bloco e Apartamento quando IsCondominium__c = TRUE ; exigência de Razão Social e CPF Representante quando RecordType = PJ.
- Record-Triggered Flow: Consulta CEP e preenchimento de Unidade_Operacional__c e Regional__c baseados no endereço de instalação.
- Omni-Channel Routing Rules: Roteamento por filas regionais e skills.
- Integração / APIs: API dos Correios / DNE para autocomplete de CEP. API TMF632 (Party Management).
- Segurança e Acessos: Profiles de Backoffice, AR e Central de Atendimento com acesso de criação. FLS restringindo edições de Unidade fora da regional permitida.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Cadastro de Lead Residencial em Condomínio
- Dado que o operador de vendas insere os dados de um cliente em um endereço sinalizado como condomínio,
- Quando ele informa o CEP e o Número do imóvel,
- Então o Salesforce deve exigir o preenchimento obrigatório dos campos "Bloco" e "Apartamento" e derivar automaticamente a "Unidade Operacional" com base no CEP do local.
- Cenário 2: Inclusão de Lead PJ com Representante Legal
- Dado que o operador seleciona o tipo de documento CNPJ no formulário "Nova Venda",
- Quando avança no cadastro sem preencher a Razão Social ou o CPF do Representante Legal,
- Então o sistema deve bloquear o salvamento e indicar os campos pendentes de preenchimento obrigatório.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Sincronização do cadastro de CEPs x Unidades Operacionais BTP.
- Riscos/Premissas: Instabilidade na API de CEP pode exigir preenchimento manual do logradouro garantindo validações mínimas.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: CEP de condomínio cadastrado com Bloco/Apto, CNPJ com Razão Social e CPF do Representante, CPF com endereço em regional diferente do usuário logado.
### [SALESFORCE B2C / VIABILIDADE & MÓVEL] - Análise de Viabilidade Técnica no Lead e Oferta Móvel Obrigatória
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas B2C
- Quero executar a análise de viabilidade técnica e ser direcionado obrigatoriamente para a Oferta Móvel em caso de inviabilidade
- Para que eu identifique precocemente a disponibilidade de rede fixa e converta o cliente para serviços móveis antes de registrar a perda do contato.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Antecipação da viabilidade técnica para a etapa de Lead no Salesforce B2C para otimizar a experiência do vendedor e evitar retrabalho.
- Regras: * Execução na Fase de Lead: A consulta de viabilidade geográfica de rede de fibra deve ser realizada obrigatoriamente na fase de Lead.
- Padrão Nacional de Viabilidade (200 Metros): Adota-se o parâmetro padrão nacional da Engenharia BTP de 200 metros de distância de cabo (drop) a partir da CTO. Exceções de distância são tratadas regionalmente após o fluxo padrão.
- Reserva Automática de Porta: Quando a viabilidade for positiva, o sistema realiza a reserva automática da porta na CTO, liberando o provisionamento pelo técnico via celular no momento da instalação.
- Gatilho de Oferta Móvel Obrigatória: Em caso de inviabilidade técnica de rede fixa (fibra), o sistema está proibido de classificar a oportunidade/lead diretamente como "Perdido".
- Fluxo Alternativo Móvel: O sistema deve obrigatoriamente apresentar a tela/passo de Oferta de Serviço Móvel (Telefonia/Dados).
- Regra de Desistência: A marcação de perda só será permitida se o cliente recusar expressamente a oferta de serviço móvel.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Lead, Viability_History__c, Product2.
- Automação / Lógica: * Integration Procedure / OmniStudio / Flow: Chamada de API de viabilidade técnica síncrona ao GIS/Inventário de Rede.
- Screen Flow (Decision Element): Avaliação do retorno de viabilidade. Se Inviable, redirecionar para a tela Mobile_Offer_Screen.
- Validation Rule: Bloqueio de alteração do status para "Perdido por Inviabilidade" sem a confirmação do campo Mobile_Offer_Rejected__c = TRUE.
- Field Updates: Salvamento da CTO e Token de Reserva de Porta (Port_Reservation_Token__c).
- Integração / APIs: API REST de Geolocalização e Inventário de Rede GIS/Ozimap. API de Reserva de Porta CTO.
- Segurança e Acessos: Acesso de leitura/escrita no Lead e leitura no Catálogo de Produtos Móveis.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Viabilidade Positiva dentro dos 200m com Reserva de Porta
- Dado que o Lead possui CEP e número de imóvel residencial cadastrados,
- Quando o vendedor aciona a consulta de viabilidade técnica,
- Então o sistema deve confirmar a viabilidade dentro do limite de 200 metros , efetuar a reserva da porta na CTO e liberar o avanço do Lead.
- Cenário 2: Inviabilidade Técnica de Fibra com Oferta Móvel Obrigatória
- Dado que a consulta de viabilidade técnica de fibra retornou "Inviável",
- Quando o sistema processa o resultado negativo,
- Então o Salesforce deve apresentar obrigatoriamente a tela de Oferta do Serviço Móvel e bloquear a marcação de perda direta até a decisão do cliente.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Integração síncrona com o barramento de rede e catálogo móvel ativo.
- Riscos/Premissas: Expirar o tempo da reserva de porta caso o Lead não seja convertido em contrato dentro do SLA configurado.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: Endereço a 150m da CTO (Viável com porta), Endereço a 350m da CTO (Inviável - deve disparar Oferta Móvel).
### [SALESFORCE B2C / CRÉDITO & MESA DE CRÉDITO] - Análise de Risco
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas B2C ou Analista de Crédito
- Quero realizar a análise de crédito automatizada (com réguas de escore associadas ao Canal de Entrada) e encaminhar solicitações para a Mesa de Crédito
- Para que a empresa estabeleça travas de segurança contra fraudes e inadimplência crônica sem comprometer a fluidez das vendas comerciais.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Análise de crédito antecipada para a fase de Lead, integrando consultas internas e externas sob regras do COI e da área de Crédito BTP.
- Regras: * Execução Antecipada: A análise de crédito deve ser processada na fase de Lead (após a confirmação da viabilidade).
- Score pelo Canal de Entrada: A régua/escore de corte de crédito é parametrizada pelo Canal de Entrada da Venda (ex: Inside Sales, PAP, Loja) e não pelo perfil do operador logado.
- Três Pilares de Consulta:
- Débitos Internos: Verificação de faturas vencidas/em aberto no ecossistema Brasil TecPar.
- Serasa / Bureaus Externos: Consulta de restrições de crédito de mercado.
- Histórico de Contratos sem 1ª Parcela: Verificação de contratos ativos no mesmo CPF.
- Regra do 3º Contrato (Mesa de Crédito): Se o cliente (CPF) possuir 2 (dois) contratos ativos sem o pagamento da primeira parcela e solicitar um 3º contrato, o sistema deve encaminhar a proposta obrigatoriamente para a Mesa de Crédito a partir da tentativa do 3º contrato.
- Parametrização e Autonomia da Mesa: A quantidade limite de contratos sem 1ª parcela (gatilho = 3º) deve ser parametrizável. A Mesa de Crédito possui a alçada exclusiva para aprovar (com ou sem condições/taxa) ou recusar a venda.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Lead, Credit_Analysis__c, Contract, Account.
- Automação / Lógica: * Custom Metadata Type (Credit_Channel_Setting__mdt): Associação de escores mínimos e limites por Canal de Entrada.
- Integration Procedure / Apex Service: Consulta combinada síncrona (Débitos Internos + Serasa + Contagem de Contratos Ativos sem 1ª Parcela Paga).
- Approval Process / Fila: Roteamento automático para a Fila "Mesa de Crédito B2C" ao identificar 2 contratos sem 1ª parcela paga na tentativa do 3º contrato.
- Integração / APIs: API MuleSoft (TMF632/Serasa/Customer Core) para retornos de débitos e faturas.
- Segurança e Acessos: FLS restrito. Vendedores visualizam apenas mensagens informativas gerais ("Aprovado", "Aguardando Mesa de Crédito" ou "Pendência Interna").
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Gatilho da Mesa de Crédito na Tentativa do 3º Contrato sem 1ª Parcela
- Dado que o cliente CPF "111.222.333-44" possui 2 contratos ativos no sistema sem confirmação do pagamento da 1ª parcela,
- Quando o vendedor tenta avançar uma nova solicitação de 3º contrato no Lead,
- Então o Salesforce deve bloquear a aprovação direta e direcionar o Lead para a fila da "Mesa de Crédito".
- Cenário 2: Consulta de Score Parametrizada por Canal de Entrada
- Dado que uma proposta é cadastrada com o Canal de Entrada "PAP Terceiro",
- Quando a consulta de crédito é disparada,
- Então o sistema deve avaliar o escore de corte configurado para o canal "PAP Terceiro" , independentemente do perfil do usuário que realizou o input.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Construção da API de validação da quantidade de contratos ativos sem a 1ª parcela paga no Customer Core.
- Riscos/Premissas: Atrasos no retorno bancário da 1ª parcela podem enviar temporariamente clientes adimplentes para a alçada da Mesa de Crédito.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: CPF sem contratos prévios, CPF com 2 contratos ativos sem a 1ª parcela paga (deve acionar a Mesa no 3º contrato), CPF com 2 contratos ativos com 1ª parcela paga (não deve acionar a Mesa).
### [SALESFORCE B2C / ENDEREÇO & RISCO] - Sinalização de Débito no Endereço (Flag/Relatório) e Histórico sem Trava Impeditiva
1. NARRATIVA DE NEGÓCIO
- Como Vendedor e Analista de Compliance
- Quero que o sistema identifique se o endereço de instalação possui histórico de débitos ou reincidência de inadimplência (cruzando CEP, número e vínculos) e exiba uma sinalização visual (Flag) sem bloquear a venda
- Para que o atendimento comercial siga de forma fluída e as propostas realizadas em locais inadimplentes sejam consolidadas em relatórios estratégicos pós-venda para análise de risco.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Padronização nacional BTP descartando aprovações manuais bloqueantes do coordenador no momento do atendimento para evitar gargalos operacionais.
- Regras: * Pesquisa no Endereço: O sistema consulta o histórico do endereço de instalação (CEP + Número + Complemento) cruzando vínculos de sobrenome, e-mail e telefone com contratos inadimplentes anteriores.
- Exibição do Histórico: O Salesforce exibe na tela de atendimento um painel com os contratos prévios daquele imóvel para dar contexto visual ao operador.
- Sem Bloqueio ou Alçada Impeditiva: A existência de débito no endereço não deve travar o fluxo de venda e não deve exigir aprovação manual impeditiva do Coordenador durante a negociação.
- Sinalização e Relatório Pós-Venda: A Oportunidade/Pedido concluído em endereço inadimplente recebe um carimbo/sinalização visual (Address_Debt_Flag__c = TRUE). O sistema gera automaticamente relatórios gerenciais pós-venda para monitoramento contínuo das regionais.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Lead, Opportunity, Order, Address_History__c.
- Automação / Lógica: * Apex Service / Integration Procedure: Consulta ao serviço de histórico do endereço de instalação e marcação da Flag Address_Debt_Flag__c = TRUE caso seja localizado débito vencido.
- FlexCard / LWC: Componente em tela exibindo o alerta visual amarelo/vermelho ("Atenção: Histórico de Débito no Endereço") e o resumo dos contratos anteriores.
- Salesforce Reports: Relatório gerencial automatizado "Vendas Concluídas em Endereços Inadimplentes".
- Integração / APIs: API de histórico de inadimplência por endereço no Customer Core / ERP.
- Segurança e Acessos: Acesso de visualização ao campo da Flag para todos os perfis e acesso de relatórios consolidados para Coordenadores/Gerentes.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Identificação de Débito no Endereço sem Bloqueio de Venda
- Dado que o endereço "Rua das Flores, 100, Apto 21" possui histórico de contrato inadimplente na base,
- Quando o vendedor cadastra uma nova proposta para o mesmo imóvel,
- Então o sistema deve exibir a sinalização visual de alerta de débito e permitir que a venda prossiga normalmente sem exigir aprovação bloqueante.
- Cenário 2: Consolidação em Relatório Gerencial Pós-Venda
- Dado que uma venda foi concluída com sucesso em um endereço sinalizado com débito,
- Quando a Oportunidade/Pedido é salvo,
- Então o registro deve ser incluído automaticamente no relatório pós-venda "Vendas Concluídas em Endereços Inadimplentes" para análise da gestão.
5. DEPENDÊNCIAS E RISCOS
- Dependências: API de consulta de histórico de endereço no Customer Core e padronização do preenchimento de complemento.
- Riscos/Premissas: Variações de escrita de complemento (ex: "Ap 21" vs "Apto 21") exigem chave de tratamento por CEP e número principal.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: Endereço sem histórico de inadimplência, Endereço com contrato cancelado e inadimplente (deve exibir Flag e incluir no relatório sem travar a venda).
### [SALESFORCE B2C / ANALYTICS & DASHBOARD] - Painel de Controle de Vendas Travadas e Gestão de Perdas Segregada
1. NARRATIVA DE NEGÓCIO
- Como Gerente Comercial, Coordenador B2C e Vendedor
- Quero visualizar um Painel de Controle (Dashboard) de oportunidades paradas no fluxo e registrar os motivos de perda com segregação entre Leads e Oportunidades
- Para que a equipe gerencial execute intervenções ativas de resgate e o marketing analise com precisão as causas de perda em cada estágio do funil.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Monitoramento de gargalos comerciais e padronização da árvore de perda BTP.
- Regras: * Painel de Controle de Vendas (Dashboard): Painel gerencial para monitorar oportunidades travadas em etapas críticas (Viabilidade, Análise de Crédito, Aguardando Pagamento da Taxa de Ativação e Aguardando Agendamento).
- Botão de Perda/Desistência: O botão de registro de perda de venda deve estar disponível ao operador ao longo de todo o fluxo comercial. O botão é desabilitado apenas após a assinatura formal do contrato.
- Segregação Obrigatória de Motivos de Perda: As listas de motivos de perda devem ser estritamente segregadas entre o objeto Lead (estágio de prospecção) e o objeto Opportunity (estágio de negociação/cotação).
- Filtros e Visibilidade Hierárquica: Vendedores enxergam apenas seus registros travados; Coordenadores enxergam a equipe/unidade; Gerentes e Diretores enxergam a visão regional/nacional.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Lead, Opportunity, Task.
- Automação / Lógica: * Salesforce Reports & Dashboards: Relatórios do tipo matriz agrupados por estágio, tempo de permanência no estágio (Stage_Age_Days__c) e unidade/regional.
- Picklists / Dependency Rules: Árvore de motivos de perda dedicada para Lead.Loss_Reason__c e Opportunity.Loss_Reason__c.
- Validation Rule: Desabilitação da alteração de status para "Perdido" se Is_Contract_Signed__c = TRUE.
- Integração / APIs: N/A (Funcionalidade nativa analítica e de processo no Salesforce).
- Segurança e Acessos: Visibilidade regulada pela Hierarquia de Papéis (Role Hierarchy).
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Disponibilidade do Botão de Perda até a Assinatura do Contrato
- Dado que uma Oportunidade está no estágio de "Análise de Crédito" ou "Aguardando Agendamento",
- Quando o cliente desiste da compra antes de assinar o contrato,
- Então o vendedor deve conseguir acionar o botão de perda e selecionar um motivo da lista exclusiva de Oportunidades.
- Cenário 2: Segregação de Motivos entre Lead e Oportunidade
- Dado que o operador está encerrando um Lead não convertido,
- Quando ele abre o campo "Motivo de Perda",
- Então o sistema deve exibir apenas os valores configurados para a picklist de Leads, impedindo a seleção de motivos exclusivos de Oportunidades.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Validação das listas padronizadas de motivos de perda pela equipe comercial BTP.
- Riscos/Premissas: Motivos de perda genéricos podem comprometer a qualidade dos relatórios estratégicos do Marketing.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: Lead em prospecção (testar lista de perda de Lead), Oportunidade em cotação (testar lista de perda de Opp), Oportunidade com contrato assinado (testar bloqueio do botão de perda).
### [SALESFORCE B2C / CPQ & SEGMENTAÇÃO] - Tipo de Negociação no Início da Oportunidade e Segmentação B2C/B2S por Ticket Médio
1. NARRATIVA DE NEGÓCIO
- Como Vendedor B2C e Administrador do Catálogo (CPQ)
- Quero selecionar o Tipo de Negociação no início da criação da Oportunidade e ter a segmentação automática entre B2C e B2S aplicada no carrinho por Ticket Médio
- Para que o sistema direcione o fluxo correto (Normal, Cortesia ou Swap) e carimbe automaticamente a categoria comercial sem intervenção manual do operador.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Padronização das regras comerciais BTP para classificação do tipo de negociação e segmentação de mercado no Salesforce CPQ.
- Regras: * Classificação do Tipo de Negociação no Início: A definição do tipo de negociação deve ser selecionada no início da criação da Oportunidade por meio de Record Types:
- Venda Normal.
- Venda Cortesia.
- Venda Swap (Permuta/Eventos).
- Segmentação Automática B2C vs B2S por Ticket Médio: A segmentação entre Varejo Residencial (B2C) e Pequenos Negócios/SOHO (B2S) é executada automaticamente pelo sistema no momento do cálculo do carrinho:
- Se o Ticket Médio total da cotação for inferior a R$ 800,00, a Oportunidade é classificada como B2C.
- Se o Ticket Médio total da cotação for igual ou superior a R$ 800,00, a Oportunidade é classificada como B2S.
- Unificação BTP: Eliminação de regras ou exceções regionais de segmentação.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Opportunity, Quote, QuoteLineItem.
- Automação / Lógica: * Record Types: Configuração dos tipos de registro Normal_Sale, Cortesia_Sale e Swap_Sale na Oportunidade.
- CPQ Price Rule / Flow: Cálculo do valor total do carrinho e atualização automática do campo Segment__c ("B2C" se < 800.00; "B2S" se >= 800.00).
- Integração / APIs: Envio do campo Segment__c nos payloads de ordem via MuleSoft para o Customer Core/ERP.
- Segurança e Acessos: Atribuição dos Record Types nos perfis das equipes de vendas B2C/B2S.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Seleção do Tipo de Negociação ao Criar Oportunidade
- Dado que o vendedor está iniciando a criação de uma nova Oportunidade,
- Quando o formulário é carregado,
- Então o sistema deve exigir a escolha do tipo de negociação entre "Venda Normal", "Venda Cortesia" ou "Venda Swap".
- Cenário 2: Segmentação Automática para B2S por Ticket Médio >= R$ 800,00
- Dado que uma Oportunidade do tipo "Venda Normal" está no carrinho de compras,
- Quando os produtos são adicionados e o valor total atinge R$ 850,00,
- Então o Salesforce deve atualizar o campo de segmento automaticamente para "B2S".
5. DEPENDÊNCIAS E RISCOS
- Dependências: Validação final pelo COI sobre as regras de produto CPF x CNPJ no catálogo B2C/B2S.
- Riscos/Premissas: Alterações no carrinho que reduzam o valor para menos de R$ 800,00 devem recalcular o segmento para B2C dinamicamente.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: Cotação total de R$ 350,00 (Segmento B2C), Cotação total de R$ 1.200,00 (Segmento B2S), Oportunidade do tipo "Venda Cortesia".
### [SALESFORCE B2C / DELIVERY & FIELD SERVICE] - Regra de Reagendamento e Cancelamento de Instalação por Insucesso de Contato (72h / 3 Tentativas)
1. NARRATIVA DE NEGÓCIO
- Como Despachante de Field Service e Agente de Backoffice
- Quero que o sistema controle as tentativas de contato para agendamento de instalação, transferindo a ordem para o Backoffice após 3 tentativas sem sucesso e cancelando a proposta após 72 horas
- Para que as agendas das equipes técnicas de campo não fiquem bloqueadas com ordens ociosas e as propostas inativas sejam limpas do pipeline.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Alinhamento de SLA e regras de contato para agendamento técnico de instalação no ecossistema BTP.
- Regras: * Tentativas de Contato no Delivery: A equipe de Field Service/Delivery realizará até 3 (três) tentativas de contato com o cliente para confirmação do agendamento da instalação.
- Transferência para Fila Comercial/Backoffice: Caso as 3 tentativas não obtenham sucesso, a ordem de serviço sai da fila do Delivery e é transferida automaticamente para a Fila do Backoffice Comercial (gerida pela equipe de Vendas) para reengajamento ativo.
- Cancelamento Automático após 72 Horas: Se o cliente permanecer sem contato/sucesso por 72 horas após a transferência para o Backoffice, a Ordem de Serviço e a Oportunidade são automaticamente canceladas/encerradas pelo sistema por insucesso de contato.
- Autonomia do Cliente: O cliente mantém a possibilidade de solicitar o reagendamento por canais digitais/WhatsApp enquanto a ordem estiver ativa.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Opportunity, Order, WorkOrder (Field Service), Task.
- Automação / Lógica: * Field Service Workflow / Flow: Contador de tentativas de contato (Contact_Attempts__c). Ao atingir = 3, alterar o proprietário do registro (OwnerId) para a Fila "Backoffice Comercial B2C".
- Scheduled Flow / Time-Based Action: Disparo programado para avaliar registros na fila do Backoffice há mais de 72 horas. Se Uncontacted_Time__c >= 72h, atualizar o status da Oportunidade/Ordem para "Cancelado - Insucesso de Contato".
- Integração / APIs: API TMF622 / MuleSoft enviando o status de cancelamento por insucesso para o ERP/Field Service.
- Segurança e Acessos: Acesso de edição na Ordem para perfis de Delivery e Backoffice Comercial.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Transferência do Delivery para o Backoffice após 3 Tentativas
- Dado que uma Ordem de Serviço de instalação está com a equipe de Delivery,
- Quando o operador registra a 3ª tentativa de contato sem sucesso com o cliente,
- Então o Salesforce deve transferir a Ordem de Serviço para a Fila "Backoffice Comercial B2C" e iniciar a contagem do SLA de 72 horas.
- Cenário 2: Cancelamento Automático da Proposta após 72 Horas sem Contato
- Dado que uma proposta está na Fila do Backoffice Comercial aguardando contato do cliente,
- Quando o tempo de permanência atinge 72 horas sem confirmação de agendamento,
- Então o sistema deve cancelar automaticamente a Ordem e a Oportunidade com o motivo "Cancelado - Insucesso de Contato em 72h".
5. DEPENDÊNCIAS E RISCOS
- Dependências: Alinhamento técnico com a gestão de Field Service/Delivery (Renato) para validação dos gatilhos de tentativa.
- Riscos/Premissas: Comunicação ineficiente no WhatsApp pode fazer ordens expirarem em 72h sem abordagem ativa do vendedor.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Desenvolvimento concluído conforme critérios de aceite.
- [ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
- [ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
- Massa de Teste Sugerida: Ordem em Delivery com 2 tentativas de contato, Ordem em Delivery atingindo a 3ª tentativa (deve mover para Backoffice), Ordem no Backoffice há 71h, Ordem no Backoffice atingindo 72h (deve ser cancelada automaticamente).[SALESFORCE B2C / GOVERNANÇA E COMPLIANCE] - Edição Restrita de Unidade Operacional por Escopo Regional
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas ou Agente de Backoffice B2C
- Quero que os dados do meu perfil (Empresa do Grupo, Regional, Canal de Entrada) sejam carregados automaticamente no início do fluxo , mantendo o campo "Unidade Operacional" editável apenas para as unidades pertencentes à minha regional.
- Para que a Brasil TecPar garanta o cumprimento das regras de compliance corporativo do COI/Octa , evitando que vendedores registrem vendas em unidades operacionais fora da sua alçada de atendimento.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na reunião de 18/08/2026, debateu-se que a plataforma legada permitia acessos irrestritos , o que gerava inconformidades operacionais. Os perfis são provisionados automaticamente via Senior/Octa. Contudo, vendedores e equipes de Backoffice atendem múltiplas unidades dentro de uma mesma regional.
- Regras:
- Carga Automática de Perfil: Ao iniciar o fluxo "Vendas PF", o Salesforce deve carregar automaticamente a Empresa do Grupo, a Gerência, o Canal de Entrada e a Regional com base no usuário logado.
- Restrição do Picklist de Unidade Operacional: O campo Unidade Operacional deve permanecer editável , mas seu conteúdo deve ser filtrado dinamicamente para exibir apenas as unidades operacionais associadas à Regional do usuário.
- Exceção de Backoffice: Perfis de Backoffice possuem permissões generalistas e poderão selecionar unidades e canais mais amplos conforme seu grupo de acesso.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: User, Account, Opportunity, User_Regional_Mapping__c (Objeto Customizado/Custom Metadata).
- Automação / Lógica: * Salesforce Flow / LWC (Screen Flow de Venda): Preenchimento automático de campos do contexto do usuário ($User).
- Field-Level Security (FLS) & Dependent Picklists / Dynamic Forms: Filtro de dependência entre Regional__c e Unidade_Operacional__c.
- Integração / APIs: Integração nativa de identidade (SSO) com Senior / Octa para provisionamento de Perfis e Permission Sets.
- Segurança e Acessos: Permission Set específico PS_B2C_Sales_User e PS_B2C_Backoffice_User definindo visibilidade de FLS.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Filtro de Unidades Operacionais para Vendedor Regional
- Dado que um vendedor pertencente à Regional São Paulo inicia o fluxo de nova venda,
- Quando ele chegar ao campo "Unidade Operacional",
- Então o sistema deve exibir no menu suspenso apenas as unidades operacionais vinculadas à Regional São Paulo.
- Cenário 2: Validação de perfil de Backoffice com permissão ampliada
- Dado que um usuário com o perfil Backoffice B2C inicia o lançamento de uma venda,
- Quando ele acessar o campo de seleção de Canal e Unidade,
- Então o sistema deve permitir a seleção de canais/unidades generalistas conforme seu grupo de acesso.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Mapeamento atualizado do de/para de Usuários x Regionais x Unidades Operacionais vindo do Octa/Senior.
- Riscos/Premissas: Risco de travamento de vendas caso o usuário seja transferido de regional no Octa e o mapeamento no Salesforce não seja atualizado em tempo real.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Fluxo de tela configurado com carga automática de dados e filtro dinâmico de Unidade Operacional.
- [ ] Perfis de Vendedor e Backoffice testados quanto à visibilidade de campos.
- Massa de Teste Sugerida: 1. Usuário Vendedor Regional SP (deve ver apenas unidades de SP). 2. Usuário Backoffice (deve visualizar a lista completa autorizada).
### [SALESFORCE B2C / ANÁLISE DE RISCO] - Sinalização de Endereço Inadimplente (Flag) e Relatório Estratégico pós-Venda
1. NARRATIVA DE NEGÓCIO
- Como Gestor Comercial e de Risco B2C
- Quero que o Salesforce apenas exiba uma marcação (flag) indicando histórico de inadimplência no endereço consultado sem aplicar bloqueio automático ou exigir aprovação manual do coordenador durante a venda.
- Para que a operação mantenha a fluidez da jornada de atendimento ao cliente final sem gerar gargalos , permitindo análises estratégicas e ações de retenção/cancelamento posteriores.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na reunião de 18/08/2026, debateu-se a prática de "rodízio de CPF" em endereços com dívidas ativas. A proposta inicial de travar a venda e exigir aprovação do coordenador foi descartada por inviabilidade operacional (gargalo comercial e facilidade de desvio alterando o complemento do endereço).
- Regras:
- Não Bloqueio na Venda: A identificação de débitos anteriores associados ao endereço de instalação não deve travar o avanço do vendedor na tela.
- Sinalização Visual (Flag): Se a consulta de histórico retornar pendências no endereço, o sistema deve registrar a marcação Flag_Endereco_Inadimplente = TRUE no registro da Oportunidade.
- Relatório Gerencial pós-Venda: O Salesforce deve disponibilizar um relatório estratégico contendo todas as vendas concluídas em endereços sinalizados para tratativa posterior da equipe de Risco/Cobrança.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Lead, Opportunity, Address__c / Account.
- Automação / Lógica: * Salesforce Flow (Record-Triggered): Atribui o valor TRUE ao campo customizado Flag_Endereco_Inadimplente__c com base na resposta do webhook de histórico de endereço.
- Salesforce Reports & Dashboards: Criação do relatório nativo "Vendas em Endereços com Histórico de Inadimplência".
- Integração / APIs: Chamada via Integration Procedure / REST API para busca do histórico de débitos do logradouro/CEP no Customer Core ou BSS.
- Segurança e Acessos: Visibilidade da flag na tela de Oportunidade para todos os usuários; acesso ao relatório restrito a Coordenadores e Gerentes.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Consulta de endereço inadimplente sem bloqueio da venda
- Dado que o vendedor insere um endereço de instalação que possui histórico de faturas não pagas,
- Quando o sistema executa a verificação via API,
- Então o Salesforce deve marcar o campo Flag_Endereco_Inadimplente como ativo e permitir que o vendedor avance normalmente para a seleção de produtos.
- Cenário 2: Consolidação em relatório gerencial
- Dado que uma venda foi concluída em um endereço com a flag ativada,
- Quando a Oportunidade for avançada para os estágios subsequentes,
- Então o registro deve figurar automaticamente no relatório "Vendas em Endereços Inadimplentes" para auditoria gerencial.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Validação da API de histórico de inadimplência de endereço junto à equipe de TI/Davi.
- Riscos/Premissas: Endereços com padronização incorreta de CEP/Complemento (ex: "Casa A", "Fundos") podem gerar falsos negativos ou duplicidades.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Campo customizado Flag_Endereco_Inadimplente__c criado no objeto Oportunidade.
- [ ] Lógica de preenchimento sem bloqueio de tela homologada.
- [ ] Relatório gerencial B2C criado e testado.
- Massa de Teste Sugerida: 1. Endereço limpo (Flag = FALSE). 2. Endereço com contrato cancelado por Woff/Inadimplência (Flag = TRUE, venda concluída sem travamento de tela).
### [SALESFORCE B2C / JORNADA DE CONTRATAÇÃO] - Resumo do Pedido e Seleção da Modalidade de Assinatura
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas B2C
- Quero visualizar a tela de Resumo da Venda com a consolidação de todos os dados do pedido e selecionar a modalidade de aceite do contrato (Digital, Evidência/Anexo ou Biometria Facial).
- Para que eu possa conferir as informações junto ao cliente antes do envio e garantir a formalização jurídica adequada da contratação.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na reunião de 19/08/2026, consolidaram-se os campos essenciais que devem compor a tela de resumo e as três opções para coleta de assinatura do contrato.
- Regras:
- Exibição do Resumo: A tela "Resumo da Venda" deve exibir obrigatoriamente: Nome Completo do Cliente, Número da Conta, Número do Pedido Salesforce, Produtos/Combos Selecionados, Período de Fidelidade/Carência, Valores Totais, Endereço de Instalação e Dados de Faturamento.
- Opções de Assinatura: O sistema deve apresentar um campo seletor com três opções:
- Digital: Dispara link via WhatsApp/E-mail para o cliente.
- Por Anexo / Evidência: Habilita o upload manual de arquivo (documento assinado ou comprovante).
- Biometria Facial: Dispara fluxo de validação biométrica no dispositivo.
- Bloqueio de Perda de Venda: O botão de registrar "Perda de Venda" fica desabilitado imediatamente após o aceite/assinatura do contrato.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Opportunity, Quote, Order, ContentDocument (Anexos).
- Automação / Lógica: * OmniStudio FlexCard / LWC: Componente visual de resumo de pedido.
- Screen Flow: Apresentação do seletor Modo_Assinatura__c. Se a opção escolhida for "Anexo", exibe o componente lightning-file-upload.
- Integração / APIs: REST API para envio de contrato digital ou integração com motor de Biometria Facial.
- Segurança e Acessos: Acesso de escrita no objeto Order e permissão de upload de arquivos (ContentVersion).
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Assinatura por Anexo/Evidência com Upload Obrigatório
- Dado que o vendedor está na tela de Resumo da Venda,
- Quando ele selecionar a modalidade de assinatura "Por Anexo",
- Então o Salesforce deve abrir a janela de upload de documento e só permitir o avanço do fluxo após a confirmação do anexo.
- Cenário 2: Desabilitação do botão de perda pós-assinatura
- Dado que o contrato foi assinado pelo cliente,
- Quando o status do contrato atualizar para Assinado,
- Então o botão "Perder Venda" deve ficar indisponível na interface.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Definição final e disponibilização do serviço de Biometria Facial junto à TI.
- Riscos/Premissas: Upload de arquivos em formatos não suportados ou que excedam os limites de tamanho do Salesforce Files.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Tela de resumo contendo todos os atributos validados em reunião.
- [ ] Fluxos de assinatura por link, anexo e biometria configurados.
- Massa de Teste Sugerida: 1. Pedido B2C completo (conferir dados no resumo e testar upload de evidência).
### [SALESFORCE B2C / MARKETING CLOUD] - Régua Automática de Lembretes de Assinatura e Expiração da Oportunidade (SLA 5 Dias)
1. NARRATIVA DE NEGÓCIO
- Como Gestor Comercial B2C
- Quero que o Salesforce e o Marketing Cloud executem uma régua de comunicação com até 3 disparos automatizados durante um período máximo de 5 dias no pipeline para propostas aguardando assinatura, cancelando automaticamente a Oportunidade caso não haja aceite.
- Para que a operação automatize a cobrança do cliente, reduza o tempo de ciclo da venda e evite propostas pendentes acumuladas no pipeline dos vendedores.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na reunião de 19/08/2026, ajustou-se que manter propostas por 15 ou 30 dias era excessivo. Definiu-se o SLA rígido de 5 dias no pipeline , com até 3 lembretes estratégicos via WhatsApp/E-mail.
- Regras:
- Permanência no Pipeline: Oportunidades no estágio Aguardando Assinatura permanecerão ativas por no máximo 5 dias.
- Régua de Comunicação (3 Disparos):
- Disparo 1: 15 minutos após o lançamento da venda.
- Disparo 2: D+1 após a criação da proposta.
- Disparo 3: D+3 após a criação da proposta.
- Janela de Comunicação: Disparos devem respeitar a janela das 08:00 às 20:00.
- Encerramento Sistemático: Se ao término do  dia o contrato não for assinado, o sistema atualizará o estágio para Perdido por Falta de Assinatura e moverá o registro para o relatório gerencial.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Opportunity, Quote, Task.
- Automação / Lógica: * Salesforce Flow (Scheduled-Triggered): Executa varredura diária. Se Data_Envio_Contrato__c + 5 dias <= HOJE(), atualiza estágio para Closed Lost.
- Marketing Cloud / Journey Builder: Lógica de entrada baseada na fase do pedido e Exit Criteria configurado para interromper a jornada caso o status mude para Contrato Assinado.
- Integração / APIs: Webhook de retorno da plataforma de assinatura digital notificando o aceite do contrato.
- Segurança e Acessos: Acesso de leitura/escrita no objeto Oportunidade via Usuário de Integração do Marketing Cloud.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Primeiro disparo de lembrete pós 15 minutos
- Dado que um contrato foi enviado ao cliente e a Oportunidade está em Aguardando Assinatura,
- Quando decorrerem 15 minutos sem a confirmação de assinatura,
- Então o sistema deve disparar o  lembrete automático via WhatsApp/E-mail contendo o link de aceite.
- Cenário 2: Cancelamento automático no 5º dia
- Dado que uma proposta está aguardando assinatura há 5 dias completos,
- Quando o Job de expiração for executado,
- Então o Salesforce deve marcar a Oportunidade como Perdida (Closed Lost) com o motivo Falta de Assinatura e notificar o vendedor proprietário.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Integração ativa do Marketing Cloud Connect com instâncias de WhatsApp e E-mail.
- Riscos/Premissas: Bloqueios de SPAM em números de WhatsApp do cliente; necessidade de validar modelos de mensagem previamente aprovados pela Meta.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Fluxo de cancelamento por SLA de 5 dias criado e testado.
- [ ] Jornada do Journey Builder configurada com disparos em 15 min, D+1 e D+3.
- Massa de Teste Sugerida: 1. Oportunidade com contrato enviado há 15 min (validar mensagem). 2. Oportunidade enviada há 5 dias (validar alteração para Closed Lost).
### [SALESFORCE B2C / COBRANÇA E CRÉDITO] - Abertura de Ticket de Débito Interno via Zendesk e SLA de Regularização
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas B2C
- Quero que, ao identificar um débito interno de um cliente durante a análise de elegibilidade, o Salesforce abra automaticamente um chamado de renegociação no Zendesk para a equipe de Cobrança e mantenha a Oportunidade em meu pipeline por até 5 dias.
- Para que a cobrança atue na regularização financeira do cliente sem que eu precise sair do ambiente do CRM , permitindo a retomada automática da venda após a confirmação da baixa bancária.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na reunião de 19/08/2026, definiu-se que o vendedor não deve negociar dívidas internas diretamente. O sistema abrirá um ticket no Zendesk para o time de Cobrança tratar. A Oportunidade fica pausada por 5 dias no pipeline do vendedor.
- Regras:
- Abertura Automática de Chamado: Identificado o débito interno, o Salesforce enviará um payload via API para abertura automática de ticket no Zendesk da equipe de Cobrança.
- SLA de Espera de Baixa (5 Dias): A Oportunidade permanecerá no pipeline do vendedor com o status Aguardando Pagamento de Débito Interno por até 5 dias.
- Retomada Automática por Baixa Bancária: Um Job diário/Webhook captura a confirmação de baixa do débito vinda do SAP/BSS. O sistema altera a Oportunidade para Liberada e notifica o vendedor para avançar com o faturamento e agendamento.
- Cancelamento por Excesso de Prazo: Se o pagamento não ocorrer em 5 dias, a Oportunidade é marcada como Perdida por Débito Interno Não Quitado.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Opportunity, Account, Task.
- Automação / Lógica: * Salesforce Flow: Dispara chamada de API de integração com Zendesk na identificação de débito.
- Scheduled Flow / Batch Apex: Executa varredura diária das oportunidades em Aguardando Pagamento de Débito Interno há  dias para alteração para Closed Lost.
- Integração / APIs: * Outbound REST API para a plataforma Zendesk (abertura de ticket).
- Inbound Callback/Webhook do BSS/SAP notificando a liquidação da dívida.
- Segurança e Acessos: Campos de detalhe de débitos visíveis na Oportunidade.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Abertura automática de ticket de cobrança no Zendesk
- Dado que o retorno da análise de crédito indica a existência de um débito interno pendente,
- Quando a Oportunidade avançar para o status Aguardando Pagamento de Débito Interno,
- Então o Salesforce deve disparar uma requisição API criando um chamado no Zendesk da equipe de Cobrança com os dados do débito e do cliente.
- Cenário 2: Retomada automática da venda pós-baixa bancária
- Dado que o cliente realizou o pagamento do acordo promovido pela cobrança,
- Quando a API do BSS/SAP notificar a baixa bancária no Salesforce,
- Então o status da Oportunidade deve ser atualizado para Débito Quitado - Liberado para Venda e uma notificação de tarefas atribuída ao vendedor proprietário.
5. DEPENDÊNCIAS E RISCOS
- Dependências: API de abertura de chamados do Zendesk homologada e serviço de callback de baixa financeira do BSS/SAP ativo.
- Riscos/Premissas: Demora na compensação de boletos bancários (até 48h) pode ultrapassar o limite de 5 dias; opção de liberação manual pela Mesa de Crédito via anexo de comprovante tratada como exceção.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Integração Outbound Salesforce -> Zendesk configurada e testada.
- [ ] Endpoint Inbound de baixa de pagamento testado.
- [ ] Job de cancelamento após 5 dias sem baixa validado.
- Massa de Teste Sugerida: 1. Cliente com débito interno de R$ 200 (validar ticket Zendesk). 2. Injeção de payload de baixa do débito (validar liberação automática da Oportunidade).
### [SALESFORCE B2C / MESA DE CRÉDITO & FIELD SERVICE] - Solicitacão de Desconto na Taxa de Ativação e Agendamento pós-Baixa via Chatbot
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas B2C
- Quero solicitar aprovação da Mesa de Crédito quando um cliente negativado recusar o valor integral da Taxa de Ativação (R$ 149,90), e garantir que o agendamento da instalação pelo Chatbot ocorra apenas após a confirmação da baixa bancária dessa taxa.
- Para que a empresa mantenha a alçada de descontos centralizada na Mesa de Crédito e garanta que o time de campo (Field Service) seja despachado apenas para clientes financeiramente regularizados.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na reunião de 19/08/2026, confirmou-se que o vendedor não tem autonomia para alterar a taxa de R$ 149,90. O pedido de desconto (0% a 100%) é submetido à Mesa de Crédito. Uma vez aceito e pago, o agendamento no Field Service é acionado por robô de autoatendimento no WhatsApp.
- Regras:
- Alçada Exclusiva da Mesa de Crédito: Vendedores não possuem permissão para alterar o valor da taxa de ativação diretamente na cotação. A solicitação é enviada para a Mesa de Crédito via fluxo de aprovação.
- Desfechos da Mesa: A Mesa de Crédito pode: (1) Negar o desconto, (2) Conceder desconto parcial ou (3) Isentar 100% da taxa. Se o cliente recusar o parecer negado/parcial, a Oportunidade é encerrada como Perdida.
- Bloqueio do Agendamento Técinco: A tela e o botão de agendamento de visita técnica permanecem bloqueados enquanto a taxa de ativação não for quitada.
- Autoagendamento via Chatbot: Confirmada a baixa bancária no BSS, o sistema aciona o Chatbot no WhatsApp oferecendo os slots do Field Service ao cliente. A resposta do cliente aloca o slot no FSL automaticamente.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Opportunity, Quote, ServiceAppointment (Field Service), ApprovalProcess.
- Automação / Lógica: * Approval Process / Flow: Roteamento da solicitação de desconto da taxa de ativação para a fila da Mesa de Crédito.
- Salesforce Field Service (FSL): Lógica de liberação de criação de ServiceAppointment condicionada à flag Taxa_Ativacao_Paga__c = TRUE.
- Integração / APIs: * REST API com o Chatbot do WhatsApp/Zendesk para consulta e reserva de slots de agenda.
- Callback de baixa financeira vindo do BSS/SAP.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Envio de solicitação de desconto para a Mesa de Crédito
- Dado que o cliente possui restrição no Serasa e é elegível mediante taxa de R$ 149,90,
- Quando o vendedor selecionar a opção "Solicitar Desconto na Taxa" e informar a justificativa,
- Então o sistema deve disparar o Processo de Aprovação enviando a Oportunidade para a fila da Mesa de Crédito e bloqueando edições na cotação.
- Cenário 2: Agendamento automático no Field Service via WhatsApp pós-baixa
- Dado que o cliente efetuou o pagamento da taxa de ativação aprovada,
- Quando a API do BSS confirmar o pagamento no Salesforce,
- Então o sistema deve acionar o Chatbot no WhatsApp para que o cliente escolha a data/período de instalação e, ao receber a resposta, gravar o ServiceAppointment no FSL.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Motor do Salesforce Field Service (FSL) com regras de capacidade e slots por região configurados.
- Riscos/Premissas: Se o cliente não responder ao Chatbot para agendar, a Oportunidade figura no dashboard de acompanhamento gerencial para que o vendedor realize intervenção manual.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Processo de Aprovação de Desconto de Taxa para a Mesa de Crédito criado e testado.
- [ ] Trava de agendamento pré-pagamento da taxa validada.
- [ ] Integração com Chatbot para alocação automática de slot no FSL homologada.
- Massa de Teste Sugerida: 1. Oportunidade com desconto de taxa solicitado (validar fila da Mesa de Crédito). 2. Baixa de taxa injetada via API (validar mensagem do Chatbot e criação do agendamento no FSL).
### [SALESFORCE B2C / CATALOG & CPQ] - Seleção Guiada de Produtos, Formação de Combos/Promoções e Filtro Dinâmico por Endereço
1. NARRATIVA DE NEGÓCIO
- Como Consultor de Vendas B2C ou Cliente da jornada de autosserviço (E-commerce / App)
- Quero visualizar e adicionar ao carrinho de cotação apenas as ofertas e combos promocionais elegíveis e com viabilidade técnica para o endereço selecionado , podendo compor e customizar pacotes (Internet + SVAs/Streaming)
- Para que a Brasil TecPar garanta uma venda guiada sem erros de oferta , evite a comercialização de serviços indisponíveis na região e aumente o Ticket Médio/ARPU de forma automatizada e segura.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
- Contexto: Na jornada de vendas B2C/B2S, a exibição de produtos no carrinho deve ser estritamente qualificada pelo endereço de instalação do cliente (cidade/IBGE e disponibilidade de rede) . Para evitar a inflação e duplicação física do catálogo no CPQ, o agrupamento de promoções/combos utiliza o objeto nativo Promotion . As promoções combinam Banda Larga e Serviços de Valor Agregado (SVAs/Streaming como HBO Max, Disney, etc.) .
- Regras:
- Filtro Dinâmico por Endereço e Viabilidade (Tetra-pé): O motor de regras do Salesforce CPQ/EPC deve filtrar instantaneamente a prateleira de produtos utilizando o contexto de Segmento, Canal, Tipo de Documento (CPF/CNPJ) e Cidade/Zona de Disponibilidade (Código IBGE) combinados com o retorno da Viabilidade Técnica de Rede . Produtos e velocidades sem viabilidade no endereço informado não devem ser exibidos no carrinho.
- Composição de Combos via Objeto Promotion: A oferta de combos (ex: Internet 700MB + HBO Max) deve ser configurada associando os produtos individuais através do objeto Promotion, sem criar um terceiro produto unificado no catálogo .
- Destinação do Desconto Promocional (Adjustment Fixo): O desconto comercial da promoção (ex: R$ 10,00 ou R$ 50,00) deve ser aplicado como um valor de ajuste fixo (adjustment) diretamente sobre o item SVA/Streaming, mantendo a internet faturada pelo seu valor original de tabela de preços por razões tributárias e fiscais.
- Customização no Carrinho e Recálculo: O cliente/vendedor pode alterar a velocidade da internet ou adicionar SVAs avulsos diretamente dentro do carrinho. O motor do CPQ reprocessa e atualiza o valor total da cotação em tempo real (Reprice).
- Rastreabilidade via Group Promotion ID: Toda ordem gerada a partir de uma composição promocional no carrinho deve gravar o identificador Group Promotion ID nos itens do pedido para rastreabilidade no BSS/OMS .
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
- Objetos Impactados: Product2, Pricebook2, PricebookEntry, Quote, QuoteLineItem, Opportunity, vlocity_cmt__Promotion__c (Promotion), vlocity_cmt__ProductChildItem__c.
- Automação / Lógica: * Salesforce CPQ / EPC (OmniStudio): Matriz de elegibilidade por contexto (IBGE/Zona de Disponibilidade e Viabilidade) .
- CPQ Calculation Engine & Cart LWC: Execução de chamadas de regras de preço (Price Rules) e regras de produto (Product Rules / Option Constraints) no momento da adição ou alteração de atributos no carrinho .
- Integração / APIs: * REST API com Motor de Viabilidade Técnica (Geosites/MK/Customer Core) para envio do CEP/Endereço e retorno das zonas técnicas ativas .
- CPQ Calculation API / Digital Commerce API para cálculo de descontos promocionais e atualizações de carrinho em tempo real .
- Segurança e Acessos: FLS nos campos de valores e descontos; permissão de acesso ao catálogo via Permission Set PS_B2C_CPQ_Sales.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
- Cenário 1: Exibição de Produtos e Combos Filtrados pelo Endereço de Instalação
- Dado que o vendedor inseriu o endereço de instalação qualificado para a Cidade/IBGE "X" e com viabilidade técnica de fibra confirmada ,
- Quando a tela de seleção do catálogo for aberta ,
- Então o Salesforce CPQ deve exibir apenas as opções de internet e combos promocionais elegíveis para aquele endereço , omitindo planos e velocidades sem cobertura técnica na região.
- Cenário 2: Adição de Combo Promocional com Desconto Direcionado ao SVA
- Dado que o consultor selecionou o combo promocional "Internet 700MB + HBO Max" ,
- Quando o combo for inserido no carrinho de cotação ,
- Então o sistema deve aplicar o valor do desconto fixo exclusivamente sobre a linha do produto HBO Max (SVA) e gravar o identificador Group Promotion ID no cabeçalho/linhas da cotação .
- Cenário 3: Customização de Atributos no Carrinho e Recálculo Dinâmico
- Dado que um combo promocional está adicionado ao carrinho,
- Quando o usuário alterar o atributo de velocidade da internet (ex: de 600MB para 700MB) ou adicionar um SVA opcional adicional,
- Então o motor do CPQ deve reprocessar o cálculo do carrinho em tempo real , somando a diferença de valor da nova velocidade ao montante mensal total da cotação.
5. DEPENDÊNCIAS E RISCOS
- Dependências: Modelagem completa da estrutura de produtos e promoções no EPC (Enterprise Product Catalog) e cadastramento das tabelas de preços regionalizadas (IBGE).
- Riscos/Premissas: Performance nas chamadas da API de cálculo do CPQ durante a navegação no carrinho com múltiplos SVAs adicionados; garantia de resposta da API de viabilidade em  segundos para não engargalar o fluxo do vendedor .
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
- [ ] Rulesets de elegibilidade por IBGE/Viabilidade configurados e validados no CPQ/EPC .
- [ ] Objeto Promotion configurado com desconto fixo em SVA e tag Group Promotion ID herdada na Ordem .
- [ ] Tela do carrinho (LWC/OmniScript) reprocessando alterações de atributos e SVAs adicionais em tempo real .
- Massa de Teste Sugerida:
- CEP/Endereço em região com viabilidade para Fibra 700MB (validar exibição do produto e combo HBO Max) .
- CEP/Endereço em região sem viabilidade técnica de Fibra (validar ocultação do produto de banda larga no carrinho) .
- Adição de Combo 700MB + HBO Max com alteração de velocidade no carrinho (validar desconto em SVA e recálculo do valor total) .