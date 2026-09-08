# W-000116 — US B2C-32 — Mudança de plano B2C sem visita técnica (MACD asset-based)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 15:53 por Diego Beltrão de Moraes | Alterado: 08/09/2026 15:53 por Diego Beltrão de Moraes

US B2C (agenda presencial 03/09: temas "Operações MACD, Change of Plan e Pedidos de Ativos" e "Configuração de Mudança de Plano no Order Management"; discussão sobre Global Group Key).

NARRATIVA
Como Atendente ou cliente no autosserviço, quero mudar o plano de um cliente B2C ativo (upgrade ou downgrade de velocidade, inclusão de SVA) a partir do ativo existente, para que a alteração seja provisionada sem visita técnica quando não há troca de equipamento e com Work Order apenas quando há.

CONTEXTO E CENÁRIO DE NEGÓCIO
A B2B-05 (W-000100) cobre upgrade e swap no B2B. No B2C não há US de mudança de plano, e é a operação mais frequente da base. A decisão de arquitetura é asset-based ordering no OM: o pedido de mudança nasce do Asset, preserva o AssetReferenceId e a ServiceTag, e o plano de orquestração decide se há ou não Work Order pela natureza da mudança.

REGRAS DE NEGÓCIO
RN-01 Origem no ativo: toda mudança de plano parte do Asset ativo; não se cria venda nova para cliente com serviço ativo no mesmo endereço.
RN-02 Sem técnico quando só muda atributo: alteração de velocidade, perfil de upload ou SVA que não exija equipamento novo é provisionada por comando de rede, sem Work Order.
RN-03 Com técnico quando muda equipamento ou tecnologia: troca de CPE, de meio de acesso ou inclusão de câmera gera Work Order e movimenta estoque.
RN-04 Identidade preservada: o AssetReferenceId e a ServiceTag do serviço não mudam no upgrade de atributo; equipamento novo recebe nova ServiceTag EQ (US CAT-TAG-01).
RN-05 Preço e fidelidade: o novo preço vem da matriz da zona do endereço; upgrade pode renovar fidelidade apenas com aceite explícito do cliente; downgrade dentro da fidelidade respeita a regra de multa (US B2C-31).
RN-06 Faturamento: a mudança gera pro rata na fatura seguinte conforme a regra de corte do financeiro.
RN-07 Elegibilidade: a nova velocidade deve ser viável na tecnologia instalada; caso contrário a jornada oferece a troca com técnico.

ESPECIFICAÇÃO TÉCNICA
Asset-based ordering do Industries OM (Change of Plan) com carrinho aberto a partir do Asset; decomposição gera itens técnicos de "change" e o plano de orquestração ramifica: comando de rede via endpoint proprietário do Customer Core (Onda 1) ou Work Order (W-000094). Validação de viabilidade da velocidade contra a tecnologia do ServicePoint. Configuração de UseAssetReferenceIdForParentAndRoot compatível com MACD (ver considerações do Digital Commerce).

DEPENDÊNCIAS E RISCOS
Dependências: base de ativos migrada (US CAT-MIG-01); US CAT-TAG-01; W-000088 e W-000094; regra de pro rata com o financeiro; endpoint de mudança de plano no Customer Core.
Riscos: ativos legados sem estrutura pai-filho consistente; conflito de configuração entre MACD e APIs cacheáveis do Digital Commerce.

CRITÉRIOS DE ACEITE
Cenário 1: Upgrade de velocidade. Dado um cliente ativo em 400M com fibra, quando solicitar 600M, então o pedido de mudança é criado a partir do Asset, provisionado sem Work Order e o AssetReferenceId e a ServiceTag permanecem.
Cenário 2: Mudança com equipamento. Dado um cliente que inclui câmera, quando confirmar, então o pedido gera Work Order, baixa de estoque e nova ServiceTag para o equipamento.
Cenário 3: Velocidade inviável. Dado um cliente em tecnologia que não suporta a velocidade pedida, quando solicitar, então a jornada oferece a troca de tecnologia com visita e não permite o upgrade direto.
Cenário 4: Preço regional. Dado a mudança confirmada, quando o novo preço for calculado, então ele corresponde à matriz da zona de preço do endereço.
