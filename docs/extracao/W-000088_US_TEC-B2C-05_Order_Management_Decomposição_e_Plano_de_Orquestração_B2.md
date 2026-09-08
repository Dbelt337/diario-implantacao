# W-000088 — US TEC-B2C-05 — Order Management: Decomposição e Plano de Orquestração B2C

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-05: Order Management: Decomposição e Plano de Orquestração B2C
Narrativa: Como time de implantação, quero o checkout da cotação gerando Order e um plano de orquestração no Industries OM que provisione o serviço no Customer Core, para o fechamento da venda ser sistêmico e rastreável.
Escopo técnico:
- Checkout Quote > Order pelas Cart-Based APIs.
- Decomposição da ordem comercial em ordem técnica (fulfillment requests) para os produtos B2C da Onda 1.
- Orchestration Plan com tarefas: aguardar pagamento/liberação, agendar instalação (Field Service), ativar no Customer Core (TMF622/641), receber callback de ativação.
- Callback de sucesso do Customer Core conclui a orquestração e atualiza a Oportunidade para Ganho (US-21), bloqueando edição retroativa.
- Tratamento de falha de ativação: tarefa de reprocesso + notificação (liga com US-20).
Critérios de aceite: pedido E2E em sandbox com mock do Customer Core percorrendo o plano até Closed Won; falha de ativação gera tarefa de reprocesso sem perder a ordem.
Dependências: TEC-02 (catálogo), TEC-04 (integrações), definição do contrato de ativação com o Customer Core.

## Critérios de Aceite (related list)

**1. Critério 2** (New)
falha de ativação gera tarefa de reprocesso sem perder a ordem.

**2. Critério 1** (New)
pedido E2E em sandbox com mock do Customer Core percorrendo o plano até Closed Won.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO 01/09/2026 ---
Requisito funcional da orquestração publicado pelo negócio (works B2C-27 e B2C-28). Destino do dado do pedido definido: Customer Core via barramento (MuleSoft/Apigee), com TMF641 consumido no OSS para ativação, TMF622 para notificação de estado e TMF637 para inventário/Assets. Incluir no plano: decomposição CP2TP, Callout/Auto Tasks, fallout management (Fatally Failed + fila N2) e etapa de Field Service (WorkOrder/ServiceAppointment).

--- ALINHAMENTO COM B2B ---
Esta fundação de OM atende também a jornada B2B (B2B-04 cancelamento com Billing Stop, B2B-05 upgrade/swap, B2B-06 handoff). Pendência de decisão registrada na B2C-27 (W-000093): padrão de decomposição Salesforce OM x Customer Core.

--- DECISÃO DE ARQUITETURA 01/09/2026 (substitui a pendência acima) ---
Decomposição ÚNICA no Salesforce Industries OM para B2C e B2B, dirigida pelo Shared Catalog/EPC (produto comercial e técnico no mesmo catálogo). Customer Core e ERP atuam como executores: provisionamento de rede e billing, recebendo ordens técnicas via barramento e devolvendo callbacks. No B2B, o botão Imputar Venda permanece como gate do BKO e passa a SUBMETER a ordem ao OM (com idempotência). Transição: enquanto o catálogo técnico B2B não estiver modelado no EPC, o plano de orquestração B2B roda em modo passthrough (Callout Task única de handoff + callback), evoluindo para decomposição plena. Fundamento: função documentada do OM e do Shared Catalog; prática eTOM de ponto único de decomposição guiado por catálogo.

--- CAMPOS FISCAIS PARAMETRIZADOS NA ORDEM (04/09, ata de 03/09) ---
No checkout Quote > Order, incluir campos parametrizados por LINHA da ordem: codigo de material SAP e descricao fiscal da nota (listas de selecao mantidas pela gestao de produtos). Motivo: contratos estaduais/federais (ex.: RS, Banco do Brasil, Caixa) exigem descricoes e tipos de nota distintos para o mesmo servico; a parametrizacao na ordem evita duplicar ofertas no catalogo. A linha da oferta deve carregar toda a informacao que o SAP precisa, sem amarracoes externas.

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #13) - a decomposicao JA OPERA em producao.
REUSAR: BTecParPF_Accept > RA_DecomposeAndCreatePlan > BTecParPf_OrderController > Industries Decomposition API (REST interno); Orchestration Items existentes.
EVIDENCIA: force-app/main/default/classes/BTecParPf_OrderController.cls | vlocity-backup/OrchestrationItemDefinition.
CONSTRUIR: tarefas novas do plano (aguardar pagamento, Field Service, callback de ativacao), produtos da Onda 1 e campos fiscais por linha (nota anterior).
DIRETRIZ SYSMAP: a fundacao de OM e EVOLUCAO do plano existente, nao greenfield - partir do OrderController e dos Orchestration Items de producao.
