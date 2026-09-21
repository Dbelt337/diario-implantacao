# 21/09/2026 - Preparacao do teste da Revisao Diretoria na preprod (staging), 22/09

Base: analise em docs/2026-09-21-aprovacao-clevel-analise.md. Org: btp-staging (preprod-brasiltecpar--staging).
Versoes ativas na staging: Encaminhar para C-Level v9, processo de fases v22, orquestracao v9 (25/08). Botao "Revisao
Diretoria" aparece so na fase Validacao tecnica.

## Feito em 21/09 a noite

- Pacote `org/clevel-v2/` (formato metadata): flow Encaminhar para C-Level = staging v9 + decisao **"Item de aprovacao
  encontrado?"** com tela propria "nao ha item pendente na fila Arquitetura (ou com voce)". Sem isso, o caso "item ja
  assumido por um arquiteto" termina em erro generico de flow. Validado com check-only na staging (0 erros). Deploy real
  bloqueado pelo modo automatico: comando abaixo.
- Tres oportunidades de teste em Validacao tecnica, com item "Aprovacao - Arquitetura" pendente na fila, receberam
  Tipo = B2B (estavam sem tipo): Test 20-02-26, Test 18-02-26, CHOCOLATES GAROTO (006HZ00000OM4K5YAL).

## Falta o Diego rodar (2 comandos)

```
cd org
sf project deploy start -o btp-staging --metadata-dir clevel-v2
sf data update record --sobject User --record-id 005HZ00000HBDmsYAH --values "IsActive=true UserRoleId='<Id do papel B2B_Head_B2B>'" -o btp-staging
```
O Id do papel: `SELECT Id FROM UserRole WHERE DeveloperName = 'B2B_Head_B2B'` na staging. Paul Nabih Raad e o Head B2B da
prod; na staging esta inativo com papel B2B_GeneralDirector. Sem um Head ativo, o caminho "Head" so serve para o caso de
falha. Alternativa sem ativar ninguem: dar o papel B2B_Head_B2B a um usuario ativo (Davi ou Gerson).

## Usuarios para o teste

| Papel no teste | Usuario na staging | Situacao |
|---|---|---|
| Quem aciona o botao | Diego (sysadmin) ou Priscila de Lima (B2B - Especialistas, papel BackofficeArchitect) | ativos |
| C-Level aprovador | Alex Patrik da Silva (Admin Acesso) ou Priscila Lima (sysadmin): o flow pega o **primeiro** ativo do papel CLevel, nao da para escolher | ativos; para decidir, logar como o que recebeu o item ("Login as" pelo Setup) |
| Head B2B | Paul Nabih Raad (depois de ativar) | inativo hoje |
| Arquiteto que assume item (caso 5) | Tayza Apollo ja tem 2 itens; ou Priscila de Lima reatribui um item para si | - |

## Oportunidades por caso (todas B2B, Validacao tecnica, item pendente na fila Arquitetura)

| Caso | Oportunidade | Por que |
|---|---|---|
| 1 Diretor encontrado (C-Level) | Teste Sr Vilson Parte 15 (006HZ00000TEmwyYAD, item 00000253) | Tipo B2B, equipe Arquitetura, Send4Approval e BackofficeForm marcados |
| 1b Diretor encontrado (Head) | Test 20-02-26 (006HZ00000OkiTJYAZ, item 00000117) | Tipo B2B (ajustado hoje); precisa do Paul ativo |
| 2 Sem papel (Head com Tipo vazio) | CALOI/Test downgrade 10-03 - 1 (006HZ00000PAaqGYAT, item 00000159) | Tipo vazio -> papel B2B_Head_ nao existe -> tela "nao foi encontrado aprovador" |
| 3 Sem usuario ativo no papel | qualquer B2B com Head, ANTES de ativar o Paul | tela de falha |
| 4 Anexo com nome errado | qualquer uma | arquivo apagado, volta ao upload |
| 5 Item ja com pessoa | Demonstracao - 30/06/26 (006HZ00000RoZ80YAF, item 00000221 com Tayza Apollo) | com o pacote novo: tela "nao ha item pendente"; sem ele: erro generico |
| 6 Item com o proprio usuario | reatribuir o item 00000114 (Test 18-02-26, 006HZ00000OhEwMYAV) para quem vai acionar | v9 aceita |
| 7 Aprovacao do diretor | a do caso 1, logado como o C-Level que recebeu | ResponsibleTeam = Arquitetura, Bypass, Send4Approval = true, nova submissao, notificacao |
| 8 Rejeicao do diretor | CHOCOLATES GAROTO (006HZ00000OM4K5YAL, item 00000104), C-Level, rejeitar | fase Em negociacao, equipe Vendedor/GR |
| 9 Fase trocada no meio | Test Cortesia/Cancelamento (Send4Approval false) nao servem; usar Parte 14 (006HZ00000SmUy9YAF) se houver item | conferir caminho padrao |
| 10 Componente Itens de aprovacao | as dos casos 1, 7 e 8 | tabela e botao atualizar |

Ja em revisao C-Level na staging (nao usar como "novo envio"): Teste Sr Vilson Parte 16 a 20. Servem para o caso 7/8 se o
item ainda estiver com o diretor: conferir em Itens de aprovacao.

## O que conferir antes de comecar

1. `sf org display -o btp-staging` conectado; versao ativa do Encaminhar = 10 depois do deploy.
2. Setup > Login Access Policies: "Administrators Can Log in as Any User" ligado, para decidir como o diretor.
3. Notificacao custom (sino) chega ao dono/gerente da conta: a oportunidade de teste precisa de dono ativo.
4. Arquivo de teste `AVAL-FINANCEIRA_teste.pdf` e um `proposta.pdf` para o caso 4.
