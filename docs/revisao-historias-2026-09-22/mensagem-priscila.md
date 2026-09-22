# Conciliacao das historias com o Agile Accelerator - resumo para a gestao agil (22/09/2026)

Priscila, fechei a conferencia das historias dos dois documentos (Especificacao Funcional e Tecnica B2B e Historias Refinadas B2C, versoes 3) contra as Works do Agile em producao. Resultado:

**Works criadas: 14** (7 B2B, 7 B2C), todas em status New, sem sprint e sem pontos, responsavel Davi e voce como PO, com os criterios de aceite ja no objeto proprio:

B2B:
- W-000160: [ENTERPRISE ORDER MANAGEMENT - EOM] - Restrição de Edição pelo BKO e Bypass de Arquitetura para Vendas Expressas (epico 1) Vender soluções)
- W-000161: [SALES CORE] - Estruturação de Motivos e Submotivos para Perda de Leads e Oportunidades (epico 1) Vender soluções)
- W-000162: [ENTERPRISE CPQ] - Configuração e Precificação de Produtos na Modalidade Cortesia / Degustação (epico 2) Vender soluções como cortesia)
- W-000163: [SALES CORE / ADVANCED APPROVALS] - Aprovação Mandatória e Trava Comercial para Cortesias (epico 2) Vender soluções como cortesia)
- W-000164: [ENTERPRISE ORDER MANAGEMENT - EOM] - Decomposição, Provisionamento e Handoff de Cortesia (Payload Faturamento Nulo) (epico 2) Vender soluções como cortesia)
- W-000165: [ENTERPRISE CPQ / SALES CORE] - Negociação de Permuta de Serviços (Swap/SUAP) e Justificativa Comercial (epico 3) Vender soluções como swap)
- W-000166: [MACD / ENTERPRISE CPQ] - Upgrade de Serviços B2B SEM Refidelização Contratual (Manutenção da Vigência Original) (epico 4) Realizar upgrade)

B2C:
- W-000167: [ATENDIMENTO & RETENÇÃO] - Tratamento de Desligamento e Reversão de Plano Colaborador
- W-000168: [DASHBOARDS & AUDITORIA] - Relatório de Auditoria de Vendas (Cortesia e SWAP) com Débito Interno
- W-000169: [MACD & CPQ] - Venda Cortesia com Aprovação Prévia e Faturamento Zerado
- W-000170: [MACD & CPQ] - Venda Swap (Permuta) com Preço Flexível e Comprovação
- W-000171: [MACD / CPQ] - Upgrade B2C com Trava de Inadimplência e Refidelização Guarda-Chuva
- W-000172: [MACD / CPQ] - Downgrade B2C com Isenção de Multa Condicionada à Refidelização
- W-000173: [MACD / CPQ] - Sincronização Automática de Refidelização e Data de Reajuste Anual

**Historias que ja tinham Work: 45** (28 alinhadas e 17 com diferencas em relacao ao texto atual do documento ou aos comentarios da Fernanda). Nenhuma Work existente foi alterada; as diferencas estao listadas no relatorio de conciliacao para o time ajustar no refinamento. As mais relevantes:
- W-000100 (upgrade/swap B2B) virou a historia de upgrade COM refidelizacao; swap (W-000165) e upgrade SEM refidelizacao (W-000166) ganharam works proprias.
- W-000115 (tipos de operacao sem faturamento B2C) e W-000116 (mudanca de plano B2C) continuam como fundacao; cortesia, swap, upgrade e downgrade B2C ganharam works especificas (W-000169 a W-000172).
- W-000125 (downgrade B2B), W-000124 (fim de degustacao), W-000122 (contrato B2B), W-000120 (rastreio de parceiros), W-000060, W-000068, W-000061 (B2C) estao com cobertura baixa do texto atual do documento: precisam de revisao do conteudo.
- W-000012 nao entra; nas orfas, W-000132 e W-000133 tratam a mesma esteira de CI/CD e podem ser unificadas.

**Bloqueadas por definicao de negocio (a Work existe, o refinamento espera):**
- Tayza: B2B-01 (listagem de motivos, W-000096) e B2B-24 (premissas do cancelamento B2B, W-000099).
- Diretoria: B2B-26 (refidelizacao guarda-chuva, W-000142).
- COI: B2C-US-10 (criterio de segmentacao B2C/B2S, W-000062).
- GRs/processo: B2B-06 (auditoria BKO, W-000101).

**Historias superadas no proprio documento (nao viram Work):** 8, onde o documento acumulou versoes; vale sempre o bloco mais recente (detalhe no relatorio).

**Candidatas a historia nova vindas dos comentarios da Fernanda, aguardando decisao do Diego:** dashboard de Logistica e Compras; aceite formal da proposta com acompanhamento de assinaturas; historia separada para desenho de solucao x venda padrao; repositorio de evidencias no Customer Core; etapa de assinatura B2B por evidencia.

Relatorio completo: docs/revisao-historias-2026-09-22/conciliacao-works-2026-09-22.md.
