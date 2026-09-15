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

## Catálogo: impacto da Modelagem v3 (14/09) nas works existentes

A v3 é posterior a todas as works (11/09) e "substitui a hierarquia da planilha ObjectTypes-EPC v2 (SysMap)". Nenhuma work cita 12, 13 ou 14/09. Works a revisar:

- **W-000041 EPC-04 (revisão 10/09)**: modela um único tipo base "BTP Produto Base" com 5 famílias. A v3 separa duas árvores (Oferta: OT_OFFER_BASE > Conectividade / Equipamento Gerenciado; Produto: OT_PROD_BASE > Conectividade / Adicional de Conectividade / Equipamento Gerenciado) e move Código SAP e descrição fiscal para campos do Product2 (Regra 7). A lista de atributos de Conectividade também mudou (v3: Meio de Acesso, Last Mile, Rede Neutra, Banda, Upload, IPv4, IPv6, Tipo de conexão VPN, Sessão BGP, Burstable 95th, Tipo de Serviço).
- **W-000052 EPC-04 original** e **W-000053 EPC-05**: hierarquia e Product Specs precisam refletir os 9 produtos Conectividade (um por oferta, Regra 3) e as 11 ofertas.
- **W-000112 CAT-CHD-01**: v3 confirma os 5 adicionais e 2 equipamentos como filhos compartilhados (Regra 4) e a cardinalidade mínima zero quando havia "Nenhum/Desativado" (Regra 5); alinhar picklists.
- **W-000108 CAT-PRC-01**: aba "Preço por Atributo" só tem Smart Internet Corporativa; depende da pendência P4.
- **W-000127 CAT-EQP-01**: ficha técnica de Firewall/Wi-Fi entra por aqui (aba Hierarquia OT).

Pendências da v3 e donos: P1 prazo na oferta (Joel), P2 valores de adicionais por oferta (Joel), P3 cardinalidade dos adicionais (Joel), P4 preços das outras 10 ofertas (Joel), P5 camada técnica CFS/RFS/Recurso (SysMap com OM), P6 SAP/fiscal por filho (Rodrigo/fiscal), P7 anomalia NOC no Serviço VPN (Joel), P8 Marca, Tipo de Negociação e Taxa Única (Comercial).
