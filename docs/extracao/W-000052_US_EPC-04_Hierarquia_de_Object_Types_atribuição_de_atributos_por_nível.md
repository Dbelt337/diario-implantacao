# W-000052 — US EPC-04 — Hierarquia de Object Types, atribuição de atributos por nível e layouts

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 17/08/2026 14:26 por Diego Beltrão de Moraes | Alterado: 21/08/2026 17:34 por Diego Beltrão de Moraes

Como Arquiteto de Solução do catálogo, quero a hierarquia de Object Types da seção 35.3 criada, com a matriz de atribuição de atributos por nível e os layouts base finalizados antes dos subtipos, para que a herança dinâmica de atributos e a herança por cópia dos layouts operem a favor do reuso.

Regras: o Object Type base carrega campos, não atributos; cada atributo entra no menor nó comum; layout do pai fecha antes de criar filhos (cópia profunda não replica mudanças posteriores); parent não muda após existirem descendentes sem ADR. Extensão para serviços gerenciados via ADR: OT_MANAGED_SERVICE_OFFER, OT_MANAGED_SECURITY_PRODUCT_SPEC e OT_MANAGED_WIFI_PRODUCT_SPEC. Ratificar a 35.3 como normativa em ata (P-08, ato interno da sessão).

Dependências: esqueleto da hierarquia, campos e layouts executáveis desde já; a atribuição de atributos consome a saída da EPC-03.
Fonte: US_modelo_refinos_v4, US EPC-04 (matriz categoria-atributo-Object Type completa).

Acceptance Criteria (3 registros):

1. Hierarquia aprovada antes dos subtipos — Dado que a hierarquia 35.3 com a extensão de gerenciados foi submetida, quando a criação iniciar, então os nós base têm atributos, campos e layout finalizados antes de qualquer subtipo, e nenhum parent muda após existirem descendentes sem ADR.
2. Herança dinâmica validada — Dado que um atributo foi atribuído ao Object Type pai, quando um subtipo ou spec vinculada for consultada, então o atributo consta herdado automaticamente, com teste de herança evidenciando a propagação.
3. Layout contém o que deve aparecer — Dado que o layout do pai foi definido com seções por categoria, quando um produto novo for criado do Object Type, então todos os atributos e campos esperados aparecem; atributo fora do layout é defeito de parametrização.

## Comentários

- Diego Beltrão de Moraes 19/08/2026 14:32: Assignee changed from Diego Beltrão de Moraes to Davi Israel de Abreu
- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
