# Works x Histórias B2B — situação em 15/09/2026

Fontes cruzadas:
- `Works_Requisitos_SysMap_1109_82docs.zip` — 82 works exportadas do Agile Accelerator em 11/09/2026 (W-000041 a W-000132, todas com Status = New).
- `Especificação Funcional e Técnica B2B.docx` — 29 histórias B2B (blocos: refinadas iniciais 1-6; reunião de 01/09: 7-11; refinadas de 09/09: 12-25; "Histórias novas": 26-29).
- `Modelagem_Conectividade_v3_BTP_1409.xlsx` — modelagem de catálogo v3 (BTP, 14/09/2026).

A numeração 1-29 abaixo é a ordem das histórias no docx e é a mesma que as works citam
(ex.: W-000122 cita "histórias 9 e 15", W-000125 cita "história 25", W-000128 cita "histórias B2B 4 e 24").

## Distribuição das 82 works por épico

| Épico | Qtde | Faixa |
|---|---|---|
| Catálogo Comercial Unificado - B2B/B2C (EPC, CAT, QUAL) | 18 | W-000041, 051-056, 102-104, 108, 111-114, 121, 127, 128 |
| B2C - Jornadas de Venda (B2C-01..34, TEC-B2C, TEC-INT, TEC-OM, TEC-CLM, TEC-DEV, CAT-ACC) | 52 | W-000057 a W-000095, 105, 106, 109, 110, 115-118, 126, 129-132 |
| B2B - Jornadas de Venda e Gestão de Contratos (B2B-01..12, CPQ-BRE-01) | 13 | W-000096 a W-000101, 107, 119, 120, 122-125 |

## Cobertura história por história

| # | História B2B (docx) | Work que cobre | Como cobre |
|---|---|---|---|
| 1 | Escalonamento de Inatividade de Leads e Enriquecimento Econodata | W-000096 B2B-01 | história integral |
| 2 | Endereçamento Geocodificado, Viabilidade Expressa, Pré-Projeto | W-000097 B2B-02 | história integral |
| 3 | Cotação Multi-Site, Alçadas, Proposta via DocGen | W-000098 B2B-03 | história integral |
| 4 | Cancelamento B2B, Esteiras de Retenção, Multa | W-000099 B2B-04 | história integral |
| 5 | Alteração Contratual Upgrade/Swap, Espelhamento de Ativos | W-000100 B2B-05 | história integral |
| 6 | Auditoria BKO, Crédito/Débitos, Handoff Customer Core/ERP | W-000101 B2B-06 | história integral |
| 7 | Rastreio Comercial e Parceiros (Finder, Integrator, Premiere) | W-000120 B2B-08 | história integral |
| 8 | Taxa Única (CAPEX) no carrinho B2B | W-000121 CAT-CPX-01 | história integral (precificação por atributo) |
| 9 | Contrato padrão e Signatário Legal obrigatório | W-000122 B2B-09 | história integral |
| 10 | Restrição de edição pelo BKO e bypass de Arquitetura em venda expressa | W-000101 B2B-06 | nota "Incorpora a história B2B de 01/09" (a)(b)(c) |
| 11 | Motivos e Submotivos de perda (Lead e Oportunidade) | W-000096 B2B-01 + W-000073 B2C-16 | nota de 10/09: Global Value Set único, dependência motivo x submotivo |
| 12 | Cotação Multi-Site, Trading, Validade de Proposta 30 dias | W-000098 B2B-03 | notas "VALIDADE 30 DIAS, ABANDONO E TRAVA DE CORTESIA" e "MECÂNICA DA VALIDADE" (10/09) |
| 13 | Cancelamento B2B, Retenção e Calculadoras Predicionais | W-000099 B2B-04 | nota "RETENÇÃO, EVIDÊNCIA, CALCULADORA E BILLING STOP" (10/09) |
| 14 | Visão 360º, Alteração Contratual e Refidelização Intencional | W-000123 B2B-10 + W-000100 B2B-05 | W-000123 é a 360; refidelização intencional na nota (c) da W-000100 |
| 15 | Geração de Contrato, Contato de NPS e Armazenamento Externo | W-000122 B2B-09 | história integral; armazenamento externo rejeitado em 10/09 |
| 16 | Motivos e Submotivos (repetida no docx) | idem 11 | duplicata da 11 |
| 17 | Cortesia / Degustação no Enterprise CPQ | W-000115 B2C-30 | nota "ESCOPO B2B E MECÂNICA NATIVA DA CORTESIA" (substitui as 3 histórias B2B de 09/09) |
| 18 | Aprovação mandatória e trava comercial para Cortesias | W-000115 B2C-30 | idem 17 |
| 19 | Decomposição / Handoff de Cortesia (faturamento nulo) | W-000115 B2C-30 + W-000088 TEC-B2C-05 | idem 17; flag "não faturar" no payload |
| 20 | Fim de Degustação (Try & Buy) e conversão | W-000124 B2B-11 | história integral |
| 21 | Permuta de Serviços (Swap/SUAP) e justificativa | W-000100 B2B-05 | nota (g) PERMUTA/SUAP (10/09) |
| 22 | Upgrade COM refidelização intencional | W-000100 B2B-05 | nota (c) |
| 23 | Upgrade SEM refidelização (vigência original) | W-000100 B2B-05 | nota (d) e "TRAVAS E FISCAL" (b) |
| 24 | Cancelamento, Esteira Sequencial e Billing Stop (TMF622) | W-000099 B2B-04 + W-000128 CAT-RET-01 | nota (a) esteira sequencial; Promotions de retenção na CAT-RET-01 |
| 25 | Downgrade Contratual, Delta MRR, Fidelidade | W-000125 B2B-12 | história integral |
| **26** | **Refidelização Pura e Simples (renovação sem alteração de escopo)** | **nenhuma** | W-000100 só trata refidelização junto com upgrade; não há fluxo de renovação isolada (OmniScript simplificado, aditivo de tempo, aprovação BKO, trava contra MACD simultâneo) |
| **27** | **Aviso Prévio de Cancelamento (30/60/90 dias), reversão e corte automático** | **nenhuma** | nenhuma work cita "aviso prévio"; W-000099 vai direto do cálculo de multa ao Billing Stop |
| **28** | **Condições Especiais de Faturamento e Intervalos de Cobrança B2B** | **nenhuma** | W-000081 B2C-24 fixa "Mensal" em somente leitura; falta picklist mensal/bimestral/trimestral/semestral/anual, condição de vencimento, alçada para não padrão e payload Billing Cycle/Payment Terms ao SAP |
| **29** | **Cadência automática de notificações de assinatura (proposta e contrato)** | **parcial: W-000122 RN-05** | RN-05 avisa só o GR (1, 3, 7 dias; gestor em 15; expira em 30) e só para contrato. A história 29 pede e-mail ao cliente com cópia ao GR em D0, D+2, D+4, D+7, D+15, D+30, às 08h (fuso -03:00), para proposta e contrato, com Task na Oportunidade e quebra da cadência pelo callback de assinatura |

## O que falta criar (B2B)

1. **B2B-13 — Refidelização Pura e Simples** (história 26). Sugestão: nova work no épico B2B, dependências W-000123 (360), W-000126 (TEC-CLM-01 aditivo), W-000100 (regras de prazo 12/24/36/48), W-000101 (fila BKO).
2. **B2B-14 — Aviso Prévio de Cancelamento e Corte Automático** (história 27). Dependências W-000099 (entrada do cancelamento), W-000088/TEC-OM-01 (ordem de desativação), Customer Core (execução programada ou disparo pelo Salesforce no D-Day).
3. **B2B-15 — Condições Especiais de Faturamento e Intervalos de Cobrança** (história 28). Dependências W-000081 (campos B2C), W-000098 (cotação), W-000101 (handoff), SAP/Customer Core aceitarem as novas chaves.
4. **Cadência de notificações de assinatura** (história 29): decidir entre (a) ampliar a W-000122 (RN-05 passa a cobrir cliente, proposta, D0..D+30 e 08h) ou (b) work própria TEC-CLM-02. Recomendação: work própria, porque a régua vale também para proposta (Quote) e reutiliza a régua B2C da W-000066.

## Catálogo: plano acordado por e-mail em 14/09 (Modelagem v3)

Cadeia de e-mails de 14/09:

- **Davi (SysMap), 14:58**: envia a estrutura montada na sexta a partir da grade de conectividade do Joel (Excel com hierarquia, produtos e ofertas, produto x Object Type, atributos) e pede avaliação do Joel e da governança Salesforce. Pede ao Diego que, **após o OK do Joel, ajuste as US 51, 52 e 55 para que passem a ter US filhas** com base na estrutura dos produtos: v0 = ofertas de conectividade; as demais ofertas (Joel) e a frente Rodrigo/Varejo geram outras filhas depois, para controle das entregas.
- **Diego, 18:01**: avaliação de governança contra as decisões de 10/09, com a Modelagem v3 anexa (mesmo arquivo analisado aqui). Fechou o seguinte:

- O conteúdo comercial da v2 (SysMap) fica: adicionais como produtos filhos, camada de oferta sem atributos de configuração, validação de valores por oferta.
- Cinco ajustes: (1) um produto tem um único Object Type, logo 9 produtos Conectividade, um por oferta, sem override por bundle; (2) árvore em dois níveis, de 17 tipos de produto para 3 famílias (Conectividade, Adicional, Equipamento Gerenciado); (3) tipos de oferta sem atributo saem, viram Catálogo/Categoria e Família do Product2, e o tipo base de oferta carrega Prazo de Contrato, Modalidade de Pagamento, Tipo de Negociação e Marca; (4) "Nenhum"/"Desativado" viram cardinalidade mínima zero e saem da picklist; (5) preço por atributo com matriz (Fibra Ponto a Ponto, blocos IPv4, Banda, nível de NOC), sem regra de preço zerando nada.
- **Works de catálogo: W-000051 (EPC-01 Attribute Categories), W-000052 (EPC-04 hierarquia) e W-000055 (EPC-03 dicionário) já existem e são as pais. Não se abre nada novo para elas: a ação é ajustá-las para receberem filhas por família, não por oferta** (instrução do Diego em 15/09: "abrir não, porque elas já existem"). O trio de Conectividade fica pronto para tramitar quando o Joel responder P1 (prazo na oferta ou no componente) e P2 (valores dos adicionais por oferta), porque os dois mudam o conteúdo. Voz, TV, Wi-Fi e Dispositivos e SVA seguem o mesmo trio quando chegarem as grades do Joel e do Rodrigo. Os números W das filhas, quando existirem no Agile Accelerator, devem ser anotados aqui (não constam do export de 11/09).

### Filhas de Conectividade (conteúdo aguarda P1 e P2)

| Work filha | Pai | Conteúdo que sai da v3 |
|---|---|---|
| EPC-01 Conectividade — categorias da família | W-000051 | categorias dos 25 atributos da v3 (Leia-me + aba Atribuição por Produto); confrontar com a taxonomia CAT_ de 8 categorias da W-000051 |
| EPC-03 Conectividade — dicionário de atributos | W-000055 | 25 atributos (ATR_*) com picklists PL_* da aba Picklists; 4 transversais no tipo base de oferta, 11 no tipo Conectividade, 1 por adicional, os de Firewall/Wi-Fi atribuídos no produto |
| EPC-04 Conectividade — hierarquia e atribuição | W-000052 | aba Hierarquia OT (OT_OFFER_BASE > OT_OFFER_CONECTIVIDADE / OT_OFFER_EQUIP_GERENCIADO; OT_PROD_BASE > OT_PROD_CONECTIVIDADE / OT_PROD_ADICIONAL / OT_PROD_EQUIP_GERENCIADO), aba Atribuição por Produto (herdado x atribuído no produto, valores habilitados e ocultos) |

Works existentes afetadas, para alinhar quando as filhas abrirem (nenhuma work cita 12, 13 ou 14/09):

- **W-000041** (revisão 10/09 da EPC-04): modela um único "BTP Produto Base" com 5 famílias e põe Código SAP e Descrição Fiscal como atributos do tipo base. Na v3 são campos do Product2 (Regra 7) e os transversais ficam no tipo base de **oferta**, não de produto. Conflito a registrar na filha EPC-04 Conectividade.
- **W-000053 EPC-05** (Product Specs da Onda 1) e **W-000112 CAT-CHD-01** (filhos): passam a seguir as abas Produtos (11 ofertas + 16 filhos: 9 Conectividade, 5 adicionais, 2 equipamentos) e Estrutura (cardinalidades).
- **W-000108 CAT-PRC-01**: aba Preço por Atributo, só Smart Internet Corporativa até P4.
- **W-000121 CAT-CPX-01**: Taxa Única só nas ofertas elegíveis (P8).
- **W-000127 CAT-EQP-01**: ficha técnica de Firewall/Wi-Fi.

### Pendências da v3 e donos

| # | Pendência | Dono |
|---|---|---|
| P1 | Prazo de Contrato na oferta ou no componente Conectividade | Joel |
| P2 | Valores dos adicionais variam por oferta ou lista completa vale para todas | Joel |
| P3 | Cardinalidade da Locação de Roteador (obrigatória em todas?) | Joel |
| P4 | Preços das outras 10 ofertas no formato da Corporativa | Joel |
| P5 | Camada técnica CFS/RFS/Recurso e decomposição | SysMap com OM |
| P6 | Código SAP, descrição e documento fiscal dos 16 filhos | Rodrigo / fiscal |
| P7 | Anomalia NOC sem cabeçalho no Serviço VPN | Joel |
| P8 | Valores de Marca, Tipo de Negociação e quais ofertas aceitam Taxa Única | Comercial |

### Achado na planilha v3

O código do atributo Prazo de Contrato está grafado `ATR_PRAZO_CONTRATO` na aba Atribuição por Produto e `ATR_PRAZO_DE_CONTRATO` na aba Picklists. Os outros 24 códigos batem entre as abas. Corrigir antes de virar template de carga (CAT-TPL-01).

## Revisão de negócio no Google Doc (comentários do docx reenviado em 15/09)

O docx reenviado tem o mesmo texto, mas traz 68 comentários do Google Doc. Extrato completo, com trecho anotado e história, em `docs/2026-09-14-comentarios-fernanda-spec-b2b.txt`.

Marcos:
- **Priscila De Lima, 09/09 22:53** (na história 11): "a partir daqui temos novas histórias" → histórias 12 a 25 são as de 09/09 (batem com as notas de 10/09 das works).
- **Priscila De Lima, 10/09 22:24 (19:24 BRT)**: "Novas histórias" → histórias 26 a 29 entraram na noite de 10/09, depois do refinamento de 10/09 e antes do export de 11/09. Por isso nenhuma work as cobre.
- **Fernanda da Silveira Duarte, 14/09 16:46 a 19:47**: 64 comentários nas histórias 1 a 17. Parou na 17 ("PAREI AQUI"). Histórias 18 a 29 ainda sem revisão de negócio.
- Itens marcados "Aguardando retorno Tayza": evidência formal no cancelamento (histórias 4 e 13) e lista de motivos/submotivos (11 e 16).

### Impacto dos comentários da Fernanda nas works

| Hist. | Comentário (resumo) | Work | Efeito |
|---|---|---|---|
| 1 | Alertas por notificação no Salesforce e e-mail; períodos parametrizáveis; "Diretor/Red" é "Head" | W-000096 | ajuste de regra |
| 2 | Mesmo com viabilidade "Viável", GR pode acionar a Arquitetura por botão/flag; sistema deve trazer automaticamente os dados da oportunidade para o Arquiteto; tipo de link vem do sistema; endereço via Correios? | W-000097 | ajuste de regra (bypass não é absoluto) |
| 3 | Proposta sai em PDF, nunca DOCX; aceite formal registrado no sistema, dados de faturamento na proposta, reenvio manual e troca de e-mail; sem alerta a Compras: dashboard para Logística/Compras com oportunidades a 90%; aprovação de desconto e temperatura 90% são temas distintos; prazos de degustação 30/60/90 dias com aprovação gerencial | W-000098 | ajuste de regra; dashboard de Compras é item novo |
| 4 | Esteiras: 1ª do GR (ofertas de retenção em %), 2ª da célula de retenção; Arquitetura NÃO faz retenção, só viabilidade da nova proposta; isenção de multa por alçada de valor, não Diretor fixo | W-000099 | **conflito** com a nota (a) de 10/09, que abre tarefa da Arquitetura para readequação técnica |
| 5 | "Mistura 4 processos distintos"; regra de espelhamento não entendida | W-000100 | reescrever narrativa separando upgrade, downgrade, swap e retenção |
| 6 | BKO não ajusta valores nem condições (vendedor faz nova cotação), mas tem acesso aberto para correções operacionais; "Imputar Venda" = aceitar a criação do contrato; assinatura vem antes do input da venda; débito interno tem prioridade absoluta sobre restrição externa; 6 meses de auditoria ainda em discussão | W-000101 | coerente com a nota (b); ajustar sequência assinatura → imputar |
| 8 | Persona é o GR, não o Arquiteto; Taxa Única é escolhida na etapa "dados de faturamento, fidelidade e tempo de contrato", depois do carrinho, não na composição do produto | W-000121 | **conflito** com a modelagem por atributo no produto; decidir onde o atributo é preenchido |
| 9 | Quem solicita o contrato é o BKO, não o GR; sistema barra antes de chegar ao BKO; subcategorias de contato (NF, financeiro, NPS); "Gerente de Contas" é "Gerente de Relacionamento" | W-000122 | ajuste de regra e de Contact Roles |
| 10 | Venda expressa ainda precisa do botão de pedir análise da Arquitetura; alteração de valor/produto obriga abandonar a cotação | W-000101, W-000098 | já coberto na W-000098 (abandono); botão na W-000097 |
| 11/16 | Botão de perda disponível o processo todo, desabilitado só após assinatura; lista com a Tayza | W-000096, W-000073 | ajuste de regra; lista pendente |
| 13 | Entradas do cancelamento: Célula de Retenção, Central de Cancelamento e GR (só a própria carteira); evidência aguarda Tayza | W-000099 | ajuste de perfis e visibilidade |
| 14 | Toda menção a upgrade vale também para downgrade; refidelização cobre todas as etiquetas da proposta (contrato guarda-chuva); prazo "e outros" | W-000100, W-000123, W-000125 | ajuste de regra |
| 15 | Régua de assinatura: MKT Cloud com templates, e-mail em D+2, D+4, D+7, D+15 e D+30 às 08h; não é "24h"; nos demais dias é o vendedor | W-000122 | **conflito** com RN-05 (1, 3 e 7 dias só para o GR). Bate com a história 29 |
| 17 | Tipo de negociação (cortesia) é definido nos dados básicos da oportunidade, não no carrinho nem no produto; venda pode virar cortesia no meio da negociação; **cortesia também tem fidelidade**, preenchida na etapa "período do contrato e fidelidade" (contrato e fidelidade em 12/24/36/48/60/outros, motivo obrigatório se diferirem) | W-000115 | **conflito** com a nota de 10/09 (a) atributo no carrinho e (b) cortesia pura sem fidelidade |

Decisões a levar para a Fernanda/Priscila antes de mexer nas works: Arquitetura na esteira de retenção (4), onde se preenche Taxa Única e Tipo de Negociação (8 e 17), fidelidade em cortesia (17), régua de assinatura (15 e 29).
