# Status dos relatórios de Performance de Arquitetura - 23/09/2026

Programa Salesforce Brasil Tecpar. Pasta "Performance Arquitetura" na org de produção, compartilhada com Vilson de Moura Hopf Junior. Os números abaixo são da execução dos relatórios em 23/09/2026.

Pasta: https://prod-brasiltecpar.my.salesforce.com/lightning/r/Folder/00lV2000009ZdSkIAK/view

## Relatórios entregues

| Relatório | O que responde | Leitura em 23/09/2026 | Link |
|---|---|---|---|
| Arquitetura - Fila pendente por idade | Itens de aprovação de arquitetura pendentes, por semana de entrada, com quem assumiu e a idade em dias, do mais antigo ao mais novo. | 248 itens pendentes; idade média 10,4 dias; item mais antigo com 77,9 dias (era 200,8 antes da limpeza). | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009cR6rMAE/view |
| Arq - Fila pendente por arquiteto | Os mesmos itens pendentes agrupados pelo arquiteto que assumiu; sem nome significa que ainda está na fila, sem dono. | 225 itens sem dono; Paul Nabih Raad 21; Gilmar Balbinot 2. | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009dQn6MAE/view |
| Arquitetura - Opps aguardando (abertas) | Oportunidades B2B abertas aguardando arquitetura, apenas nas fases Viabilidade e desenho da solução e Validação técnica, com dias na fase atual. | 249 oportunidades: 231 em Viabilidade e desenho da solução (média 10,9 dias) e 18 em Validação técnica (média 3,8 dias). | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009cqy5MAA/view |
| Arquitetura - Validações por arquiteto | Itens concluídos nos últimos 30 dias por arquiteto, só os 17 nomes da lista e só passos concluídos de verdade: quantidade, horas e dias (soma, média e máximo). | 1.267 validações concluídas em 30 dias por 15 arquitetos; tempo médio de 117 horas (4,9 dias) entre entrada e conclusão. | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009cR6sMAE/view |
| Arquitetura - Volume mensal | Matriz arquiteto x mês de conclusão dos últimos 90 dias, com a mesma lista de 17 arquitetos. | 3.938 validações concluídas em 90 dias; média de 108,7 horas por item. | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009cR6tMAE/view |
| Arq - Viabilidade: dias por arquiteto | Tempo de cada oportunidade na fase Viabilidade e desenho da solução (90 dias), por quem encerrou a fase. | 1.816 saídas da fase em 90 dias; média de 7,1 dias na fase; máximo 213 dias. | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009dQn5MAE/view |
| Arq - Viabilidade: saídas por destino | Para onde a oportunidade foi ao sair de Viabilidade: Análise cliente (aprovada, segue para proposta) ou Em negociação (devolvida ao vendedor), com a taxa de cada destino. | Taxa de aprovação de 86,3% (1.567 seguiram para proposta) e 13,7% devolvidas (249). | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009dQn4MAE/view |
| Arq - Validação técnica: dias por mês | Tempo de cada oportunidade na fase Validação técnica, por mês de saída, 90 dias. | 1.225 saídas em 90 dias; média de 1,3 dia na fase; setembro com 269 saídas e média de 1,35 dia. | https://prod-brasiltecpar.my.salesforce.com/lightning/r/Report/00OV2000009dQn3MAE/view |

## Requisitos solicitados e situação

| Requisito | Situação | Onde está atendido |
|---|---|---|
| Fila geral: responsável por item e há quanto tempo está na fila | Atendido | Fila pendente por idade |
| Detalhe por arquiteto: quem está com o quê e há quanto tempo | Atendido | Fila pendente por arquiteto |
| Fórmulas de tempo revisadas (entrada até conclusão) e coerência entre média, máximo e quantidade | Atendido | Validações por arquiteto |
| Tempo médio de atendimento por profissional | Atendido | Validações por arquiteto |
| Tempo total na fila de arquitetura e tempo de elaboração do desenho no setor | Atendido | Viabilidade: dias por arquiteto; Validação técnica: dias por mês |
| Volume atendido no mês e visão de 90 dias | Atendido | Volume mensal |
| Filtro pela lista de 17 arquitetos, incluindo Jeferson Manfio | Atendido | Validações por arquiteto; Volume mensal |
| Taxa de conversão: desenhos que avançam para proposta | Atendido | Viabilidade: saídas por destino |
| Oportunidades aguardando arquitetura só nas fases técnicas (sem Em negociação) | Atendido | Opps aguardando (abertas) |
| Limpeza de itens fora do fluxo | Atendido | 47 oportunidades fechadas limpas em 18/09; item de 191 dias (Em negociação) cancelado em 21/09; idade máxima da fila caiu de 200,8 para 77,9 dias |
| Acesso da liderança aos relatórios | Atendido | Pasta Performance Arquitetura compartilhada com Vilson de Moura Hopf Junior (acesso de edição) |
| Duas versões por fase nos relatórios de itens (Viabilidade x Validação técnica) | Parcial, decisão pendente | Nos relatórios de histórico de oportunidade a fase já é separada. Nos itens de aprovação a plataforma usa o mesmo passo nas duas fases e o item não guarda a fase; a alternativa é um campo na oportunidade preenchido pela automação, a combinar |
| Expurgar da Validação técnica o tempo de espera de terceiros (BKO, vendedor, cliente) | Parcial, decisão pendente | Fases próprias (aprovação comercial, crédito, análise cliente) já ficam fora. A espera do formulário do BKO dentro da mesma fase exige uma fase "Pendente BKO" ou um campo de data preenchido pela automação; decisão da Priscila |

## Práticas e decisões que dependem da área

- Assumir o item ao começar a análise: hoje 225 dos 248 itens pendentes estão sem dono, e a visão por arquiteto só fica completa com essa prática combinada em 18/09.
- Manter a fila limpa de forma permanente: a limpeza feita até aqui foi por rotina manual; o próximo passo é a automação que cancela o item quando a oportunidade sai das fases técnicas ou fecha, a construir e testar em sandbox antes de ir para produção.
- Definir a meta de SLA por fase para a fila (proposta em aberto com a Priscila), o que permite destacar no relatório os itens fora do prazo.

Documentação técnica dos relatórios e das decisões no repositório do programa (docs/2026-09-18-relatorios-arquitetura-v2-plano.md).
