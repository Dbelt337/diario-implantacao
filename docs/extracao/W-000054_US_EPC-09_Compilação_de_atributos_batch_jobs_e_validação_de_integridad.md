# W-000054 — US EPC-09 — Compilação de atributos, batch jobs e validação de integridade do catálogo

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 17/08/2026 14:32 por Diego Beltrão de Moraes | Alterado: 21/08/2026 17:34 por Diego Beltrão de Moraes

Como Administrador do Catálogo, quero a rotina de compilação e as validações de integridade executadas e evidenciadas ao final de cada bloco de parametrização, para que os atributos apareçam corretamente em runtime, inclusive nos produtos legados da org.

Regras: executar EPCProductAttribJSONBatchJob ao atribuir atributo a Object Type que já tem produtos, e EPCFixCompiledAttributeOverrideBatchJob quando houver overrides, com evidência e contagem de registros. Antes de atribuir a OTs existentes, gerar o relatório de impacto da seção 35.5 (descendentes, Quotes, Orders, Assets, rollback). Ponto crítico no RadarDev pelos produtos legados. Definition of Done ampliada da 41.4.

Dependências: transversal — roda após cada bloco (EPC-01, 03, 04 e ofertas).
Fonte: US_modelo_refinos_v4, US EPC-09.

Acceptance Criteria (2 registros):

1. Compilação evidenciada — Dado que atributos foram atribuídos a OT com produtos, quando o bloco for concluído, então os jobs executaram com sucesso e os atributos aparecem na criação de produto e no carrinho.
2. Definition of Done ampliada — Dado que a entrega foi declarada pronta, quando o checklist da 41.4 for aplicado, então não há picklist órfã, valor sem pricing ou mapping obrigatório, linha faturável sem material, nem falha nos testes de herança e não regressão.

## Comentários

- Diego Beltrão de Moraes 19/08/2026 14:36: Assignee changed from Diego Beltrão de Moraes to Davi Israel de Abreu
- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
