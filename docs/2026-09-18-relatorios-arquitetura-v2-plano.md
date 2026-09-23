# 18/09/2026 - Relatorios de Arquitetura v2: decisoes da reuniao (Diego, Priscila, Vilson) e plano tecnico

Reuniao de 18/09 sobre a pasta "Performance Arquitetura" (4 relatorios). Vilson de Moura Hopf Junior validou o conceito e
apontou inconsistencias; Priscila De Lima estruturou as visoes; versao revisada a apresentar na terca-feira 22/09, depois de
testes internos (Priscila, Thais, Diego).

## Decisoes

1. Relatorios de desempenho divididos em duas fases: **viabilidade tecnica** ("Viabilidade e desenho da solucao") e **validacao
   tecnica**.
2. Expurgar do tempo de validacao tecnica os periodos em que a responsabilidade esta com o vendedor, o C-level ou o BKO.
3. Filtro de usuarios (lista de arquitetos, que o Vilson vai mandar, incluindo o usuario "Jefferson MF") no relatorio de volume
   trimestral.
4. Quatro visoes: (a) fila geral, quem esta e ha quanto tempo; (b) detalhe por arquiteto responsavel e tempo; (c) tempo total
   de permanencia na fila de arquitetura, independente de quem tratou; (d) produtividade mensal, itens fechados.
5. Indicadores adicionais (Vilson): tempo medio da fase de viabilidade por setor e por pessoa; taxa de aprovacao dos projetos
   que avancam para validacao tecnica.

## O que a org ja tem e muda o desenho (levantado em 18/09, leitura)

- **Campos de SLA na Oportunidade, ja preenchidos por automacao**: `SLAViability__c` (Inicio Viabilidade, data/hora),
  `SLAArchitect__c` (Inicio Arquitetura = inicio da validacao tecnica), `SLAViabilityArch__c` (duracao da viabilidade, texto
  hh:mm:ss, ex.: 397:15:47) e `SLATechValidArch__c` (duracao da validacao tecnica, texto, ex.: 3:21:12). Preenchimento nas
  B2B dos ultimos 180 dias: 4.790 de 8.040 com viabilidade, 2.811 com validacao. Sao exatamente as duas fases da decisao 1.
  Quem preenche: nao esta nos 18 flows recuperados nem apareceu na busca em Apex; confirmar em Setup (provavel flow ou
  trigger de Opportunity nao recuperado). Os campos de duracao sao texto, entao nao somam em relatorio; o caminho e usar as
  datas de inicio com formula de linha, ou o historico de fases.
- **Tipo de relatorio "Historico de oportunidades"** (OpportunityHistory) tem a coluna **Duracao da fase** (STAGE_DURATION, em
  dias), fase de origem e fase de destino, proprietario e data. Da o tempo por fase por oportunidade, no historico inteiro,
  sem formula. Como "Aprovacao comercial", "Aprovacao credito" e "Analise cliente" sao fases proprias, o tempo delas fica
  naturalmente fora da duracao de "Validacao tecnica": e a base da decisao 2. O que nao separa e o tempo parado dentro da
  mesma fase esperando formulario BKO (campo BackofficeForm__c, que tem historico de campo).
- **As 47 orquestracoes canceladas hoje (scripts 47 e 48)** deixaram os itens como Completed com Step Run Status = Canceled.
  Sem filtro, entrariam no relatorio de concluidos como "validacoes" de meses. Correcao: filtro "Orchestration Step Run:
  Status = Completed" nos relatorios de concluidos (aplicado no metadado, ver abaixo). Itens concluidos de verdade hoje: 22,
  por 10 arquitetos.
- **Caso dos 191 dias em "Em negociacao"** que o Vilson achou: oportunidade "Luiz- Conectividade de Campo grande", item de
  04/03 (198 dias hoje), Send4Approval = true, ArchitectureApproved = false, fase Em negociacao. A orquestracao foi
  disparada e a oportunidade voltou de fase sem a aprovacao terminar. Mesmo mecanismo da limpeza: cancelar a orquestracao
  (script 48 so trata fechadas; decidir se abertas fora das fases tecnicas tambem entram; ha 2 casos: essa e "AJUSTE
  MENSALIDADE - BAGGIO", em Aguardando contrato com ArchitectureApproved = true).
- **Nome do arquiteto no item pendente**: o item fica atribuido a fila "Arquitetura" ate alguem concluir; a coluna "Assigned
  User" so aparece se o arquiteto reatribuir o item para si. Nao existe campo de arquiteto na Oportunidade (so os SLAs).
  Duas opcoes: (i) pratica: o arquiteto "assume" o item (reatribui para si) ao comecar, e o relatorio ja mostra; (ii) campo
  novo `Arquiteto__c` (lookup User) na Oportunidade, preenchido por flow quando o item e concluido (quem aprovou) e, se
  houver (i), quando e assumido. Recomendo (i) agora e (ii) na sprint seguinte.

## Plano por item das proximas etapas

| # | Etapa (dono) | Como fazer | Dependencia |
|---|---|---|---|
| 1 | Identificacao do arquiteto (Diego) | Coluna "Assigned User" ja existe nos relatorios de fila; adotar a pratica de assumir o item. Campo Arquiteto__c na Oportunidade como evolucao, com flow no fechamento do item | Vilson combinar a pratica com o time |
| 2 | Revisar calculo de medias (Diego) | (a) filtro Step Run Status = Completed, tira as canceladas; (b) mostrar, por arquiteto, contagem, soma de horas, media e maximo, para os numeros fecharem entre si; (c) trocar "ultima modificacao" por data de conclusao onde existir; (d) explicar que media de 30 dias com 1.400 itens/mes e puxada por outliers: acrescentar faixas (ate 24h, 24 a 72h, 3 a 7 dias, mais de 7 dias) por contagem | nenhuma |
| 3 | Quatro visoes (Diego) | (a) Fila geral: relatorio de itens pendentes por idade, ja existe, mais o de oportunidades abertas aguardando; (b) por arquiteto: itens pendentes com Assigned User + concluidos por Modificado por; (c) tempo total na fila: relatorio Historico de oportunidades, fases Viabilidade e Validacao tecnica, Duracao da fase por oportunidade; (d) produtividade mensal: Volume mensal, ja existe, com o filtro de usuarios | item 8 para (d) |
| 4 | Segmentar por fase (Diego) | Duas copias de cada relatorio de tempo: uma com Fase = "Viabilidade e desenho da solucao" e outra com Fase = "Validacao tecnica" (no Historico de oportunidades pela coluna Fase de origem; nos itens de orquestracao nao ha fase, usar a fase atual da oportunidade no relatorio de oportunidades aguardando) | nenhuma |
| 5 | Filtros de exclusao (Diego) | No Historico de oportunidades a exclusao e automatica (fases de aprovacao e Analise cliente sao outras fases). Para o BKO: filtro cruzado "sem historico de BackofficeForm__c no periodo", ou aceitar como limitacao e reportar a parte. Validar com Priscila quais fases sao "de outros" | decisao da Priscila sobre a lista de fases |
| 6 | Visao trimestral com Vilson (Diego, Priscila) | Volume mensal ja cobre 90 dias; acrescentar agrupamento por trimestre e as faixas do item 2 | item 8 |
| 7 | Service level (Priscila, com Tayza) | Definir a meta em horas por fase (ex.: viabilidade 72h, validacao 24h) para o relatorio marcar dentro/fora do SLA com uma formula de resumo | Priscila |
| 8 | Filtro de usuarios (Diego) | Filtro "Modificado por: Nome" igual a lista, com os nomes que o Vilson mandar; alternativa mais robusta: filtro por Perfil/Role nao existe nesse tipo de relatorio, entao a lista e o caminho | lista do Vilson |
| 9 | Reuniao com Vilson (Priscila) | terca 22/09 ou quarta 23/09 | testes internos antes |

## Indicadores adicionais do Vilson (decisao 5)

- Tempo medio de viabilidade por setor e por pessoa: Historico de oportunidades, Fase de origem = Viabilidade e desenho da
  solucao, agrupado por Proprietario (setor via Papel do proprietario ou Cluster da oportunidade) e por "Modificado pela
  ultima vez por" (quem tirou da fase). Alternativa mais fiel a pessoa: campo Arquiteto__c (item 1, opcao ii).
- Taxa de aprovacao para validacao tecnica: no mesmo tipo de relatorio, contar oportunidades que sairam de Viabilidade para
  Validacao tecnica x para Fechado/Perdido ou Analise cliente; formula de resumo = aprovadas / total.

## Ja aplicado hoje no metadado (validado, deploy pendente)

- Filtro "Orchestration Step Run: Status = Completed" nos relatorios "Validacoes por arquiteto" e "Volume mensal", para
  excluir as orquestracoes canceladas na limpeza.

## Cronograma

- 18/09 a 19/09: montar as visoes (itens 2, 3, 4, 8) no metadado; validar com deploy check-only; publicar.
- 19/09: lista de arquitetos do Vilson; Priscila define fases "de outros" (item 5) e meta de SLA (item 7).
- 21/09: testes internos Priscila, Thais, Diego.
- 22/09 ou 23/09: apresentacao ao Vilson.

## Publicado em 18/09, 11h05 (deploy 0AfV2000000tzXVKAY, 8/8): links

- Arq - Fila pendente por arquiteto: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009dQn6MAE/view
- Arq - Validação técnica: dias por arq.: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009dQn3MAE/view
- Arq - Viabilidade: dias por arquiteto: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009dQn5MAE/view
- Arq - Viabilidade: saídas por destino: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009dQn4MAE/view
- Arquitetura - Fila pendente por idade: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009cR6rMAE/view
- Arquitetura - Opps aguardando (abertas): https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009cqy5MAA/view
- Arquitetura - Validações por arquiteto: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009cR6sMAE/view
- Arquitetura - Volume mensal: https://prod-brasiltecpar.lightning.force.com/lightning/r/Report/00OV2000009cR6tMAE/view

## Leitura dos primeiros numeros (18/09, 11h30, via API depois do deploy 0AfV2000000tzdxKAA)

- Viabilidade (90 dias): 1.930 saidas, media 7,1 dias, maximo 213, soma 13.713 dias. Destinos: **Analise cliente** (aprovada,
  vai para proposta) e **Em negociacao** (devolvida). Nenhuma sai direto para Validacao tecnica: a taxa de aprovacao da
  viabilidade e Analise cliente / total. Por pessoa (soma de dias): Andre 2.729, Gilmar 1.591, Alex 1.141, Jeferson 595,
  Joao Pedro 310, Clayton 136, Franklin 119; "Automated Process" 2.663 (saidas automaticas, ex.: viabilidade expressa).
- Validacao tecnica (90 dias): 1.640 saidas, media 1,3 dia, maximo 32. Quem tira da fase e sempre o Automated Process (a
  orquestracao muda a fase apos a aprovacao): por pessoa nao existe no historico. O relatorio virou "dias por mes" (visao de
  time); a visao por arquiteto da validacao continua sendo "Validacoes por arquiteto" (itens da fila).
- Ajustes aplicados no metadado: validacao agrupada por mes; saidas por destino com grafico por quantidade; descricoes.

## 21/09: evolucao dos tres relatorios originais (deploy 0AfV2000000uBgjKAE, 3/3)

Decisao do Diego (21/09): manter os tres primeiros relatorios e evoluir a partir deles. Lista oficial de arquitetos recebida
(17 nomes, todos ativos, perfil B2B - Especialistas; Matheus De Jesus Barbosa De Oliveira e Priscila Schafhauzer sem papel):
Alex Bruno Bueno Maass, Andre Vicente Teixeira da Silva, Clayton Mogami, Franklin Santos Lima, Gilmar Benjamim Batista,
Jeferson Manfio, Joao Pedro Oliveira Martins, Luis Henrique Correa De Oliveira, Marcelo Costa Ribeiro, Matheus Resende Silva,
Matheus De Jesus Barbosa De Oliveira, Paulo Cesar Davet Junior, Paulo Cesar Smith, Pedro Teixeira Jacques, Priscila
Schafhauzer, Vinicius Cattaneo Camboim, Willians Pereira dos Santos.

| Relatorio | O que mudou |
|---|---|
| Arquitetura - Validacoes por arquiteto | filtro "Modificado por" = lista dos 17 (item 8 do plano; destravado, da para editar na tela); por arquiteto agora mostra quantidade, horas soma/media/maximo e dias media/maximo/soma (item 2b) |
| Arquitetura - Fila pendente por idade | segundo nivel de agrupamento por Assigned User (quem assumiu; vazio = ainda na fila), detalhe ordenado da idade maior para a menor (item 3a) |
| Arquitetura - Volume mensal | filtro dos 17 arquitetos e soma de horas ao lado da media (item 8 e 2b) |

Leitura depois do deploy (21/09): 1.206 validacoes concluidas nos ultimos 30 dias pelos 17, 15 arquitetos com itens (os dois
sem papel nao tem nenhum); 224 pendentes, media 12,2 dias, maximo 200,8; itens assumidos por Paul Nabih Raad e Gilmar Balbinot, que nao estao na
lista de arquitetos (conferir com o Vilson se entram ou se sao BKO).

Limites que ficaram: (1) o tipo de relatorio de itens de orquestracao expoe so 13 colunas (nome, datas, status, atribuido,
modificado por); nao ha data de conclusao propria nem o registro relacionado, entao "conclusao" continua sendo a ultima
modificacao e a oportunidade so aparece no relatorio "Opps aguardando"; (2) faixas de tempo (ate 24h, 24-72h, 3-7 dias, mais
de 7) exigiriam uma segunda formula de linha, e o tipo permite uma so; alternativa e um relatorio por faixa ou o campo de SLA na
Oportunidade. Os cinco relatorios de fase (v2 de 18/09) ficaram publicados sem alteracao; remover so com decisao do Diego.

## 21/09: "Opps aguardando (abertas)" so nas fases tecnicas (deploy 0AfV2000000uBlZKAU)

Pedido do Diego: o relatorio nao pode mostrar "Em negociacao"; so Viabilidade e desenho da solucao e Validacao tecnica.
Antes do filtro havia 250 oportunidades abertas com Send4Approval e sem ArchitectureApproved: 205 em Viabilidade, 19 em
Validacao tecnica, 14 em Analise cliente, 9 em Aprovacao comercial, 2 em Em negociacao, 1 em Analise financeira. Filtro de
fase acrescentado (destravado); as 26 fora das fases tecnicas sao os casos do item "orquestracao disparada e a oportunidade
voltou de fase" e ficam para a limpeza permanente (flow de cancelamento).

## 21/09: requisitos consolidados (lista da Priscila/Vilson) x situacao

Fato que limita o desenho: a orquestracao "[Oportunidade] Controle de filas aprovacao" (OpportunityApprovalSteps_B2B) usa o
MESMO passo "Aprovacao - Arquitetura" para as duas fases: dispara em Viabilidade e desenho da solucao, ou em Validacao
tecnica quando BackofficeForm = true. O item da fila nao guarda a fase, e o tipo de relatorio de itens expoe 13 colunas
(sem oportunidade, sem fase, sem data de conclusao propria). Por isso: nos relatorios de ITENS a fase so entra por limpeza
de dados (a fila so deve ter itens de opps nas fases tecnicas); nos relatorios de HISTORICO DE OPORTUNIDADE a fase e nativa.

| # | Requisito | Situacao em 21/09 | Onde |
|---|---|---|---|
| 1a | Fila geral: usuario responsavel por item | feito: agrupamento por Assigned User (vazio = fila) | Fila pendente por idade |
| 1b | Fila geral: o que esta na fila e ha quanto tempo | feito: dias na fila por item, ordenado do mais antigo | Fila pendente por idade |
| 1c | Limpeza de automacoes indevidas / fora do fluxo | 47 opps fechadas limpas em 18/09 (scripts 47/48); hoje 224 pendentes: 204 Viabilidade, 19 Validacao tecnica, 1 Em negociacao -> script 50 cancela essa; permanente: flow que cancela a orquestracao quando a opp sai das fases tecnicas ou fecha (sandbox) | script 50 |
| 2a | Detalhe por arquiteto: quem esta com o que e ha quanto tempo | feito: pendentes por Assigned User | Fila pendente por arquiteto |
| 2b | Revisao das formulas de tempo (criacao ate ultima modificacao) e coerencia media/maximo/quantidade | feito: horas soma/media/maximo + dias media/maximo/soma + quantidade, por arquiteto; so passos Completed (exclui cancelados) | Validacoes por arquiteto |
| 2c | Tempo medio de atendimento por profissional | feito (mesmo relatorio, media em horas e em dias) | Validacoes por arquiteto |
| 3a | Tempo total na fila de arquitetura, independente de quem atendeu | existe: total geral de Validacoes por arquiteto (itens) e, por fase, Viabilidade: dias por arquiteto (total) e Validacao tecnica: dias por mes | relatorios de fase |
| 3b | Tempo medio de elaboracao de projetos/desenho no setor | existe: Viabilidade: dias por arquiteto, total geral (media 7,1 dias em 18/09) | Viabilidade: dias por arquiteto |
| 4a | Volume atendido no mes | feito | Volume mensal |
| 4b | Visao 90 dias | feito | Volume mensal |
| 4c | Filtro pela lista de arquitetos, incluindo Jeferson Manfio | feito: 17 nomes, filtro destravado | Validacoes por arquiteto, Volume mensal |
| 4d | Taxa de conversao (desenhados que avancam) | feito hoje: formula "Taxa (% das saidas)" por destino (Analise cliente = avancou; Em negociacao = devolvida); deploy 0AfV2000000uBonKAE | Viabilidade: saidas por destino |
| T1 | Duas versoes por fase (Viabilidade x Validacao tecnica) | historico de oportunidade: ja separado (2 relatorios de viabilidade, 1 de validacao); itens de orquestracao: impossivel separar (mesmo passo nas duas fases, item sem fase). Alternativa: campo na oportunidade preenchido pelo flow ao criar o item (fase no momento) e relatorio de oportunidade | decisao |
| T2 | Expurgo de terceiros na validacao tecnica (vendedor, C-level, Red, BKO) | historico de oportunidade: automatico para o que e fase propria (Aprovacao comercial, Aprovacao credito, Analise cliente ficam fora da duracao de Validacao tecnica). O que NAO separa: espera de formulario BKO dentro da mesma fase (BackofficeForm__c tem historico de campo, mas nao entra no tipo de relatorio). Precisa de fase propria "Pendente BKO" ou de campo de data/hora preenchido por flow | decisao Priscila |

Relatorios de fase (18/09) continuam publicados: sao eles que atendem 3a, 3b, 4d e T1 no historico de oportunidade.

### 21/09, 14h26: script 50 executado pelo Diego

1 orquestracao cancelada (Luiz- Conectividade de Campo grande, Em negociacao desde 11/03), 0 falhas. Fila de Arquitetura
depois: 223 itens no momento do script (224 na leitura dos relatorios minutos depois, um item novo entrou), todos de
oportunidades em Viabilidade e desenho da solucao ou Validacao tecnica. Idade maxima na fila caiu de 200,8 para 76 dias.
Itens assumidos: Paul Nabih Raad 18, Gilmar Balbinot 2; 204 ainda na fila sem dono.

## 23/09: indicadores do e-mail do Vilson (TMEP, TAP, SLA de entregas) medidos do item de aprovacao

Decisao do Diego: o relogio comeca quando o item de aprovacao e criado para a Arquitetura, nao quando a fase muda. A org ja
tinha os marcos de inicio (SLAViability__c "Inicio Viabilidade" e SLAArchitect__c "Inicio Arquitetura", gravados pelo flow
[Anexo] Anexar documentos no envio para aprovacao, no mesmo instante da criacao do item). Faltava a conclusao e o arquiteto.

Construido (org/force-app, validado na staging 0AfHZ00000QQUQ50AP e na producao em check-only 0AfV2000000uMInKAM):
- Campos na Oportunidade: ArchViabilityConcludedAt__c, ArchTechValidConcludedAt__c (conclusao do item por fase),
  Architect__c (quem concluiu = LastModifiedBy do FlowOrchestrationWorkItem, que bate com os 17 nomes; so 132 dos 5.802
  itens de 120 dias tinham sido assumidos, por isso o assignee nao serve), ArchViabilityDays__c e ArchTechValidDays__c.
- Flow record-triggered [Oportunidade] Marcos da fila de Arquitetura: quando Send4Approval__c passa a falso com a fase
  anterior em Viabilidade ou Validacao tecnica, busca o ultimo item "Aprovacao - Arquitetura" concluido apos o marco de
  inicio e grava conclusao e arquiteto. Nao toca no flow de controle nem na orquestracao.
- Permission set Arquitetura_Marcos_Leitura (leitura dos 7 campos).
- Relatorios novos na pasta Performance Arquitetura, tipo Oportunidades, 90 dias pela data de conclusao:
  "Arq - TMEP: tempo de elaboracao" (dias item criado ate concluido, por arquiteto), "Arq - TAP: taxa de aprovacao de
  projetos" (bucket de destino: negocio fechado / validado e em proposta / devolvido / perdido, com % do total) e
  "Arq - SLA de entregas" (bucket dentro/fora da meta, 5 dias como valor provisorio, por arquiteto, com %).
- Carga retroativa: tools/relatorios/gerar_backfill_marcos_arquitetura.py (120 dias: 4.456 oportunidades).
Comandos de implantacao, carga e permission set: scripts/52_marcos_arquitetura_e_relatorios_TMEP_TAP_SLA_2309.md.
Pendente: meta de SLA (Vilson) e decisao sobre apagar os 8 relatorios anteriores (sugestao: manter os dois de fila).
