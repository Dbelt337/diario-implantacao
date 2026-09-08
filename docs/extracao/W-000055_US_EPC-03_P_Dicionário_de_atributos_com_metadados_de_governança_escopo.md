# W-000055 — US EPC-03 (P) — Dicionário de atributos com metadados de governança — escopo parcial, sem atributos do WITO

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 17/08/2026 14:33 por Diego Beltrão de Moraes | Alterado: 21/08/2026 17:34 por Diego Beltrão de Moraes

Como Administrador do Catálogo, quero os atributos da Onda 1 criados com os metadados completos da seção 35.4 (AttributeCode, DataType, categoria, PicklistCode, default, visibilidade e editabilidade por canal, Assetizable, PricingImpact, OMImpact, EligibilityImpact, lifecycle e owner).

ESCOPO PARCIAL DESTA WORK: excluir FIREWALL_VENDOR e WIFI_VENDOR (aguardam confirmação do WITO, P-02); defaults pendentes entram como "a confirmar" (NOC_TIER, P-01; LICENSE_TIER, P-10). Criação exclusivamente via Product Console ou Designer. O de-para comercial-técnico completo fica para as USs de decomposição (onda de OM). A planilha ganhará colunas de Atribuição do pai e Categoria por atributo (ação de 14/08).

Dependências: categorias da EPC-01; atributos do tipo Picklist dependem da EPC-02 (bloqueada) — priorizar escrita técnica e atributos sem picklist.
Fonte: US_modelo_refinos_v4, US EPC-03.

Acceptance Criteria (3 registros):

1. Completude dos metadados — Dado que um atributo foi criado, quando o dicionário for auditado, então nenhum atributo está sem categoria, sem picklist quando do tipo Picklist, sem default aprovado ou sem os impactos declarados.
2. Criação só pelo console — Dado que a equipe recebeu o dicionário, quando qualquer atributo for criado ou alterado, então a operação ocorre no Product Console ou Designer; fora disso é não conformidade.
3. Derivação sem dupla entrada — Dado que o vendedor selecionou um valor comercial, quando a linha for processada para o OM, então o valor técnico vem do atributo derivado por Mapping Rule, sem nova digitação.

## Comentários

- Diego Beltrão de Moraes 19/08/2026 14:33: Assignee changed from Diego Beltrão de Moraes to Davi Israel de Abreu
- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
