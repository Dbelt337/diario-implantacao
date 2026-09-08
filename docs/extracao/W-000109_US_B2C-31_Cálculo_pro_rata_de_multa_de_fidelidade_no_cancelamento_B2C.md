# W-000109 — US B2C-31 — Cálculo pro rata de multa de fidelidade no cancelamento B2C

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:21 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:21 por Diego Beltrão de Moraes

US B2C (agenda presencial 02/09: ação "Implementar Cálculo Prorrata" e tema "Cálculos de multa e prorrogação").

NARRATIVA
Como Atendente de Retenção, quero que o sistema calcule automaticamente a multa de fidelidade proporcional ao prazo restante no cancelamento de um cliente B2C, para que o valor informado ao cliente seja correto, auditável e igual ao que será cobrado.

CONTEXTO E CENÁRIO DE NEGÓCIO
A B2B-04 (W-000099) cobre a multa rescisória do B2B. No B2C não há US, e a regra é diferente: multa proporcional ao benefício concedido (desconto de fidelidade ou taxa de instalação isenta) pelos meses restantes, respeitando o Código de Defesa do Consumidor e o regulamento da Anatel. O dado de fidelidade passa a viver no Asset (US CAT-MIG-01 e W-000081).

REGRAS DE NEGÓCIO
RN-01 Base de cálculo: valor do benefício concedido na contratação (desconto mensal de fidelidade ou instalação isenta), nunca as mensalidades restantes.
RN-02 Pro rata: multa = benefício total × (meses restantes ÷ meses de fidelidade), com meses restantes contados a partir da data de solicitação do cancelamento.
RN-03 Fidelidade máxima: 12 meses para pessoa física; prazos maiores no contrato não geram multa além de 12.
RN-04 Isenções automáticas: falha de prestação comprovada, mudança para endereço sem cobertura e óbito do titular zeram a multa, mediante motivo registrado.
RN-05 Transparência: o cálculo é exibido ao atendente e enviado ao cliente antes da confirmação, com os componentes (benefício, meses restantes, valor).
RN-06 Imutabilidade: após confirmado, o valor da multa é gravado na solicitação e não recalcula com alterações posteriores do catálogo.

ESPECIFICAÇÃO TÉCNICA
Campos de fidelidade no Asset (data de início, meses de fidelidade, benefício concedido) alimentados pela venda e pela migração; fórmula em Apex ou Flow invocável a partir do OmniScript de cancelamento; registro em objeto de solicitação de cancelamento; envio ao Customer Core pelo endpoint proprietário com o valor calculado (Onda 1).

DEPENDÊNCIAS E RISCOS
Dependências: dados de fidelidade no Asset (US CAT-MIG-01 para a base legada); W-000081; jurídico para as isenções; regra de arredondamento com o financeiro.
Riscos: base legada sem data de início confiável; divergência com o cálculo atual do Customer Core.

CRITÉRIOS DE ACEITE
Cenário 1: Cancelamento no meio da fidelidade. Dado um cliente com 12 meses de fidelidade, benefício total de R$ 240 e 6 meses restantes, quando o cancelamento for solicitado, então a multa calculada é R$ 120 e os componentes são exibidos.
Cenário 2: Fidelidade cumprida. Dado um cliente além do 12º mês, quando solicitar cancelamento, então a multa é zero.
Cenário 3: Isenção. Dado um cancelamento por mudança para área sem cobertura, quando o motivo for registrado, então a multa é zerada e o motivo fica auditável.
Cenário 4: Imutabilidade. Dado uma multa confirmada, quando o catálogo mudar depois, então o valor gravado na solicitação não se altera.
