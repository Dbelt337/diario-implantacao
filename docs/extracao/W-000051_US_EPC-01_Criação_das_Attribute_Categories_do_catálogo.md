# W-000051 — US EPC-01 — Criação das Attribute Categories do catálogo

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 17/08/2026 14:25 por Diego Beltrão de Moraes | Alterado: 21/08/2026 17:34 por Diego Beltrão de Moraes

Como Administrador do Catálogo de Produtos, quero a taxonomia de Attribute Categories definida e criada no EPC antes de qualquer atributo, com código estável, rótulo em português e sequência de exibição, para que todo atributo nasça vinculado a uma categoria governada.

Contexto: a documentação oficial do EPC exige categoria como pré-requisito para criar atributo (o tipo é definido no nível da categoria). Decisão de 14/08: a estruturação permanece no escopo; o agrupamento visual em interface está fora do escopo atual.

Regras: código CAT_ + domínio; taxonomia inicial de 8 categorias (CAT_CONECTIVIDADE_COMERCIAL, CAT_ENDERECAMENTO_IP, CAT_TECNICO_ACESSO, CAT_SLA_SUPORTE, CAT_SEGURANCA_GERENCIADA, CAT_WIFI_GERENCIADO, CAT_CONTRATO, CAT_INFRAESTRUTURA), a ratificar em ata da Onda 0; proibido atributo sem categoria ou categoria ad hoc por oferta.

Dependências: nenhuma — primeira peça da ordem de construção (manual v2.2, seções 7.1 e 41.1).
Fonte: US_modelo_refinos_v4, US EPC-01.

Acceptance Criteria (3 registros):

1. Criação prévia das categorias — Dado que o dicionário da Onda 1 foi aprovado, quando a parametrização iniciar no Product Console ou Designer, então as 8 categorias existem ativas, com código CAT_, rótulo e Display Sequence, antes do primeiro atributo.
2. Vínculo obrigatório — Dado que um novo atributo será criado, quando o registro for salvo, então ele referencia exatamente uma categoria da taxonomia aprovada e a matriz atributo-categoria é atualizada.
3. Integridade estrutural — Dado que o dicionário foi carregado, quando a auditoria de cadastro consultar vínculos e sequências, então todo atributo tem exatamente uma categoria e toda categoria tem Display Sequence. A exibição visual não é critério desta história (fora de escopo, decisão de 14/08).

## Comentários

- Diego Beltrão de Moraes 19/08/2026 14:32: Assignee changed from Diego Beltrão de Moraes to Davi Israel de Abreu
- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
