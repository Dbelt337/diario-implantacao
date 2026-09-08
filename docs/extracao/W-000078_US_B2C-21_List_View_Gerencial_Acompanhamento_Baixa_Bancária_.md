# W-000078 — US B2C-21 — List View Gerencial "Acompanhamento Baixa Bancária"

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 31/08/2026 19:26 por Diego Beltrão de Moraes

Referência: US-18 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-18: List View Gerencial "Acompanhamento Baixa Bancária"
1. NARRATIVA DE NEGÓCIO
Como Gerente/Coordenador
Quero visualizar em uma única tela as propostas pausadas aguardando pagamento da taxa de ativação
Para que possamos atuar proativamente na régua de cobrança antes que o prazo de cancelamento expire.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Monitoramento do fluxo financeiro.
Regras:
* A List View deve ser filtrada por Status = "Aguardando Pagamento".
* Deve ser compartilhada com os Grupos Públicos das Regionais B2C.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Opportunity.
Automação / Lógica: Criação declarativa de List View e Public Groups.
- Acesso e Filtro Correto: Dado que um Coordenador acessa a aba Oportunidades, / Quando ele seleciona a lista "Acompanhamento Baixa Bancária", / Então ele vê apenas registros da sua regional aguardando pagamento.

## Critérios de Aceite (related list)

**1. Acesso e Filtro Correto** (New)
Dado que um Coordenador acessa a aba Oportunidades
Quando ele seleciona a lista "Acompanhamento Baixa Bancária"
Então ele vê apenas registros da sua regional aguardando pagamento.
