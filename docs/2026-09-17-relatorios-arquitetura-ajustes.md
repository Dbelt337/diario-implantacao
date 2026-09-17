# 17/09/2026 - Relatorios de Arquitetura: ajustes pedidos pelo Diego e limpeza da fila

Pedido (17/09, tarde), sobre os 3 relatorios da pasta "Performance Arquitetura" (publicados na prod pelo Diego):
1. Fila pendente: antes de tudo, identificar itens de "Aprovacao - Arquitetura" de oportunidade ganha ou perdida; criar um
   processo para fechar esses itens quando a oportunidade fecha; e regra no relatorio para nao considerar fechadas.
2. Validacoes por arquiteto: coluna de dias alem das horas.
3. Volume mensal: coluna de dias.

## 1. Fila pendente: o que existe hoje (leitura, 17/09 15h)

| Situacao dos 290 itens "Aprovacao - Arquitetura" com Status = Assigned | Qtde | Idade mediana |
|---|---|---|
| Oportunidade aberta | 243 (228 em "Viabilidade e desenho da solucao", 13 "Validacao tecnica", 1 "Em negociacao", 1 "Aguardando contrato") | 7 dias; 109 com mais de 7 dias, 20 com mais de 30 |
| Oportunidade **Fechado/Perdido** | 43 | 129 dias (maxima 287) |
| Oportunidade ganha / Instalado | 0 | - |
| Orfao (sem RelatedRecordId; orquestracoes de dez/2025 e fev/2026 ainda InProgress) | 4 | 281 dias |

As 43 opps fechadas continuam com Send4Approval__c = true, ArchitectureApproved__c = false e uma ApprovalSubmission InProgress
(orquestracao InProgress). A orquestracao OpportunityApprovalSteps_B2B nao tem condicao de saida para oportunidade fechada:
o item fica na fila para sempre. E por isso que a fila mostra 290 e nao 243, e que a mediana de idade dos pendentes parecia 178 h.

**Regra no relatorio.** O tipo de relatorio dos itens de orquestracao nao enxerga a oportunidade (RelatedRecordId e polimorfico),
entao nao da para filtrar "oportunidade fechada" nele. Solucao: um relatorio novo do lado da Oportunidade,
"Arquitetura - Opps aguardando (abertas)": oportunidades com IsClosed = false, Send4Approval__c = true e ArchitectureApproved__c =
false, agrupadas por fase, com a coluna "Dias na fase atual" (NOW() - LastStageChangeDate). E a mesma populacao dos 243 itens
abertos e exclui as fechadas por construcao. O relatorio antigo ("Fila pendente por idade", pelos itens) fica como visao de
auditoria: a diferenca entre os dois e exatamente o lixo a limpar.

**Limpeza (script 47, duas fases, so com o "vai").** Mecanismo: ApprovalSubmission.Status = 'Recalled' (o "Recolher" da tela; o
campo e atualizavel pela API e ja existe 1 Recalled na org) nas 43 submissoes InProgress das opps fechadas; para os 4 orfaos,
FlowOrchestrationInstance.Status = 'Canceled'. Fase 1 lista; fase 2 com LIMITE = 1 para testar em uma e conferir na tela se o item
some da fila; depois LIMITE = 100. Se a plataforma recusar o DML, o log mostra o erro e o caminho passa a ser recolher pela
tela (43 cliques) ou cancelar as orquestracoes em Setup > Orchestration Runs.

**Processo para nao voltar a acontecer (proposta, sem executar).** Flow record-triggered em Opportunity (after save), condicao:
IsClosed passou a true (ou StageName = Fechado/Perdido ou Instalado) e Send4Approval__c = true e ArchitectureApproved__c =
false. Acao: Get Records em ApprovalSubmission (RelatedRecordId = opp, Status = InProgress) e Update Status = Recalled; e
Update na opp: Send4Approval__c = false. Alternativa mais simples: acrescentar na orquestracao OpportunityApprovalSteps_B2B uma
condicao de saida do estagio "Send Approval - Arquitetura" quando $Record.IsClosed = true. As duas dependem do teste do script
47 provar que "Recalled" encerra o item da fila. Montar na sandbox primeiro (a org nao tem sandbox autenticada ainda).

## 2 e 3. Coluna de dias

Um relatorio Lightning aceita uma unica formula de linha (CDF1, hoje "Horas na fila"). A coluna de dias entrou como formula de
resumo "Dias na fila (media)" = CDF1:AVG / 24, com uma casa decimal, no nivel do arquiteto e no total geral:
- Arquitetura - Validacoes por arquiteto: media e maximo de horas por arquiteto + media de dias por arquiteto.
- Arquitetura - Volume mensal: media de horas e media de dias por arquiteto x mes.
Validado na prod com deploy check-only (0 erros), junto com o relatorio novo de oportunidades.

## Deploy (bloqueado para o Claude; rodar no terminal)

```
cd C:\Users\DIego\Documents\diario-implantacao\org
sf project deploy start -o btp-prod --wait 10 --metadata "Report:Performance_Arquitetura/Arq_Validacoes_Concluidas_por_Arquiteto" "Report:Performance_Arquitetura/Arq_Volume_Mensal_por_Arquiteto" "Report:Performance_Arquitetura/Arq_Opps_Aguardando_Arquitetura"
```

Limpeza da fila (depois do "vai"; primeiro com LIMITE = 1 no script, conferir, depois LIMITE = 100 e INCLUIR_ORFAOS = true):

```
sf apex run -o btp-prod --file scripts\47_FecharAprovacoesArquiteturaOppFechada_1709.apex
```
