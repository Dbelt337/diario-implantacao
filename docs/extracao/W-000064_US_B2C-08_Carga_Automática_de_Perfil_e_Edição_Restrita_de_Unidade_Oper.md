# W-000064 — US B2C-08 — Carga Automática de Perfil e Edição Restrita de Unidade Operacional

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:23 por Diego Beltrão de Moraes | Alterado: 31/08/2026 19:13 por Diego Beltrão de Moraes

"Como Consultor de Vendas ou Agente de Backoffice B2C
Quero que os dados do meu perfil (Empresa do Grupo, Regional, Canal de Entrada) sejam carregados automaticamente no início do fluxo , mantendo o campo ""Unidade Operacional"" editável apenas para as unidades pertencentes à minha regional.
Para que a Brasil TecPar garanta o cumprimento das regras de compliance corporativo do COI/Octa , evitando que vendedores registrem vendas em unidades operacionais fora da sua alçada de atendimento.

SOLUÇÃO TÉCNICA: Opportunity.OperationUnit__c JÁ EXISTE — não criar campo; replicar no Lead
(W-B2C-01). Picklist dependente nativa NÃO filtra por usuário: o caminho é o objeto
UserRegionalMapping__c (User__c, Regional__c, OperationUnit__c — mantido pelo Backoffice sem deploy)
+ choices filtradas pelo $User na jornada/tela. Permission sets PS_B2C_Sales_User (filtrado) e
PS_B2C_Backoffice_User (visão ampliada). Carga automática do contexto (empresa, gerência, canal,
regional) a partir do usuário logado.

Dependências: SLA de atualização do de-para quando o Octa/Senior transfere o usuário de regional;
mecanismo de provisionamento (SSO/SCIM) [CONFIRMAR com TI].

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-08."

## Critérios de Aceite (related list)

**1. 2** (New)
Validação de perfil de Backoffice com permissão ampliada — Dado que um usuário com o perfil Backoffice B2C inicia o lançamento de uma venda; Quando ele acessar o campo de seleção de Canal e Unidade; Então o sistema deve permitir a seleção de canais/unidades generalistas conforme seu grupo de acesso.

**2. 1** (New)
Filtro de Unidades Operacionais para Vendedor Regional — Dado que um vendedor pertencente à Regional São Paulo inicia o fluxo de nova venda; Quando ele chegar ao campo "Unidade Operacional"; Então o sistema deve exibir no menu suspenso apenas as unidades operacionais vinculadas à Regional São Paulo.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-08 — Edição Restrita de Unidade Operacional por Escopo Regional to US B2C-08 — Carga Automática de Perfil e Edição Restrita de Unidade Operacional
