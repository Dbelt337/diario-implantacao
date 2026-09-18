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
