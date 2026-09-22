# Conciliacao das historias B2B e B2C com as Works do Agile Accelerator (producao) - 22/09/2026

Org: btp-prod, diegomoraes.t@brasiltecpar.com.br, https://prod-brasiltecpar.my.salesforce.com, Organization 00DHu00000FcxIgMAJ (IsSandbox = false, instancia BRA38, Enterprise). Levantamento em 22/09/2026, 14h30 a 15h40 (horario de Brasilia). Fases 0 a 4 somente leitura: nenhuma Work criada ou alterada.

## Resumo executivo

Historias nos documentos: 29 (B2B) + 38 (B2C) = 67, conferindo com a referencia. Superadas por versao mais recente no mesmo documento: 8. Vigentes: 59.

| Classe | B2B | B2C | Total |
|---|---|---|---|
| EXISTE_ALINHADA | 7 | 21 | 28 |
| EXISTE_DESATUALIZADA | 8 | 9 | 17 |
| PARCIAL | 2 | 4 | 6 |
| NAO_EXISTE | 5 | 3 | 8 |
| NAO_EXISTE_BLOQUEADA | 0 | 0 | 0 |
| DUPLICADA | 0 | 0 | 0 |
| SUPERADA (fora da conciliacao) | 7 | 1 | 8 |

Works a criar (NAO_EXISTE + complementares das PARCIAL): **14** (7 B2B, 7 B2C), nenhuma bloqueada por negocio. Works do programa sem historia nos documentos (ORFA): 46, todas tecnicas ou de catalogo, sem acao. Duplicadas: nenhuma. Candidatas a historia nova vindas dos comentarios: 5.

Padrao das Works existentes (Fase 2), reproduzido nas novas: Record Type User Story (012V2000009Qk5dIAC), Product Tag Salesforce (a8bV200000001NVIAY, usado por 88 works), Scrum Team SysMap, Assignee Davi Israel de Abreu, Product Owner Priscila De Lima, Type "User Story" (valor em uso nas 111 works; picklist nao restrita), Status New, descricao em texto simples no campo agf__Details__c (os 93 do programa usam so esse campo), criterios de aceite no objeto agf__ADM_Acceptance_Criterion__c (226 registros em 73 works, ultimo em 15/09, nome "Criterio n - titulo"). Epico das B2B por tema (1) a 7)), como as existentes; B2C no epico "B2C - Jornadas...". Prioridade, Story Points, Sprint e Backlog Rank ficam vazios. Os dois .docx nao aparecem em ContentDocumentLink dos epicos (anexo nao localizado por consulta).

## Tabela completa: historia x Work x classe x confianca

| id_local | Onda | Titulo | Classe | Work | Conf. | Observacao |
|---|---|---|---|---|---|---|
| B2B-01 | Consolidado inicial | Escalonamento de Inatividade de Leads B2B e Enriquecimento via Econoda | EXISTE_ALINHADA | W-000096 | A | cobertura 0,90; 21 comentarios, 3 bloqueios (listagem com a Tayza; regra de guarda de contato) |
| B2B-02 | Consolidado inicial | Endereçamento Geocodificado, Viabilidade Expressa e Roteamento de Pré- | EXISTE_ALINHADA | W-000097 | A | cobertura 0,82; 16 comentarios |
| B2B-03 | Consolidado inicial | Cotação Multi-Site, Alçadas de Desconto/Trading e Geração de Proposta  | SUPERADA por B2B-12 | | | mesmo escopo (cotacao multi-site, alcadas, proposta); B2B-12 de 09/09 reescreve com trading, validade e alcadas |
| B2B-04 | Consolidado inicial | Solicitação de Cancelamento B2B, Esteiras de Retenção e Cálculo de Mul | SUPERADA por B2B-24 | | | mesmo escopo (cancelamento B2B, retencao, multa); B2B-13 (09/09) e B2B-24 (mais abaixo) reescrevem; vale B2B-24 |
| B2B-05 | Consolidado inicial | Alteração Contratual B2B (Upgrade/Swap) com Espelhamento de Ativos e D | SUPERADA por B2B-22 | | | upgrade/swap: desdobrado em B2B-21 (swap), B2B-22 (upgrade com refidelizacao) e B2B-23 (upgrade sem); vale a versao mais recente |
| B2B-06 | Consolidado inicial | Auditoria de Vendas B2B pelo BKO, Análise de Crédito/Débitos e Handoff | EXISTE_ALINHADA | W-000101 | A | cobertura 0,90; 7 comentarios, 2 bloqueios (processo dos GRs a discutir) |
| B2B-07 | Histórias da reunião de 01/09/2026 | Rastreio Comercial e Identificação de Parceiros na Jornada do Lead à O | EXISTE_DESATUALIZADA | W-000120 | B | cobertura 0,55: faltam anexo obrigatorio, verificacao pos-venda e identificacao de parceiro na negociacao |
| B2B-08 | Histórias da reunião de 01/09/2026 | Configuração de Taxa Única (CAPEX) no Carrinho B2B | EXISTE_DESATUALIZADA | W-000121 | B | W-000121 e a modelagem no catalogo (CAT-CPX-01); a historia pede a taxa unica no carrinho B2B e no resumo ao cliente; cobertura 0,50 |
| B2B-09 | Histórias da reunião de 01/09/2026 | Geração de Contrato Padrão e Obrigatoriedade de Signatário Legal | SUPERADA por B2B-15 | | | mesmo escopo (geracao de contrato e signatario legal); B2B-15 de 09/09 acrescenta NPS e armazenamento externo |
| B2B-10 | Histórias da reunião de 01/09/2026 | Restrição de Edição pelo BKO e Bypass de Arquitetura para Vendas Expre | NAO_EXISTE |  |  | bypass de arquitetura para vendas expressas e restricao de edicao pelo BKO; W-000101 cobre so a auditoria |
| B2B-11 | Histórias da reunião de 01/09/2026 | Estruturação de Motivos e Submotivos para Perda de Leads e Oportunidad | SUPERADA por B2B-16 | | | titulo identico; B2B-16 (09/09) e a versao mais recente |
| B2B-12 | Adicionada em 09/09/26 | Cotação Multi-Site, Trading, Validade de Proposta e Alçadas B2B | EXISTE_ALINHADA | W-000098 | A | cobertura 0,85; versao 09/09 refletida nas notas da work |
| B2B-13 | Adicionada em 09/09/26 | Solicitação de Cancelamento B2B, Retenção e Calculadoras Predicionais | SUPERADA por B2B-24 | | | mesmo escopo de B2B-24 (cancelamento, esteira de retencao, billing stop), que esta mais abaixo no documento |
| B2B-14 | Adicionada em 09/09/26 | Visão 360º, Alteração Contratual B2B e Refidelização Intencional | SUPERADA por B2B-22 | | | mesmo escopo de B2B-22 (alteracao contratual com refidelizacao intencional); a parte "Visao 360" nao tem bloco proprio no documento e ja existe como W-000123 |
| B2B-15 | Adicionada em 09/09/26 | Geração de Contrato, Contato de NPS e Armazenamento Externo | EXISTE_DESATUALIZADA | W-000122 | B | cobertura 0,45: faltam armazenamento externo, contato de NPS na etapa contratual e integracao matinal |
| B2B-16 | Adicionada em 09/09/26 | Estruturação de Motivos e Submotivos para Perda de Leads e Oportunidad | NAO_EXISTE |  |  | motivos e submotivos de perda com listas dependentes; nenhuma work |
| B2B-17 | Adicionada em 09/09/26 | Configuração e Precificação de Produtos na Modalidade Cortesia / Degus | NAO_EXISTE |  |  | cortesia B2B no CPQ; W-000115 e B2C (tipos de operacao sem faturamento) |
| B2B-18 | Adicionada em 09/09/26 | Aprovação Mandatória e Trava Comercial para Cortesias | NAO_EXISTE |  |  | aprovacao mandatoria e trava comercial para cortesias B2B |
| B2B-19 | Adicionada em 09/09/26 | Decomposição, Provisionamento e Handoff de Cortesia (Payload Faturamen | NAO_EXISTE |  |  | handoff de cortesia com payload de faturamento nulo (EOM) |
| B2B-20 | Adicionada em 09/09/26 | Automação de Fim de Degustação (Try & Buy) e Conversão de Contrato | EXISTE_DESATUALIZADA | W-000124 | A | cobertura 0,42: faltam automacao agendada de fim de periodo, retencao e conversao; 11 comentarios |
| B2B-21 | Adicionada em 09/09/26 | Negociação de Permuta de Serviços (Swap/SUAP) e Justificativa Comercia | PARCIAL | W-000100 | B | W-000100 (B2B-05) e guarda-chuva de upgrade/swap; swap/SUAP ganha work propria |
| B2B-22 | Adicionada em 09/09/26 | Upgrade de Serviços B2B COM Refidelização Contratual Intencional | EXISTE_DESATUALIZADA | W-000100 | B | W-000100 passa a corresponder ao upgrade COM refidelizacao; cobertura 0,62; 22 comentarios |
| B2B-23 | Adicionada em 09/09/26 | Upgrade de Serviços B2B SEM Refidelização Contratual (Manutenção da Vi | PARCIAL | W-000100 | B | upgrade SEM refidelizacao (vigencia original) ganha work propria |
| B2B-24 | Adicionada em 09/09/26 | Solicitação de Cancelamento B2B, Esteira Sequencial de Retenção e Bill | EXISTE_ALINHADA | W-000099 | A | cobertura 0,85; bloqueio: premissas da area de negocio pendentes (Fernanda 15/09) |
| B2B-25 | Adicionada em 09/09/26 | Downgrade Contratual B2B, Recálculo de Delta MRR e Apuração de Fidelid | EXISTE_DESATUALIZADA | W-000125 | A | cobertura 0,38: faltam delta MRR negativo, apuracao de carencia, recalculo |
| B2B-26 | Histórias novas | Refidelização Pura e Simples B2B (Renovação sem Alteração de Escopo) | EXISTE_DESATUALIZADA | W-000142 | A | cobertura 0,62; bloqueio: refidelizacao guarda-chuva aguarda diretoria; dados a apresentar (7 itens) |
| B2B-27 | Histórias novas | Gestão de Aviso Prévio de Cancelamento B2B, Tentativas de Reversão e C | EXISTE_ALINHADA | W-000143 | A | cobertura 0,80 |
| B2B-28 | Histórias novas | Configuração de Condições Especiais de Faturamento e Intervalos de Cob | EXISTE_ALINHADA | W-000144 | A | cobertura 0,82 |
| B2B-29 | Histórias novas | Cadência Automática de Notificações de Assinatura (Proposta e Contrato | EXISTE_DESATUALIZADA | W-000145 | A | cobertura 0,55: faltam horario/provedor dos disparos e testes automaticos |
| B2C-US-NEW-01 | Novas Histórias de Usuário (adicionadas ao escopo) | Etapa Manual: Preenchimento dos Dados de Faturamento e Parametrização  | EXISTE_ALINHADA | W-000081 | A | cobertura 0,88; 9 comentarios |
| B2C-US-NEW-02 | Novas Histórias de Usuário (adicionadas ao escopo) | Geração Dinâmica da Minuta do Contrato | EXISTE_ALINHADA | W-000082 | A | cobertura 0,80; W-000089 e a infraestrutura tecnica, nao duplicata |
| B2C-US-NEW-03 | Novas Histórias de Usuário (adicionadas ao escopo) | Guarda de Dados para Abordagens Futuras e Gestão de LGPD | EXISTE_ALINHADA | W-000083 | A | cobertura 0,85; 5 comentarios |
| B2C-US-01 | 1. Entrada & Qualificação de Lead | Ingestão Omnichannel de Leads (Carga Massiva Restrita, QR Code e Form) | EXISTE_ALINHADA | W-000071 | A | cobertura 0,90 |
| B2C-US-02 | 1. Entrada & Qualificação de Lead | Refatoração da Busca Global e Consulta no Customer Core | EXISTE_ALINHADA | W-000072 | A | cobertura 0,90; 12 comentarios |
| B2C-US-03 | 1. Entrada & Qualificação de Lead | Captura, Triagem e Roteamento Omni-Channel | EXISTE_ALINHADA | W-000057 | A | cobertura 0,70; 7 comentarios |
| B2C-US-04 | 1. Entrada & Qualificação de Lead | Categorização do Lead (Conversão em Opp ou Descarte como Perdido) | EXISTE_ALINHADA | W-000073 | A | cobertura 0,75 |
| B2C-US-05 | 2. Risco & Viabilidade | Antecipação da Consulta de Débito no Endereço (Pré-Viabilidade / Flag) | EXISTE_DESATUALIZADA | W-000060 | A | cobertura 0,40: faltam list view de acompanhamento, pagamentos pendentes e fluxo no OmniScript |
| B2C-US-06 | 2. Risco & Viabilidade | Consulta Simultânea de Viabilidade Técnica e Crédito B2C | EXISTE_ALINHADA | W-000074 | A | cobertura 0,80 |
| B2C-US-07 | 2. Risco & Viabilidade | Trilha Alternativa: Oferta Móvel Obrigatória em caso de Inviabilidade | EXISTE_DESATUALIZADA | W-000058 | A | cobertura 0,62: faltam distancia em metros da fibra e fase da oportunidade |
| B2C-US-08 | 2. Risco & Viabilidade | Tratamento de Débito Interno: Ticket Zendesk e SLA de 5 Dias | EXISTE_ALINHADA | W-000067 | A | cobertura 0,70; 7 comentarios |
| B2C-US-09 | 2. Risco & Viabilidade | Regra de Risco: Análise de Contratos sem 1ª Parcela (Gatilho 3º Contra | EXISTE_DESATUALIZADA | W-000059 | A | cobertura 0,55: faltam tratamento manual e regras diferenciadas por risco |
| B2C-US-10 | 3. CPQ, Cotação & Contrato | Tipo de Negociação e Segmentação B2C/B2S por Ticket (< R$ 800) | EXISTE_ALINHADA | W-000062 | A | cobertura 0,72; bloqueio: criterio de segmentacao B2C/B2S vai ao COI |
| B2C-US-11 | 3. CPQ, Cotação & Contrato | Seleção Guiada, Combos Promocionais e Filtro Dinâmico por IBGE | EXISTE_DESATUALIZADA | W-000069 | A | cobertura 0,60: faltam desconto promocional, velocidade 700MB e motor de combos |
| B2C-US-12 | 3. CPQ, Cotação & Contrato | Gestão da Taxa de Ativação (R$ 149,90) e Alçadas de Desconto | EXISTE_DESATUALIZADA | W-000068 | A | cobertura 0,45: faltam perfil de compras, agente de relacionamento e regras do carrinho; valor R$ 149,90 no doc x 149,99 na work |
| B2C-US-13 | 3. CPQ, Cotação & Contrato | Resumo da Venda e Seleção da Modalidade de Assinatura | EXISTE_ALINHADA | W-000065 | A | cobertura 0,75 |
| B2C-US-14 | 3. CPQ, Cotação & Contrato | Régua de Lembretes , Expiração da Oportunidade por SLA (5 Dias)Aguarda | EXISTE_ALINHADA | W-000066 | A | cobertura 0,80; titulo do doc acrescenta "aguardando pagamento ou taxa de ativacao" |
| B2C-US-15 | 3. CPQ, Cotação & Contrato | Recepção Inbound de Vendas 100% Digitais (Touchless Order API) | EXISTE_ALINHADA | W-000075 | A | cobertura 0,82 |
| B2C-US-16 | 4. Pagamento, Delivery & Field Service | Emissão, Notificação do Cliente, Comprovante e Mesa de Crédito | EXISTE_ALINHADA | W-000076 | A | cobertura 0,85 |
| B2C-US-17 | 4. Pagamento, Delivery & Field Service | Controle de Pagamento, Isenção de Taxa e Autoagendamento Bot | EXISTE_ALINHADA | W-000077 | A | cobertura 0,80 |
| B2C-US-18 | 4. Pagamento, Delivery & Field Service | List View Gerencial "Acompanhamento Baixa Bancária" | EXISTE_ALINHADA | W-000078 | A | cobertura 0,80 |
| B2C-US-19 | 4. Pagamento, Delivery & Field Service | Field Service: Reagendamento e Cancelamento por Insucesso (72h / 3 Ten | EXISTE_DESATUALIZADA | W-000063 | A | cobertura 0,68: faltam transferencia para a equipe e devolucao a oportunidade |
| B2C-US-20 | 5. Ativação & Encerramento | Relatório de Instalações Não Realizadas e Notificação Comercial | EXISTE_ALINHADA | W-000079 | A | cobertura 0,75 |
| B2C-US-21 | 5. Ativação & Encerramento | Ativação Final no Customer Core e Fechamento Oportunidade "Ganho" | EXISTE_ALINHADA | W-000080 | A | cobertura 0,75 |
| B2C-US-22 | 5. Ativação & Encerramento | Carga Automática de Perfil e Edição Restrita de Unidade Operacional | EXISTE_DESATUALIZADA | W-000064 | A | cobertura 0,68: faltam perfis operacionais e acessos dos vendedores |
| B2C-US-23 | 5. Ativação & Encerramento | Dashboard Gerencial Executivo e Árvore Segregada de Perdas | EXISTE_DESATUALIZADA | W-000061 | A | cobertura 0,53: faltam segregacao entre hierarquias e lista de leads aguardando |
| B2C-N01 | Novas histórias (01/09/2026) | Orquestração de Ativação e Provisionamento de Pedido B2C no Customer C | EXISTE_ALINHADA | W-000093 | A | cobertura 0,80 |
| B2C-N02 | Novas histórias (01/09/2026) | Geração e Despacho de Ordem de Serviço (Work Order) para Instalação Fí | EXISTE_ALINHADA | W-000094 | A | cobertura 0,80 |
| B2C-N03 | Novas histórias (01/09/2026) | Visão 360 Consolidada do Cliente B2C (Customer 360) | EXISTE_ALINHADA | W-000095 | A | cobertura 0,85 |
| B2C-N04 | Novas histórias (2ª leva) | Tratamento de Desligamento e Reversão de Plano Colaborador | NAO_EXISTE |  |  | desligamento e reversao de plano colaborador; nenhuma work |
| B2C-N05 | Novas histórias (2ª leva) | Relatório de Auditoria de Vendas (Cortesia e SWAP) com Débito Interno | NAO_EXISTE |  |  | relatorio de auditoria de vendas cortesia/swap com debito interno; nenhuma work |
| B2C-N06 | Novas histórias (2ª leva) | Jornada de Upgrade B2C com Regra de Refidelização Dinâmica (RGC Anatel | SUPERADA por B2C-N09 | | | mesmo escopo (upgrade B2C com refidelizacao); o bloco de 22/09 (N09) reescreve com trava de inadimplencia e guarda-chuva |
| B2C-N07 | Novas histórias 22/09 | Venda Cortesia com Aprovação Prévia e Faturamento Zerado | PARCIAL | W-000115 | B | W-000115 (B2C-30) e guarda-chuva dos tipos de operacao sem faturamento; venda cortesia ganha work propria |
| B2C-N08 | Novas histórias 22/09 | Venda Swap (Permuta) com Preço Flexível e Comprovação | PARCIAL | W-000115 | **C** | idem; venda swap com preco flexivel e comprovacao ganha work propria (cobertura 0,30) |
| B2C-N09 | Novas histórias 22/09 | Upgrade B2C com Trava de Inadimplência e Refidelização Guarda-Chuva | PARCIAL | W-000116 | **C** | W-000116 (B2C-32 mudanca de plano MACD) e generica; upgrade com trava de inadimplencia ganha work propria (cobertura 0,35) |
| B2C-N10 | Novas histórias 22/09 | Downgrade B2C com Isenção de Multa Condicionada à Refidelização | PARCIAL | W-000116 | **C** | idem; downgrade com isencao de multa condicionada ganha work propria (cobertura 0,40) |
| B2C-N11 | Novas histórias 22/09 | Sincronização Automática de Refidelização e Data de Reajuste Anual | NAO_EXISTE |  |  | sincronizacao de refidelizacao e data de reajuste anual; nenhuma work |
| B2C-N12 | Novas histórias 22/09 | Cancelamento Voluntário, Retenção e Desconexão Automática (Disconnect) | EXISTE_DESATUALIZADA | W-000129 | B | cobertura 0,40: faltam desconexao automatica (Disconnect), ordem de servico de retirada e assinatura |

Confianca: A = titulo e conteudo batem; B = conteudo bate, titulo diferente; **C** = match por tema, exige revisao do Diego (B2C-N08, N09, N10, todas PARCIAL sobre works guarda-chuva).

## Decisoes de versao (SUPERADA)

- B2B-03 (Cotação Multi-Site, Alçadas de Desconto/Trading e Geração de) -> vale B2B-12: mesmo escopo (cotacao multi-site, alcadas, proposta); B2B-12 de 09/09 reescreve com trading, validade e alcadas
- B2B-04 (Solicitação de Cancelamento B2B, Esteiras de Retenção e Cálc) -> vale B2B-24: mesmo escopo (cancelamento B2B, retencao, multa); B2B-13 (09/09) e B2B-24 (mais abaixo) reescrevem; vale B2B-24
- B2B-13 (Solicitação de Cancelamento B2B, Retenção e Calculadoras Pre) -> vale B2B-24: mesmo escopo de B2B-24 (cancelamento, esteira de retencao, billing stop), que esta mais abaixo no documento
- B2B-05 (Alteração Contratual B2B (Upgrade/Swap) com Espelhamento de ) -> vale B2B-22: upgrade/swap: desdobrado em B2B-21 (swap), B2B-22 (upgrade com refidelizacao) e B2B-23 (upgrade sem); vale a versao mais recente
- B2B-14 (Visão 360º, Alteração Contratual B2B e Refidelização Intenci) -> vale B2B-22: mesmo escopo de B2B-22 (alteracao contratual com refidelizacao intencional); a parte "Visao 360" nao tem bloco proprio no documento e ja existe como W-000123
- B2B-09 (Geração de Contrato Padrão e Obrigatoriedade de Signatário L) -> vale B2B-15: mesmo escopo (geracao de contrato e signatario legal); B2B-15 de 09/09 acrescenta NPS e armazenamento externo
- B2B-11 (Estruturação de Motivos e Submotivos para Perda de Leads e O) -> vale B2B-16: titulo identico; B2B-16 (09/09) e a versao mais recente
- B2C-N06 (Jornada de Upgrade B2C com Regra de Refidelização Dinâmica () -> vale B2C-N09: mesmo escopo (upgrade B2C com refidelizacao); o bloco de 22/09 (N09) reescreve com trava de inadimplencia e guarda-chuva

## EXISTE_DESATUALIZADA: diferencas (proposta de ajuste pelo time; nenhuma Work alterada)

- B2B-07 x W-000120: cobertura 0,55: faltam anexo obrigatorio, verificacao pos-venda e identificacao de parceiro na negociacao. Comentarios ancorados no documento: 2.
- B2B-08 x W-000121: W-000121 e a modelagem no catalogo (CAT-CPX-01); a historia pede a taxa unica no carrinho B2B e no resumo ao cliente; cobertura 0,50. Comentarios ancorados no documento: 2.
- B2B-15 x W-000122: cobertura 0,45: faltam armazenamento externo, contato de NPS na etapa contratual e integracao matinal. Comentarios ancorados no documento: 4.
- B2B-20 x W-000124: cobertura 0,42: faltam automacao agendada de fim de periodo, retencao e conversao; 11 comentarios. Comentarios ancorados no documento: 11.
- B2B-22 x W-000100: W-000100 passa a corresponder ao upgrade COM refidelizacao; cobertura 0,62; 22 comentarios. Comentarios ancorados no documento: 22.
- B2B-25 x W-000125: cobertura 0,38: faltam delta MRR negativo, apuracao de carencia, recalculo. Comentarios ancorados no documento: 10.
- B2B-26 x W-000142: cobertura 0,62; bloqueio: refidelizacao guarda-chuva aguarda diretoria; dados a apresentar (7 itens). Comentarios ancorados no documento: 7.
- B2B-29 x W-000145: cobertura 0,55: faltam horario/provedor dos disparos e testes automaticos. Comentarios ancorados no documento: 0.
- B2C-US-05 x W-000060: cobertura 0,40: faltam list view de acompanhamento, pagamentos pendentes e fluxo no OmniScript. Comentarios ancorados no documento: 4.
- B2C-US-07 x W-000058: cobertura 0,62: faltam distancia em metros da fibra e fase da oportunidade. Comentarios ancorados no documento: 0.
- B2C-US-09 x W-000059: cobertura 0,55: faltam tratamento manual e regras diferenciadas por risco. Comentarios ancorados no documento: 1.
- B2C-US-11 x W-000069: cobertura 0,60: faltam desconto promocional, velocidade 700MB e motor de combos. Comentarios ancorados no documento: 0.
- B2C-US-12 x W-000068: cobertura 0,45: faltam perfil de compras, agente de relacionamento e regras do carrinho; valor R$ 149,90 no doc x 149,99 na work. Comentarios ancorados no documento: 5.
- B2C-US-19 x W-000063: cobertura 0,68: faltam transferencia para a equipe e devolucao a oportunidade. Comentarios ancorados no documento: 2.
- B2C-US-22 x W-000064: cobertura 0,68: faltam perfis operacionais e acessos dos vendedores. Comentarios ancorados no documento: 0.
- B2C-US-23 x W-000061: cobertura 0,53: faltam segregacao entre hierarquias e lista de leads aguardando. Comentarios ancorados no documento: 1.
- B2C-N12 x W-000129: cobertura 0,40: faltam desconexao automatica (Disconnect), ordem de servico de retirada e assinatura. Comentarios ancorados no documento: 0.

## PARCIAL (works guarda-chuva)

- B2B-21 (Negociação de Permuta de Serviços (Swap/SUAP) e Justificativ) x W-000100: W-000100 (B2B-05) e guarda-chuva de upgrade/swap; swap/SUAP ganha work propria. Proposta: criar work propria (no plano) e manter W-000100 como fundacao, sem alteracao.
- B2B-23 (Upgrade de Serviços B2B SEM Refidelização Contratual (Manute) x W-000100: upgrade SEM refidelizacao (vigencia original) ganha work propria. Proposta: criar work propria (no plano) e manter W-000100 como fundacao, sem alteracao.
- B2C-N07 (Venda Cortesia com Aprovação Prévia e Faturamento Zerado) x W-000115: W-000115 (B2C-30) e guarda-chuva dos tipos de operacao sem faturamento; venda cortesia ganha work propria. Proposta: criar work propria (no plano) e manter W-000115 como fundacao, sem alteracao.
- B2C-N08 (Venda Swap (Permuta) com Preço Flexível e Comprovação) x W-000115: idem; venda swap com preco flexivel e comprovacao ganha work propria (cobertura 0,30). Proposta: criar work propria (no plano) e manter W-000115 como fundacao, sem alteracao.
- B2C-N09 (Upgrade B2C com Trava de Inadimplência e Refidelização Guard) x W-000116: W-000116 (B2C-32 mudanca de plano MACD) e generica; upgrade com trava de inadimplencia ganha work propria (cobertura 0,35). Proposta: criar work propria (no plano) e manter W-000116 como fundacao, sem alteracao.
- B2C-N10 (Downgrade B2C com Isenção de Multa Condicionada à Refideliza) x W-000116: idem; downgrade com isencao de multa condicionada ganha work propria (cobertura 0,40). Proposta: criar work propria (no plano) e manter W-000116 como fundacao, sem alteracao.

## DUPLICADA

Nenhuma historia com mais de uma Work. Observacao entre orfas: W-000132 (TEC-DEV-01 esteira CI/CD) e W-000133 (INTEGRACOES - CI/CD GitLab) tratam o mesmo tema; proposta de unificacao pelo time, sem acao aqui.

## ORFA (works do programa sem historia nos dois documentos, sem acao)

- W-000051 | US EPC-01 — Criação das Attribute Categories do catálogo
- W-000052 | US EPC-04 — Hierarquia de Object Types, atribuição de atributos por nível e layouts
- W-000053 | US EPC-05 — Criação das Product Specifications das famílias da Onda 1
- W-000054 | US EPC-09 — Compilação de atributos, batch jobs e validação de integridade do catálogo
- W-000055 | US EPC-03 (P) — Dicionário de atributos com metadados de governança — escopo parcial, sem atributos 
- W-000056 | US QUAL-01 (P) — Qualificação de catálogo de ofertas comerciais via contexto de elegibilidade (Tetra
- W-000070 | US EPC-10 — Criação dos catálogos comerciais por família e estrutura B2B/B2C
- W-000084 | US TEC-B2C-01 — Botão "Criar Cotação" na Oportunidade (Industries CPQ Create Cart)
- W-000085 | US TEC-B2C-02 — Modelagem EPC das Ofertas Comerciais B2C (planos, SVAs, Promotions, taxa)
- W-000086 | US TEC-B2C-03 — Esqueleto do OmniScript "Nova Venda B2C" (Guided Selling)
- W-000087 | US TEC-B2C-04 — Fundação de Integrações (Named Credentials, IPs base e mapa TMF)
- W-000088 | US TEC-B2C-05 — Order Management: Decomposição e Plano de Orquestração B2C
- W-000089 | US TEC-B2C-06 — Infraestrutura de Geração de Documentos (Minuta de Contrato)
- W-000090 | US TEC-B2C-07 — Segurança e Acessos da Jornada B2C (Permission Sets, FLS e Filas)
- W-000091 | US TEC-B2C-08 — Configuração de Roteamento Omni-Channel (skills, presence e filas regionais)
- W-000092 | US TEC-B2C-09 — Fundação Marketing Cloud (Connect, jornadas base e templates WhatsApp)
- W-000102 | US CAT-TPL-01 — Planilha mestre do catálogo (template de carga)
- W-000103 | US CAT-MIG-01 — Migração da base legada de ativos para o EPC
- W-000104 | US CAT-TAG-01 — Algoritmo de geração da Service Tag
- W-000105 | US TEC-INT-01 — Canal de eventos de contrato (Salesforce para MuleSoft)
- W-000106 | US B2C-33 — Templates jurídicos unificados de contrato (Document Generation)
- W-000107 | US CPQ-BRE-01 — Motor de regras de precificação de projetos especiais (Prisma → Business Rules Engin
- W-000108 | US CAT-PRC-01 — Regra de cálculo de desconto em combos e promoções regionais
- W-000109 | US B2C-31 — Cálculo pro rata de multa de fidelidade no cancelamento B2C
- W-000110 | US TEC-INT-02 — Integração com fornecedores de SVA e mapeamento de IDs de plano
- W-000111 | US CAT-FAM-01 — Modelagem EPC das famílias Móvel, Streaming e Câmera
- W-000112 | US CAT-CHD-01 — Componentes comerciais como produtos filhos (Porta secundária, Anti-DDoS, NOC, Locaç
- W-000113 | US CAT-API-01 — Cache das APIs de oferta (Digital Commerce) e rotina de atualização do catálogo
- W-000114 | US CAT-ZON-01 — Carga das zonas de disponibilidade e zonas de preço (IBGE → zona)
- W-000117 | US CAT-ACC-01 — Modelo de contas do cliente (Consumer, Business, Billing e Service) e momento de cri
- W-000118 | US TEC-OM-01 — Checkout da cotação e submissão do pedido ao Order Management (B2C, B2B e e-commerce)
- W-000119 | US B2B-07 — Importação de sites multi-ponto por planilha e endereço de referência da oportunidade
- W-000123 | US B2B-10 — Visão 360º de contratos e ativos do grupo econômico B2B (ponto de partida de upgrade, do
- W-000126 | US TEC-CLM-01 — Aditivo contratual por MACD: geração via Document Generation, aceite, assinatura e v
- W-000127 | US CAT-EQP-01 — Modelo de equipamento (CPE) no catálogo e matriz de compatibilidade CPE x plano
- W-000128 | US CAT-RET-01 — Promotions de retenção: elegibilidade, duração, limite de reuso e alçadas
- W-000130 | US TEC-INT-03 — Sincronização SAP para Salesforce do equipamento instalado no cliente
- W-000131 | US TEC-INT-04 — API inbound TMF641: ordem de campo de parceiros de delivery no Field Service
- W-000132 | US TEC-DEV-01 — Esteira de implantação CI/CD: repositório, baseline, pipeline e papel dos sandboxes
- W-000133 | US INTEGRAÇÕES - CI/CD: subir repositório GitLab e implementar esteira básica de CI/CD
- W-000134 | US INTEGRAÇÕES - Ambientes: formalizar licenciamento e ajustes das Sandboxes junto à Salesforce (des
- W-000135 | US INTEGRAÇÕES - MuleSoft: cobrar orçamento da avaliação do arquiteto e mapear demandas pendentes do
- W-000136 | US ARQUITETURA - Mapear fluxo e arquitetura das APIs do B2B (sessão Victor/David/Zildo/Priscila/Fern
- W-000137 | US ARQUITETURA - Finalizar decomposição e camada técnica do catálogo (discussão de OM)
- W-000140 | US B2B - Habilitar integração B2B para permitir execução de testes (urgente)
- W-000141 | US B2B - Escrever histórias funcionais/técnicas B2B (onboarding 3 novos profissionais SysMap)

## CANDIDATA_NOVA_HISTORIA (comentarios da revisao de negocio; nao criar sem decisao do Diego)

- [B2B-03] Fernanda 14/09: Dashboard para Logistica e Compras: oportunidades proximas do fechamento (temperatura 90%) com materiais necessarios para projetos complexos
- [B2B-03] Fernanda 14/09 e 15/09: Aceite formal da proposta tecnico-comercial: prazo de 30 dias, status "aguardando assinatura", notificacao de falta de retorno; acompanhamento de propostas e contratos aguardando assinatura (parte cabe em B2B-29/W-000145, o painel nao)
- [B2B-10] Fernanda 15/09: Historia especifica para diferenciar desenho de solucao (projeto) de venda padrao (prateleira)
- [B2C-US-01] Fernanda 01/09: Repositorio de evidencias (carga massiva, QR Code, formulario) no Customer Core
- [B2B-25 e B2B-26] Fernanda 16/09: Etapa de assinatura B2B digital ou por evidencia, com envio ao gestor quando por evidencia (solucao temporaria) e status "aguardando assinatura"

## Pendencias de negocio (comentarios de bloqueio), por responsavel

**Tayza**: B2B-01 (listagem de motivos/dados a pegar com a Tayza); B2B-04 e B2B-13 (superadas por B2B-24) "Aguardando retorno Tayza" sobre cancelamento e calculadoras; B2B-24 premissas de negocio pendentes (Fernanda 15/09).
**Diretoria**: B2B-26 refidelizacao guarda-chuva (todas as etiquetas da proposta) aguarda definicao com a diretoria.
**COI**: B2C-US-10 criterios de segmentacao B2C/B2S alem do ticket medio serao submetidos ao COI.
**GRs / processo**: B2B-06 auditoria BKO "ainda a ser discutido, depende de como o processo sera executado pelos GRs".

Comentarios: 194 no B2B e 71 no B2C, todos ancorados; autores: Fernanda da Silveira Duarte 232, Priscila De Lima 31, Diego 2. As estimativas do documento B2C (story points sugeridos por bloco) ficam so aqui: nao foram copiadas para as works.

## Plano de criacao (Fase 5, aguardando APROVADO)

| id_local | Subject | Epico | Criterios | Tamanho descricao | Bloqueio |
|---|---|---|---|---|---|
| B2B-10 | [ENTERPRISE ORDER MANAGEMENT - EOM] - Restrição de Edição pelo BKO e Bypass de Arquitetura | 1) Vender soluções | 2 | 4502 | N |
| B2B-16 | [SALES CORE] - Estruturação de Motivos e Submotivos para Perda de Leads e Oportunidades | 1) Vender soluções | 2 | 2782 | N |
| B2B-17 | [ENTERPRISE CPQ] - Configuração e Precificação de Produtos na Modalidade Cortesia / Degust | 2) Vender soluções como cortesia | 2 | 5873 | N |
| B2B-18 | [SALES CORE / ADVANCED APPROVALS] - Aprovação Mandatória e Trava Comercial para Cortesias | 2) Vender soluções como cortesia | 2 | 3341 | N |
| B2B-19 | [ENTERPRISE ORDER MANAGEMENT - EOM] - Decomposição, Provisionamento e Handoff de Cortesia  | 2) Vender soluções como cortesia | 2 | 4193 | N |
| B2B-21 | [ENTERPRISE CPQ / SALES CORE] - Negociação de Permuta de Serviços (Swap/SUAP) e Justificat | 3) Vender soluções como swap | 2 | 5436 | N |
| B2B-23 | [MACD / ENTERPRISE CPQ] - Upgrade de Serviços B2B SEM Refidelização Contratual (Manutenção | 4) Realizar upgrade | 2 | 5987 | N |
| B2C-N04 | [ATENDIMENTO & RETENÇÃO] - Tratamento de Desligamento e Reversão de Plano Colaborador | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 2 | 3780 | N |
| B2C-N05 | [DASHBOARDS & AUDITORIA] - Relatório de Auditoria de Vendas (Cortesia e SWAP) com Débito I | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 2 | 3585 | N |
| B2C-N07 | [MACD & CPQ] - Venda Cortesia com Aprovação Prévia e Faturamento Zerado | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 2 | 3963 | N |
| B2C-N08 | [MACD & CPQ] - Venda Swap (Permuta) com Preço Flexível e Comprovação | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 2 | 3894 | N |
| B2C-N09 | [MACD / CPQ] - Upgrade B2C com Trava de Inadimplência e Refidelização Guarda-Chuva | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 2 | 4102 | N |
| B2C-N10 | [MACD / CPQ] - Downgrade B2C com Isenção de Multa Condicionada à Refidelização | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 2 | 3947 | N |
| B2C-N11 | [MACD / CPQ] - Sincronização Automática de Refidelização e Data de Reajuste Anual | B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | 1 | 3205 | N |

Arquivos: plano-criacao-works.csv (campos e valores validados), plano-criterios-aceite.csv, preview-works/<id_local>.txt (Subject e descricao exatos), scripts/criar-works.apex (DRY_RUN padrao com savepoint/rollback).

## Resultado do DRY_RUN (scripts/criar-works.apex, 22/09/2026)

Compilado e executado em btp-prod com savepoint e rollback. Contagem de Works na org antes e depois: 111 (nada persistiu).

```
CW22| works a criar: 14 | DRY_RUN=true
CW22| OK [ENTERPRISE ORDER MANAGEMENT - EOM] - Restrição de Edição pelo BKO e B -> a9IV2000000zzwDMAQ
CW22| OK [SALES CORE] - Estruturação de Motivos e Submotivos para Perda de Lead -> a9IV2000000zzwEMAQ
CW22| OK [ENTERPRISE CPQ] - Configuração e Precificação de Produtos na Modalida -> a9IV2000000zzwFMAQ
CW22| OK [SALES CORE / ADVANCED APPROVALS] - Aprovação Mandatória e Trava Comer -> a9IV2000000zzwGMAQ
CW22| OK [ENTERPRISE ORDER MANAGEMENT - EOM] - Decomposição, Provisionamento e  -> a9IV2000000zzwHMAQ
CW22| OK [ENTERPRISE CPQ / SALES CORE] - Negociação de Permuta de Serviços (Swa -> a9IV2000000zzwIMAQ
CW22| OK [MACD / ENTERPRISE CPQ] - Upgrade de Serviços B2B SEM Refidelização Co -> a9IV2000000zzwJMAQ
CW22| OK [ATENDIMENTO & RETENÇÃO] - Tratamento de Desligamento e Reversão de Pl -> a9IV2000000zzwKMAQ
CW22| OK [DASHBOARDS & AUDITORIA] - Relatório de Auditoria de Vendas (Cortesia  -> a9IV2000000zzwLMAQ
CW22| OK [MACD & CPQ] - Venda Cortesia com Aprovação Prévia e Faturamento Zerad -> a9IV2000000zzwMMAQ
CW22| OK [MACD & CPQ] - Venda Swap (Permuta) com Preço Flexível e Comprovação -> a9IV2000000zzwNMAQ
CW22| OK [MACD / CPQ] - Upgrade B2C com Trava de Inadimplência e Refidelização  -> a9IV2000000zzwOMAQ
CW22| OK [MACD / CPQ] - Downgrade B2C com Isenção de Multa Condicionada à Refid -> a9IV2000000zzwPMAQ
CW22| OK [MACD / CPQ] - Sincronização Automática de Refidelização e Data de Rea -> a9IV2000000zzwQMAQ
CW22| works inseridas: 14/14 | criterios inseridos: 27/27
CW22| DRY_RUN: rollback executado, nada persistiu.
```

Validado: record type User Story, epicos, product tag, scrum team, assignee, product owner, status New, type User Story, 27 criterios de aceite no objeto proprio. Descricao completa validada localmente (maior: 5.987 caracteres, limite 32.000; Subject maior: 121 caracteres, limite 255, nenhum abreviado).

**Aguardando APROVADO para a Fase 5.**

## Fase 5 e 6: execucao (aprovada pelo Diego em 22/09/2026, 16h) e verificacao

Criacao via Bulk API 2.0: works job 750V200000mdBrCIAU (14 processadas, 0 falhas), criterios de aceite job 750V200000mdEQrIAM (27 processados, 0 falhas). Verificacao: Subject, epico, record type User Story, status New, tamanho da descricao e quantidade de criterios conferidos um a um contra o plano, todos iguais. Story Points, Sprint e Backlog Rank vazios. Total de works na org: 111 -> 125.

| id_local | Work | Id | Subject |
|---|---|---|---|
| B2B-10 | W-000160 | a9IV2000000zzxpMAA | [ENTERPRISE ORDER MANAGEMENT - EOM] - Restrição de Edição pelo BKO e Bypass de Arquitetura |
| B2B-16 | W-000161 | a9IV2000000zzxqMAA | [SALES CORE] - Estruturação de Motivos e Submotivos para Perda de Leads e Oportunidades |
| B2B-17 | W-000162 | a9IV2000000zzxrMAA | [ENTERPRISE CPQ] - Configuração e Precificação de Produtos na Modalidade Cortesia / Degust |
| B2B-18 | W-000163 | a9IV2000000zzxsMAA | [SALES CORE / ADVANCED APPROVALS] - Aprovação Mandatória e Trava Comercial para Cortesias |
| B2B-19 | W-000164 | a9IV2000000zzxtMAA | [ENTERPRISE ORDER MANAGEMENT - EOM] - Decomposição, Provisionamento e Handoff de Cortesia  |
| B2B-21 | W-000165 | a9IV2000000zzxuMAA | [ENTERPRISE CPQ / SALES CORE] - Negociação de Permuta de Serviços (Swap/SUAP) e Justificat |
| B2B-23 | W-000166 | a9IV2000000zzxvMAA | [MACD / ENTERPRISE CPQ] - Upgrade de Serviços B2B SEM Refidelização Contratual (Manutenção |
| B2C-N04 | W-000167 | a9IV2000000zzxwMAA | [ATENDIMENTO & RETENÇÃO] - Tratamento de Desligamento e Reversão de Plano Colaborador |
| B2C-N05 | W-000168 | a9IV2000000zzxxMAA | [DASHBOARDS & AUDITORIA] - Relatório de Auditoria de Vendas (Cortesia e SWAP) com Débito I |
| B2C-N07 | W-000169 | a9IV2000000zzxyMAA | [MACD & CPQ] - Venda Cortesia com Aprovação Prévia e Faturamento Zerado |
| B2C-N08 | W-000170 | a9IV2000000zzxzMAA | [MACD & CPQ] - Venda Swap (Permuta) com Preço Flexível e Comprovação |
| B2C-N09 | W-000171 | a9IV2000000zzy0MAA | [MACD / CPQ] - Upgrade B2C com Trava de Inadimplência e Refidelização Guarda-Chuva |
| B2C-N10 | W-000172 | a9IV2000000zzy1MAA | [MACD / CPQ] - Downgrade B2C com Isenção de Multa Condicionada à Refidelização |
| B2C-N11 | W-000173 | a9IV2000000zzy2MAA | [MACD / CPQ] - Sincronização Automática de Refidelização e Data de Reajuste Anual |
