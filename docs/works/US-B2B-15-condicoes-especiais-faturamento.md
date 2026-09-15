# US B2B-15 — Condições especiais de faturamento e intervalos de cobrança na cotação B2B

| Campo | Valor |
|---|---|
| Work | (a criar no Agile Accelerator) |
| Épico | B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente |
| Time (Scrum Team) | SysMap |
| Status | New |
| Responsável | a definir |
| Documento gerado em | 15/09/2026 |

US de negócio B2B (documento de 10/09, "Histórias novas", história 28; comentário de negócio de 14/09 na história 8: parâmetros de faturamento são preenchidos na etapa "dados de faturamento, fidelidade e tempo de contrato", depois do carrinho; W-000081 B2C-24 mantém "Mensal" somente leitura no B2C; W-000125 RN-02: nenhum cálculo financeiro no Salesforce). Fundamentação técnica em `docs/2026-09-15-fundamentacao-tecnica-historias-26-29.md`.

## Descrição
Como Gerente de Relacionamento / Backoffice B2B
Quero parametrizar na cotação corporativa o intervalo de cobrança (mensal, bimestral, trimestral, semestral, anual) e a condição de vencimento, com aprovação quando fugir do padrão
Para que contas governamentais e grandes grupos sejam faturados conforme o contrato sem ajuste manual no legado.

## Contexto e Cenário de Negócio
Hoje o BKO configura essas condições manualmente no legado. No Industries CPQ a frequência de cobrança é propriedade da pricing variable (Charge Type Recurring + Frequency) da price list entry, ou seja, é definição de catálogo, não escolha por cotação. Criar cinco pricing variables e price list entries por frequência multiplicaria o catálogo e contraria a decisão de precificação por atributo sem produto duplicado (CAT-CPX-01). Decisão desta US: o preço da cotação continua sendo o recorrente mensal da price list; intervalo de cobrança e condição de vencimento são parâmetros contratuais do header (Quote → Order → Contract) que viajam no handoff e são aplicados pelo motor de cobrança do SAP/Customer Core.

## Regras de Negócio Associadas
RN-01 Campos no header da Quote, preenchidos pelo GR na etapa de dados de faturamento após o carrinho (junto com fidelidade e prazo): Intervalo de Cobrança (Mensal padrão, Bimestral, Trimestral, Semestral, Anual); Condição de Vencimento (Mês Corrente padrão, Mês Seguinte); Dia de Vencimento (lista permitida em Custom Metadata); Tipo de Faturamento (Padrão, Órgão Público, Conglomerado).
RN-02 O preço das linhas não muda: continua o MRC mensal da price list (pricing variable recorrente mensal). O sistema apenas exibe, em campo fórmula informativo, o valor por ciclo = MRC × meses do intervalo. Nenhuma pricing variable, price list entry ou adjustment é criada por frequência.
RN-03 Combinação fora do padrão (intervalo diferente de Mensal, vencimento diferente de Mês Corrente ou tipo Órgão Público/Conglomerado) bloqueia a aprovação expressa: Approval Process com critério de entrada roteia a cotação ao BKO ou Gestor Financeiro, com justificativa obrigatória e record lock durante a aprovação.
RN-04 Após aprovação os campos ficam somente leitura (FLS para o GR e Validation Rule por status); alteração exige abandonar a cotação e gerar cotação filha (W-000098).
RN-05 Propagação: os campos são mapeados de Quote para Order e Contract pelo Field Mapper do ABO e entram no payload de handoff do Imputar Venda (W-000101) e da decomposição (W-000088) como campos de header, com as chaves acordadas com o SAP (Billing Frequency, Payment Terms). Não são atributos de produto e não passam pelas mapping rules de produto.
RN-06 De-para de valores Salesforce → SAP em Custom Metadata, mantido com Rodrigo/fiscal; valor sem de-para bloqueia o handoff com mensagem.
RN-07 Pró-rata em ciclos longos é apurado pelo billing (SAP), não no Salesforce (W-000125 RN-02). O Salesforce só envia a data de início de vigência.
RN-08 Elegibilidade: intervalos não mensais só para Business Account; Consumer Account mantém Mensal somente leitura (W-000081).
RN-09 Multi-site: os parâmetros são do master quote e valem para todos os grupos, salvo override por grupo com a mesma alçada da RN-03.

## Especificação Técnica (Salesforce)
Campos custom em Quote, Order e Contract (mesmos API names para o mapeamento); passo do OmniScript de dados de faturamento (W-000081 estendido para B2B); campo fórmula "Valor por ciclo"; Approval Process "Condições de Faturamento Não Padrão" com record lock; Validation Rules (RN-04, RN-08); Field Mapper do ABO para Quote → Order → Asset/Contract; DataRaptor Transform do handoff (W-000101/W-000088) incluindo os campos de header; Custom Metadata de de-para SAP e de dias de vencimento.

## Dependências, Riscos e Estimativa
Dependências: W-000081 (etapa de dados de faturamento), W-000098 (cotação e cotação filha), W-000101 (handoff/Imputar Venda), W-000088 (decomposição e payload), W-000121 (CAT-CPX-01, Modalidade de Pagamento), Rodrigo/fiscal e SAP (chaves de Billing Frequency e Payment Terms).
Riscos: SAP/Customer Core precisam absorver as novas chaves; contratos estaduais/federais podem exigir descrições fiscais distintas por ciclo (já tratadas por linha na W-000101).
Estimativa: 5 Story Points.

## Critérios de Aceite (formato Agile Accelerator: Name | Status | Description)

| Name | Status | Description |
|---|---|---|
| Critério 1 — Padrão | New | Dado uma cotação B2B nova, quando o GR chega à etapa de dados de faturamento, então Intervalo = Mensal e Condição = Mês Corrente vêm preenchidos e a cotação segue sem aprovação adicional. |
| Critério 2 — Não padrão roteia | New | Dado uma cotação para órgão público, quando o GR seleciona Trimestral e Vencimento Mês Seguinte, então a aprovação expressa é bloqueada, a justificativa é exigida e a cotação vai à fila do BKO/Gestor Financeiro com o registro travado. |
| Critério 3 — Preço inalterado | New | Dado uma cotação com MRC de R$ 1.000 e intervalo Semestral, quando o carrinho é reprecificado, então as linhas continuam com R$ 1.000 mensais e o campo informativo mostra R$ 6.000 por ciclo. |
| Critério 4 — Somente leitura após aprovação | New | Dado uma cotação aprovada com condições não padrão, quando o GR tenta alterar o intervalo, então o sistema bloqueia e orienta a gerar cotação filha. |
| Critério 5 — Propagação e payload | New | Dado uma Oportunidade Semestral aprovada e convertida, quando o BKO aciona Imputar Venda, então Order e Contract carregam os mesmos valores e o payload ao SAP traz Billing Frequency e Payment Terms com as chaves do de-para. |
| Critério 6 — Sem de-para | New | Dado um valor de intervalo sem chave SAP cadastrada, quando o handoff é acionado, então o envio é bloqueado com mensagem indicando o valor sem de-para. |
| Critério 7 — B2C inalterado | New | Dado uma venda B2C, quando o vendedor chega aos dados de faturamento, então Intervalo continua "Mensal" somente leitura. |

Massa de teste sugerida: cotações com "Mensal/Mês Corrente", "Trimestral/Mês Seguinte" e "Anual"; conta Consumer para o critério 7; auditoria do payload recebido pelo SAP em sandbox.
