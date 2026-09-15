# US B2B-14 — Aviso prévio de cancelamento B2B: prazo de 30/60/90 dias, janela de reversão, painel e corte automático

| Campo | Valor |
|---|---|
| Work | (a criar no Agile Accelerator) |
| Épico | B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente |
| Time (Scrum Team) | SysMap |
| Status | New |
| Responsável | a definir |
| Documento gerado em | 15/09/2026 |

US de negócio B2B (documento de 10/09, "Histórias novas", história 27; continuação da W-000099; comentários de negócio de 14/09 nas histórias 4 e 13: entradas pela Célula de Retenção, Central de Cancelamento e GR restrito à carteira; Arquitetura não atua na retenção). Fundamentação técnica em `docs/2026-09-15-fundamentacao-tecnica-historias-26-29.md`.

## Descrição
Como Central de Cancelamentos / Analista de Retenção BKO B2B
Quero registrar o prazo de aviso prévio do cancelamento corporativo, acompanhar a janela num painel e ter a desativação técnica e o Billing Stop disparados automaticamente só ao fim do prazo
Para que o serviço continue operante e faturado durante o aviso, a retenção tenha uma janela de reversão e o corte não dependa de planilha.

## Contexto e Cenário de Negócio
A W-000099 cobre a solicitação, as esteiras de retenção e o cálculo da multa e, na efetivação, dispara o Billing Stop. No B2B existe aviso prévio contratual de 30, 60 ou 90 dias entre a efetivação e o corte. Hoje isso é planilha. Esta US insere a janela entre a efetivação da W-000099 e o corte, com reversão possível e execução automática no D-Day.

## Regras de Negócio Associadas
RN-01 Ao efetivar o cancelamento (fim das esteiras da W-000099), o usuário informa o Aviso Prévio: 30, 60 ou 90 dias (valores em Custom Metadata). O sistema calcula Data Fim do Aviso Prévio = data de efetivação + prazo e grava na Oportunidade de cancelamento e no Contract.
RN-02 Status durante a janela: Contract Status "Em Aviso Prévio" (valor custom na categoria Activated, para o contrato seguir ativo em relatórios); Oportunidade de cancelamento em "Aguardando Fim do Aviso Prévio".
RN-03 Durante a janela nada é submetido ao Order Management nem ao Customer Core. Motivo: uma ordem de desativação submetida só pode ser cancelada in-flight antes do Point of No Return e gera ordem suplementar com rollback. A ordem de desativação só é criada no D-Day.
RN-04 Agendamento do corte: record-triggered flow no Contract com scheduled path, Time Source = Data Fim do Aviso Prévio, offset 1 dia depois, condição Status = "Em Aviso Prévio", batch 200. No disparo, o path chama a Integration Procedure que converte os assets do contrato em ordem (Convert Asset to Order, Assets Action Type Change, ação Delete no root bundle; quantidades ficam desabilitadas e one-time charges não são carregadas, comportamento padrão da conversão), submete ao OM (TEC-OM-01) e a decomposição gera a ordem técnica de desativação ao Customer Core pelo endpoint proprietário (TMF622 como mapa). O Billing Stop segue a regra da W-000099: só após callback do Customer Core.
RN-05 Reversão: ação "Reverter Cancelamento" visível para Retenção/BKO, Central de Cancelamentos e GR dono da conta. Ao acionar: motivo de retenção obrigatório (lista da W-000096), oferta de retenção aceita quando houver (CAT-RET-01, gera pedido de alteração via W-000100), Contract Status volta a Activated e a Oportunidade fecha como "Retido". Com a mudança de status o registro deixa de atender à condição do path e o agendamento é cancelado automaticamente, sem passo manual.
RN-06 Renegociação do prazo (ex.: de 90 para 60 dias): alterar a Data Fim do Aviso Prévio reagenda o corte para a nova data, desde que futura. Data no passado é bloqueada por Validation Rule.
RN-07 Painel: Lightning Dashboard e list views de contratos "Em Aviso Prévio" com dias restantes (campo fórmula), GR, célula de retenção e valor de MRR em risco. GR enxerga só a própria carteira (sharing por Account Owner e equipe); Retenção e Central veem tudo.
RN-08 Após o corte: Assets com provisioning status Deleted e status "Cancelado", Contract Status "Encerrado", Oportunidade de cancelamento Ganha (churn efetivado), conforme W-000099.
RN-09 Falha na execução: o scheduled path é retentado pela plataforma em 15, 30, 60, 120 e 240 minutos; se persistir, o flow cria Task para o BKO e o registro fica em "Corte com Falha" no painel. Fallout de orquestração é tratado no OM (Fallout Handling).
RN-10 Reversão após o D-Day (ordem já submetida): só o BKO pode cancelar a ordem in-flight, e apenas antes do Point of No Return; depois disso a reativação é uma venda nova (W-000097 em diante).
RN-11 Limites: 250.000 scheduled paths por 24 h; callouts em massa saem do OM/MuleSoft e não do flow; Default Workflow User configurado.

## Especificação Técnica (Salesforce)
Campos no Contract: Prazo de Aviso Prévio (picklist), Data Fim do Aviso Prévio (Date), Dias Restantes (fórmula), Motivo de Retenção (lookup à lista global); valores de Status "Em Aviso Prévio" e "Encerrado"; record-triggered flow "Contrato — Corte por Aviso Prévio" com scheduled path (RN-04) chamando Integration Procedure que usa a implementação ABO (Convert Asset to Order, ação Delete) e o checkout do TEC-OM-01; Quick Action "Reverter Cancelamento" (screen flow) com permissão por Permission Set; Validation Rule para data passada; Custom Metadata dos prazos; Dashboard e list views com sharing por carteira; relatório de execuções via Time-Based Automations e logs FLOW_SCHEDULED_PATH_QUEUED.

## Dependências, Riscos e Estimativa
Dependências: W-000099 (efetivação, multa, Billing Stop), W-000118 (TEC-OM-01 submissão), W-000088 (decomposição), W-000087 (integrações), W-000128 (CAT-RET-01 ofertas de retenção), W-000096 (motivos), W-000123 (360), W-000103 (Assets sincronizados), W-000090 (perfis e permissões).
Riscos: Customer Core sem execução programada exige que o Salesforce dispare no dia exato (assumido nesta US); contratos sem Asset não podem gerar ordem ABO; dependência da lista de entradas e alçadas com a Tayza (comentário de 14/09).
Estimativa: 8 Story Points.

## Critérios de Aceite (formato Agile Accelerator: Name | Status | Description)

| Name | Status | Description |
|---|---|---|
| Critério 1 — Prazo e data | New | Dado um cancelamento efetivado em 01/10 com aviso prévio de 30 dias, quando o usuário confirma, então Data Fim do Aviso Prévio = 31/10, Contract Status = "Em Aviso Prévio" e o contrato aparece no painel com 30 dias restantes. |
| Critério 2 — Nada no OM durante a janela | New | Dado um contrato em aviso prévio, quando se consulta as ordens do contrato durante a janela, então não existe ordem de desativação criada nem submetida ao OM e o faturamento segue ativo. |
| Critério 3 — Corte automático | New | Dado um contrato com Data Fim do Aviso Prévio em 31/10 e sem reversão, quando o sistema atinge 01/11 (data manipulada em QA), então o scheduled path cria e submete a ordem ABO de desconexão, o Customer Core recebe a ordem técnica e, após o callback, o Billing Stop é enviado e os assets ficam Deleted/Cancelado. |
| Critério 4 — Reversão cancela o agendamento | New | Dado um contrato aguardando aviso prévio de 60 dias, quando o Analista de Retenção aciona "Reverter Cancelamento" com motivo, então o Contract volta a Activated, a Oportunidade fecha como Retido e o agendamento some de Time-Based Automations sem nenhuma ordem gerada. |
| Critério 5 — Renegociação de prazo | New | Dado um contrato com corte agendado para 30/12, quando o usuário altera a Data Fim do Aviso Prévio para 30/11, então o agendamento passa a 01/12; e se tentar uma data passada, a Validation Rule bloqueia. |
| Critério 6 — Visibilidade por carteira | New | Dado dois GRs com carteiras distintas, quando cada um abre o painel, então vê apenas os contratos em aviso prévio das próprias contas, enquanto o perfil Retenção vê todos. |
| Critério 7 — Falha e retentativa | New | Dado que a Integration Procedure de submissão falha, quando o scheduled path executa, então a plataforma retenta e, esgotadas as tentativas, uma Task é criada para o BKO e o contrato aparece como "Corte com Falha". |
| Critério 8 — Reversão após submissão | New | Dado uma ordem de desativação já submetida e ainda antes do Point of No Return, quando o BKO aciona o cancelamento in-flight, então o OM congela a ordem e gera a suplementar; e um usuário GR não vê essa ação. |

Massa de teste sugerida: cotação de cancelamento aprovada com aviso de 30 dias; manipulação da data em QA para o 31º dia; contrato com 60 dias e reversão; usuário GR de outra carteira para o critério 6.
