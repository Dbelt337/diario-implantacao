# W-000081 — US B2C-24 — Etapa Manual: Preenchimento dos Dados de Faturamento e Parametrização Contratual

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:50 por Diego Beltrão de Moraes

Referência: US-NEW-01 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

[US-NEW-01] Etapa Manual: Preenchimento dos Dados de Faturamento e Parametrização Contratual
1. NARRATIVA DE NEGÓCIO
Como Consultor de Vendas B2C,
Quero preencher os parâmetros contratuais e de faturamento em uma etapa dedicada com regras de negócio automatizadas e campos restritos,
Para que os dados de cobrança, datas de vencimento, fidelização e endereço da fatura sejam validados e integrados corretamente ao ERP sem erros manuais.
2. CONTEXTO E REGRAS DE NEGÓCIO
A etapa de faturamento antecede a geração do contrato e exige o preenchimento de parâmetros que definem o ciclo de vida do cliente.
Tempo de contrato: Lista suspensa obrigatória restrita aos valores: 12, 24, 36, 48 ou 60 meses.
Tempo de término do contrato: Campo calculado automaticamente (ReadOnly) somando o "Tempo de contrato" à data de início.
Tempo de fidelização: Campo numérico em meses (ex.: 12 meses).
Intervalo de cobrança: Preenchido automaticamente com "Mensal" (ReadOnly).
Data de vencimento: Lista suspensa restrita aos dias 5, 10 ou 15.
Cedente da cobrança: Preenchido automaticamente com base na Empresa do Grupo/Regional da Unidade Operacional.
Forma de pagamento: Lista suspensa (Boleto, Cartão de Crédito, Pix, Débito em Conta).
Forma de envio da fatura: Default em "E-mail" (ReadOnly ou auto-preenchido). Deve validar o formato do e-mail inserido.
Endereço de faturamento: Checkbox "Igual ao endereço informado anteriormente". Se desmarcado, exibe campos obrigatórios (CEP, Logradouro, Número) para novo endereço.Segmento de mercado: Preenchido automaticamente com "Residencial" (ReadOnly).
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Quote, Order, Opportunity.
Automação: Criação de Step dedicado no OmniScript com formulas para recálculo de datas e regras de dependência (UI Behavior) no endereço de faturamento.
- Cálculo Automático de Término: Dado que o vendedor seleciona "24 meses" no Tempo de Contrato, / Quando o campo perde o foco, / Então o sistema calcula o Término do Contrato somando 24 meses à data atual.
- Endereço de Faturamento Divergente: Dado que o cliente deseja a fatura em outro endereço, / Quando o vendedor desmarca a opção "Igual ao endereço de instalação", / Então o sistema deve exibir o bloco de CEP e obrigar o preenchimento.

## Critérios de Aceite (related list)

**1. Endereço de Faturamento Divergente** (New)
Dado que o cliente deseja a fatura em outro endereço
Quando o vendedor desmarca a opção "Igual ao endereço de instalação"
Então o sistema deve exibir o bloco de CEP e obrigar o preenchimento.

**2. Cálculo Automático de Término** (New)
Dado que o vendedor seleciona "24 meses" no Tempo de Contrato
Quando o campo perde o foco
Então o sistema calcula o Término do Contrato somando 24 meses à data atual.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso parcial (matriz #8).
REUSAR: captura de faturamento/vencimento em producao - BTecParPF_PaymentMethod (metodo/vencimento) + BTecParPF_GetDueDate (datas).
EVIDENCIA: vlocity-backup/OmniScript/BTecParPF_PaymentMethod_Portuguese-Brazil | vlocity-backup/IntegrationProcedure/BTecParPF_GetDueDate.
CONSTRUIR: regras novas do doc consolidado (tempo de contrato 12-60, cedente automatico por unidade, endereco de faturamento divergente).
DIRETRIZ SYSMAP: estender o step existente da jornada PF; confirmar cedente, forma de envio e datas com o financeiro (pendencia da matriz).

--- PRAZO DE CONTRATO E CAMPOS FISCAIS (decisoes 03/09 e 04/09) ---
AJUSTE: "Tempo de contrato" (12/24/36/48/60) NAO e mais um campo livre desta etapa. Pela decisao de 03/09 ele e atributo de precificacao escolhido no CARRINHO (W-000069/W-000085). Esta etapa apenas EXIBE (read-only) o prazo herdado da linha e calcula termino e fidelizacao a partir dele; alterar o prazo significa voltar ao carrinho e reprecificar. Demais campos (vencimento 5/10/15, cedente, forma de pagamento, endereco de fatura) permanecem. Campos fiscais por linha (codigo de material SAP + descricao fiscal) sao parametrizados na criacao da ordem (W-000088) e mantidos pela gestao de produtos; esta etapa nao os edita.
