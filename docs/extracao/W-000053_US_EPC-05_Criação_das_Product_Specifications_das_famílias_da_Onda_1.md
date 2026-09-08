# W-000053 — US EPC-05 — Criação das Product Specifications das famílias da Onda 1

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 17/08/2026 14:28 por Diego Beltrão de Moraes | Alterado: 21/08/2026 17:34 por Diego Beltrão de Moraes

Como Administrador do Catálogo, quero as Product Specifications conceituais e reutilizáveis criadas a partir dos Object Types aprovados, para que as ofertas realizem definições únicas, sem preço, sem duplicação estrutural.

Escopo: PS_MANAGED_CORPORATE_INTERNET, PS_MANAGED_FIREWALL e PS_MANAGED_WIFI, mais as especificações dos componentes reutilizáveis (acesso, conexão, NOC, Anti-DDoS, Fail-Over, Bastidor). Regra de escala (14/08): especificações são padrões semânticos genéricos; toda oferta nova parte de REUSE_EXISTING (seção 36.1) e criar spec nova é exceção justificada. Specs não recebem preço, canal ou catálogo.

Dependências: Object Types da EPC-04.
Fonte: US_modelo_refinos_v4, US EPC-05.

Acceptance Criteria (2 registros):

1. Herança integral do Object Type — Dado que a spec foi criada vinculada ao OT, quando inspecionada, então todos os atributos da cadeia de herança estão presentes, com defaults e picklists corretos, sem redefinição local.
2. Unicidade semântica — Dado que uma demanda nova é coberta por spec existente, quando classificada conforme a seção 36.1, então a classificação é REUSE_EXISTING e nenhuma spec duplicada é criada sem justificativa aprovada.

## Comentários

- Diego Beltrão de Moraes 19/08/2026 14:33: Assignee changed from Diego Beltrão de Moraes to Davi Israel de Abreu
- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
