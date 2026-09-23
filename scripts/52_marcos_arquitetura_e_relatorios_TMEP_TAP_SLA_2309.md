# 52 - Marcos da fila de Arquitetura e relatorios TMEP, TAP e SLA de entregas (23/09/2026)

Pacote validado na staging (0AfHZ00000QQUQ50AP) e na producao em modo check-only (0AfV2000000uMInKAM, 10 componentes,
0 erros). Nada implantado ainda. Rodar na raiz do repo, na ordem.

## 1. Implantar na producao (quick deploy da validacao ja feita; vale por 10 dias)

```
cd org
sf project deploy quick --job-id 0AfV2000000uMInKAM --target-org btp-prod --wait 15
cd ..
```

Se o quick deploy expirar ou falhar, implantar direto (sem Apex no pacote, a producao aceita sem testes):

```
cd org
sf project deploy start --source-dir force-app/main/default/objects/Opportunity/fields/ArchViabilityConcludedAt__c.field-meta.xml force-app/main/default/objects/Opportunity/fields/ArchTechValidConcludedAt__c.field-meta.xml force-app/main/default/objects/Opportunity/fields/Architect__c.field-meta.xml force-app/main/default/objects/Opportunity/fields/ArchViabilityDays__c.field-meta.xml force-app/main/default/objects/Opportunity/fields/ArchTechValidDays__c.field-meta.xml force-app/main/default/flows/OpportunityArchitectureMilestones_B2B.flow-meta.xml force-app/main/default/permissionsets/Arquitetura_Marcos_Leitura.permissionset-meta.xml force-app/main/default/reports/Performance_Arquitetura/Arq_TMEP_Tempo_Medio_Elaboracao_Projeto.report-meta.xml force-app/main/default/reports/Performance_Arquitetura/Arq_TAP_Taxa_Aprovacao_Projetos.report-meta.xml force-app/main/default/reports/Performance_Arquitetura/Arq_SLA_Entregas.report-meta.xml --target-org btp-prod --wait 15
cd ..
```

## 2. Carga retroativa dos marcos (120 dias: 4.456 oportunidades, 3.271 conclusoes em Viabilidade e 2.085 em Validacao tecnica)

O CSV ja esta gerado em `org/tmp/arquitetura_marcos/backfill_marcos_arquitetura.csv`. Para regerar com dados do dia:

```
C:\Users\DIego\AppData\Local\Programs\Python\Python312\python.exe tools\relatorios\gerar_backfill_marcos_arquitetura.py --dias 120
sf data update bulk --sobject Opportunity --file org/tmp/arquitetura_marcos/backfill_marcos_arquitetura.csv --target-org btp-prod --wait 10
```

Atencao: o update dispara as automacoes da Oportunidade. O flow novo so reage a mudanca em Send4Approval__c, que a carga
nao toca. Se houver receio com outros flows, rodar primeiro um lote de 5 linhas (copiar o cabecalho e 5 linhas para outro
arquivo) e conferir na org.

## 3. Permission set de leitura dos campos (17 arquitetos + Vilson, Priscila, Gerson, Diego)

```
sf org assign permset --name Arquitetura_Marcos_Leitura --target-org btp-prod --on-behalf-of alexmaass@brasiltecpar.com.br andrevicente@brasiltecpar.com.br claytonmogami@avato.com.br diegomoraes.t@brasiltecpar.com.br franklinlima.t@brasiltecpar.com.br gersonpereira.t@brasiltecpar.com.br gilmarbatista@brasiltecpar.com.br jefersonmanfio@brasiltecpar.com.br joaooliveira@avato.com.br luisoliveira@brasiltecpar.com.br marceloribeiro.t@brasiltecpar.com.br matheusbarbosa@brasiltecpar.com.br matheusresende@brasiltecpar.com.br paulodavet@brasiltecpar.com.br paulosmith@avato.com.br pedrojacques@brasiltecpar.com.br priscilalima.t@brasiltecpar.com.br priscilaschafhauzer@brasiltecpar.com.br vilsonhopf@brasiltecpar.com.br viniciuscamboim@avato.com.br willianssantos@brasiltecpar.com.br
```

## 4. Conferir

Abrir os tres relatorios na pasta Performance Arquitetura: "Arq - TMEP: tempo de elaboracao", "Arq - TAP: taxa de aprovacao
de projetos" e "Arq - SLA de entregas". Depois da carga retroativa eles ja mostram 90 dias. O SLA esta com meta de 5 dias no
bucket "SLA de entrega": ajustar no proprio relatorio quando o Vilson definir o numero.

## 5. Apagar os relatorios antigos (quando o Vilson confirmar)

Exclusao e acao de producao: fazer pela interface (pasta Performance Arquitetura, menu de cada relatorio) ou por
`sf project deploy start --metadata-dir` com destructiveChanges. Os 8 antigos: Fila pendente por idade, Fila pendente por
arquiteto, Opps aguardando (abertas), Validacoes por arquiteto, Volume mensal, Viabilidade: dias por arquiteto,
Viabilidade: saidas por destino, Validacao tecnica: dias por mes. Sugestao: manter os dois de fila (pendente por idade e
por arquiteto), que respondem "o que esta na fila hoje" e nao tem substituto nos tres novos.
