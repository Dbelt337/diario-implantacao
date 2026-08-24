# -*- coding: utf-8 -*-
# Works EPC (catálogo) W-000051..W-000055 — extração de 24/08/2026.
# Scrum Team = Salesforce; critérios de aceite embutidos em agf__Details__c.

EPIC_CAT = 'Catálogo Comercial Unificado - B2B/B2C'

EPC_WORKS = [
{
 'id': 'W-000051',
 'subject': 'US EPC-01 — Criação das Attribute Categories do catálogo',
 'epic': EPIC_CAT, 'team': 'Salesforce', 'created': '2026-08-17T17:25:41',
 'details': '''Como Administrador do Catálogo de Produtos, quero a taxonomia de Attribute Categories definida e criada no EPC antes de qualquer atributo, com código estável, rótulo em português e sequência de exibição, para que todo atributo nasça vinculado a uma categoria governada.

Contexto: a documentação oficial do EPC exige categoria como pré-requisito para criar atributo (o tipo é definido no nível da categoria). Decisão de 14/08: a estruturação permanece no escopo; o agrupamento visual em interface está fora do escopo atual.

Regras: código CAT_ + domínio; taxonomia inicial de 8 categorias (CAT_CONECTIVIDADE_COMERCIAL, CAT_ENDERECAMENTO_IP, CAT_TECNICO_ACESSO, CAT_SLA_SUPORTE, CAT_SEGURANCA_GERENCIADA, CAT_WIFI_GERENCIADO, CAT_CONTRATO, CAT_INFRAESTRUTURA), a ratificar em ata da Onda 0; proibido atributo sem categoria ou categoria ad hoc por oferta.

Dependências: nenhuma — primeira peça da ordem de construção (manual v2.2, seções 7.1 e 41.1).

Fonte: US_modelo_refinos_v4, US EPC-01.''',
 'criteria': [
  'Criação prévia das categorias — Dado que o dicionário da Onda 1 foi aprovado, quando a parametrização iniciar no Product Console ou Designer, então as 8 categorias existem ativas, com código CAT_, rótulo e Display Sequence, antes do primeiro atributo.',
  'Vínculo obrigatório — Dado que um novo atributo será criado, quando o registro for salvo, então ele referencia exatamente uma categoria da taxonomia aprovada e a matriz atributo-categoria é atualizada.',
  'Integridade estrutural — Dado que o dicionário foi carregado, quando a auditoria de cadastro consultar vínculos e sequências, então todo atributo tem exatamente uma categoria e toda categoria tem Display Sequence. A exibição visual não é critério desta história (fora de escopo, decisão de 14/08).',
 ],
},
{
 'id': 'W-000052',
 'subject': 'US EPC-04 — Hierarquia de Object Types, atribuição de atributos por nível e layouts',
 'epic': EPIC_CAT, 'team': 'Salesforce', 'created': '2026-08-17T17:26:43',
 'details': '''Como Arquiteto de Solução do catálogo, quero a hierarquia de Object Types da seção 35.3 criada, com a matriz de atribuição de atributos por nível e os layouts base finalizados antes dos subtipos, para que a herança dinâmica de atributos e a herança por cópia dos layouts operem a favor do reuso.

Regras: o Object Type base carrega campos, não atributos; cada atributo entra no menor nó comum; layout do pai fecha antes de criar filhos (cópia profunda não replica mudanças posteriores); parent não muda após existirem descendentes sem ADR. Extensão para serviços gerenciados via ADR: OT_MANAGED_SERVICE_OFFER, OT_MANAGED_SECURITY_PRODUCT_SPEC e OT_MANAGED_WIFI_PRODUCT_SPEC. Ratificar a 35.3 como normativa em ata (P-08, ato interno da sessão).

Dependências: esqueleto da hierarquia, campos e layouts executáveis desde já; a atribuição de atributos consome a saída da EPC-03.

Fonte: US_modelo_refinos_v4, US EPC-04 (matriz categoria-atributo-Object Type completa).''',
 'criteria': [
  'Hierarquia aprovada antes dos subtipos — Dado que a hierarquia 35.3 com a extensão de gerenciados foi submetida, quando a criação iniciar, então os nós base têm atributos, campos e layout finalizados antes de qualquer subtipo, e nenhum parent muda após existirem descendentes sem ADR.',
  'Herança dinâmica validada — Dado que um atributo foi atribuído ao Object Type pai, quando um subtipo ou spec vinculada for consultada, então o atributo consta herdado automaticamente, com teste de herança evidenciando a propagação.',
  'Layout contém o que deve aparecer — Dado que o layout do pai foi definido com seções por categoria, quando um produto novo for criado do Object Type, então todos os atributos e campos esperados aparecem; atributo fora do layout é defeito de parametrização.',
 ],
},
{
 'id': 'W-000053',
 'subject': 'US EPC-05 — Criação das Product Specifications das famílias da Onda 1',
 'epic': EPIC_CAT, 'team': 'Salesforce', 'created': '2026-08-17T17:28:17',
 'details': '''Como Administrador do Catálogo, quero as Product Specifications conceituais e reutilizáveis criadas a partir dos Object Types aprovados, para que as ofertas realizem definições únicas, sem preço, sem duplicação estrutural.

Escopo: PS_MANAGED_CORPORATE_INTERNET, PS_MANAGED_FIREWALL e PS_MANAGED_WIFI, mais as especificações dos componentes reutilizáveis (acesso, conexão, NOC, Anti-DDoS, Fail-Over, Bastidor). Regra de escala (14/08): especificações são padrões semânticos genéricos; toda oferta nova parte de REUSE_EXISTING (seção 36.1) e criar spec nova é exceção justificada. Specs não recebem preço, canal ou catálogo.

Dependências: Object Types da EPC-04.

Fonte: US_modelo_refinos_v4, US EPC-05.''',
 'criteria': [
  'Herança integral do Object Type — Dado que a spec foi criada vinculada ao OT, quando inspecionada, então todos os atributos da cadeia de herança estão presentes, com defaults e picklists corretos, sem redefinição local.',
  'Unicidade semântica — Dado que uma demanda nova é coberta por spec existente, quando classificada conforme a seção 36.1, então a classificação é REUSE_EXISTING e nenhuma spec duplicada é criada sem justificativa aprovada.',
 ],
},
{
 'id': 'W-000054',
 'subject': 'US EPC-09 — Compilação de atributos, batch jobs e validação de integridade do catálogo',
 'epic': EPIC_CAT, 'team': 'Salesforce', 'created': '2026-08-17T17:32:28',
 'details': '''Como Administrador do Catálogo, quero a rotina de compilação e as validações de integridade executadas e evidenciadas ao final de cada bloco de parametrização, para que os atributos apareçam corretamente em runtime, inclusive nos produtos legados da org.

Regras: executar EPCProductAttribJSONBatchJob ao atribuir atributo a Object Type que já tem produtos, e EPCFixCompiledAttributeOverrideBatchJob quando houver overrides, com evidência e contagem de registros. Antes de atribuir a OTs existentes, gerar o relatório de impacto da seção 35.5 (descendentes, Quotes, Orders, Assets, rollback). Ponto crítico no RadarDev pelos produtos legados. Definition of Done ampliada da 41.4.

Dependências: transversal — roda após cada bloco (EPC-01, 03, 04 e ofertas).

Fonte: US_modelo_refinos_v4, US EPC-09.''',
 'criteria': [
  'Compilação evidenciada — Dado que atributos foram atribuídos a OT com produtos, quando o bloco for concluído, então os jobs executaram com sucesso e os atributos aparecem na criação de produto e no carrinho.',
  'Definition of Done ampliada — Dado que a entrega foi declarada pronta, quando o checklist da 41.4 for aplicado, então não há picklist órfã, valor sem pricing ou mapping obrigatório, linha faturável sem material, nem falha nos testes de herança e não regressão.',
 ],
},
{
 'id': 'W-000055',
 'subject': 'US EPC-03 (P) — Dicionário de atributos com metadados de governança — escopo parcial, sem atributos do WITO',
 'epic': EPIC_CAT, 'team': 'Salesforce', 'created': '2026-08-17T17:33:30',
 'details': '''Como Administrador do Catálogo, quero os atributos da Onda 1 criados com os metadados completos da seção 35.4 (AttributeCode, DataType, categoria, PicklistCode, default, visibilidade e editabilidade por canal, Assetizable, PricingImpact, OMImpact, EligibilityImpact, lifecycle e owner).

ESCOPO PARCIAL DESTA WORK: excluir FIREWALL_VENDOR e WIFI_VENDOR (aguardam confirmação do WITO, P-02); defaults pendentes entram como "a confirmar" (NOC_TIER, P-01; LICENSE_TIER, P-10). Criação exclusivamente via Product Console ou Designer. O de-para comercial-técnico completo fica para as USs de decomposição (onda de OM). A planilha ganhará colunas de Atribuição do pai e Categoria por atributo (ação de 14/08).

Dependências: categorias da EPC-01; atributos do tipo Picklist dependem da EPC-02 (bloqueada) — priorizar escrita técnica e atributos sem picklist.

Fonte: US_modelo_refinos_v4, US EPC-03.''',
 'criteria': [
  'Completude dos metadados — Dado que um atributo foi criado, quando o dicionário for auditado, então nenhum atributo está sem categoria, sem picklist quando do tipo Picklist, sem default aprovado ou sem os impactos declarados.',
  'Criação só pelo console — Dado que a equipe recebeu o dicionário, quando qualquer atributo for criado ou alterado, então a operação ocorre no Product Console ou Designer; fora disso é não conformidade.',
  'Derivação sem dupla entrada — Dado que o vendedor selecionou um valor comercial, quando a linha for processada para o OM, então o valor técnico vem do atributo derivado por Mapping Rule, sem nova digitação.',
 ],
},
]
