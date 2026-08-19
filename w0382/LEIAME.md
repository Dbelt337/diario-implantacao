# W0382 — pacote de ajustes

Gerado a partir do retrieve de produção. **Deployar em sandbox primeiro.**

## O que está no pacote

| Arquivo | Mudança |
|---|---|
| `flexipages/OpportunityRecordPageB2B.flexipage` | visibilidade do botão "Revisão Diretoria": fase `Viabilidade e desenho da solução` → `Validação técnica` |
| `flows/OpportunityStageApprovalProcess_B2B.flow` | regra `SendStage_AprovacaoTecnica_CLevel`: mesma troca de fase |
| `flows/OpportunitySendCLevelApproval_B2B.flow` | filtro `IsActive = true` na busca do aprovador + decisão `AprovadorEncontrado` + tela de erro `FailNoApproverScreen` |
| `objects/Opportunity.object` | 2 validation rules novas (uma inativa — ver abaixo) |
| `classes/ApprovalWorkItemsController.cls` | erro deixa de ser engolido; `LIMIT 200` |
| `classes/ApprovalWorkItemsControllerTest.cls` | assertions de verdade |

Os demais critérios do botão ficam intactos: `ArchitectureApproved__c = false`,
`ResponsibleTeam__c = Arquitetura`, esconder do vendedor, `Type ∈ {B2B, B2G}`.

## Ordem de deploy

1. `ApexClass` (classe + teste)
2. `CustomObject` (validation rules)
3. `Flow` — cria versão nova e ativa
4. `FlexiPage`

```bash
sf project deploy start --manifest package.xml --target-org <sandbox> --test-level RunSpecifiedTests --tests ApprovalWorkItemsControllerTest
```

## ⚠️ Uma VR vai INATIVA de propósito

`ObrigaTipoEmNegociacao` (Tipo obrigatório na fase 1) está com `active=false`.

Antes de ativar, rode e trate o resultado:

```sql
SELECT COUNT() FROM Opportunity
WHERE RecordTypeName__c = 'B2B' AND StageName = 'Em negociação' AND Type = null
```

Se houver Oportunidades abertas sem `Type`, ativar a regra trava todas elas
para os vendedores. Faça o backfill antes.

## Por que NÃO mexi em `canAssigneeEdit`

O requisito diz que o aprovador da diretoria não pode editar a Oportunidade.
A tentação é colocar `canAssigneeEdit=false` nos steps da orquestração — **e
isso quebraria o processo**: o C-Level recebe o MESMO work item por
reatribuição, então o atributo não distingue arquiteto de diretor, e o
arquiteto perderia o direito de alterar produtos, valores e quantidades, que a
própria work exige.

Por isso o bloqueio virou a validation rule `BloqueiaAlteracaoRevisaoDiretoria`,
que age sobre `ResponsibleTeam__c IN ('C-Level','Head')` e segue o padrão
`BloqueiaAlteracao*` já existente no objeto. `Bypass__c` continua sendo a
válvula de escape, como nas outras regras.

## O que NÃO está no pacote, e por quê

| Item | Por que ficou de fora |
|---|---|
| Aprovador da diretoria determinístico | hoje `GetDirectorUser` pega **um usuário qualquer** do papel — sem `LIMIT`, sem `IsActive`. A correção limpa é criar filas `C-Level` e `Head` e passar o Id da fila no `assigneeId` (a ação padrão aceita fila). Exige Setup + decisão de negócio. |
| Voltar ao arquiteto **do início** | a work pede o usuário específico; hoje volta para a fila `Arquitetura`. Exige campo novo + mudança na orquestração. |
| Papel `B2B_Head_B2G` | **não existe no org.** Precisa ser criado no Setup e receber o Head responsável. Sem isso, Head + B2G não tem para quem atribuir. |
| Desempate entre os 2 usuários de `B2B_Head_B2B` | precisa de definição: são intercambiáveis (então o certo é fila) ou há titular (então é ordenação/campo)? |
| Voltar ao arquiteto **do início** | a work pede o usuário específico; hoje volta para a fila `Arquitetura`. Exige campo novo + mudança na orquestração. |

## Já existia, não precisou mexer

- **Validação do nome `AVAL-FINANCEIRA_`**: o `FilterNameFile` filtra `FileUpload.fileNames` por `StartsWith 'AVAL-FINANCEIRA_'` e a decisão `FileAttached` barra quando a coleção fica vazia. Funciona.
- **Restrição `Type ∈ {B2B, B2G}`**: já está nos critérios de visibilidade do botão.
- **Botão escondido do vendedor**: critério `NOT($Permission.CustomPermission.SalesmanGR)`.

## Teste obrigatório em sandbox

O ponto mais frágil não é código, é comportamento de plataforma:

1. Oportunidade B2B/B2G em **Validação técnica** com `BackofficeForm__c = true`
2. Item de aprovação cai na fila `Arquitetura`; botão "Revisão Diretoria" aparece
3. Escalar para C-Level → conferir `ResponsibleTeam__c = C-Level` e o work item reatribuído
4. Tentar editar a Oportunidade → **deve bloquear** (VR nova)
5. C-Level **aprova** → conferir `ResponsibleTeam__c = Arquitetura` e se **nasce um item novo** para a fila Arquitetura
6. C-Level **reprova** → conferir volta para `Em negociação` e `ResponsibleTeam__c = Vendedor/GR`

### Testar também o caminho de erro

Com a decisão nova, selecionar **Head** numa Oportunidade `Type = B2G` deve
mostrar a tela de erro e **não** enviar nada — em vez de fingir sucesso, que é
o comportamento de hoje. Depois que o papel `B2B_Head_B2G` for criado, o mesmo
teste deve passar normalmente.

**O passo 5 é o risco real.** `UpdateApproved_AprovacaoTecnica_CLevel` só grava
`ResponsibleTeam__c = Arquitetura` e não mexe em `Send4Approval__c`. O
re-disparo da orquestração depende de ela reagir a essa atualização — que
acontece **dentro de um background step da própria orquestração em execução**.
Se o item novo não nascer, o processo trava aí e é preciso setar
`Send4Approval__c` explicitamente.

---

# Estado em 2026-08-19

## Deploy em sandbox: sucesso, MENOS a FlexiPage

`success: true`, 8 componentSuccesses: as 2 classes, `Opportunity.object`, as 2
validation rules, os 2 flows (versao nova criada em ambos) e o `package.xml`.

**A FlexiPage nao estava no pacote** -- o bloco foi removido do manifest depois
da falha em `Record.SDR__c`. A alteracao dela continua pendente.

Dois pontos do log que ficaram em aberto:

- `numTestsRun: 0`. O deploy rodou sem test level. As assertions novas do
  `ApprovalWorkItemsControllerTest` nunca foram exercitadas. Producao vai
  exigir os testes -- rodar avulso antes da janela.
- Aviso "Modo do sistema sem compartilhamento" no
  `OpportunitySendCLevelApproval_B2B`: `problemType: Info`, pre-existente,
  sem relacao com a W0382.

Falta confirmar no org: que `ObrigaTipoEmNegociacao` entrou **inativa** (o log
diz `created: true` mas nao diz o estado), e que a versao **ativa** dos dois
flows e a nova.

## FlexiPage: passo MANUAL, nao viaja com o pacote

Feita pelo Lightning App Builder, nao por deploy. Isso significa que ela tem de
ser **refeita a mao em producao** -- o deploy da pagina inteira continua batendo
no `Record.SDR__c`, que nao tem relacao com a W0382.

App Builder -> `OpportunityRecordPageB2B` -> componente do botao "Revisao
Diretoria" -> Definir visibilidade do componente -> linha do filtro
`Record > StageName` -> trocar para `Validacao tecnica`. Salvar; a pagina ja
esta ativada.

Conferir o valor exato da picklist (Setup -> Oportunidade -> Fase) antes de
salvar. O filtro compara string: acento ou caixa divergente faz o botao nunca
aparecer, sem erro em lugar nenhum. E a falha mais silenciosa da entrega.

Os outros criterios ficam intactos: `ArchitectureApproved__c = false`,
`ResponsibleTeam__c = Arquitetura`, `NOT($Permission.CustomPermission.SalesmanGR)`,
`Type IN (B2B, B2G)`.

## Papel B2B_Head_B2G

Aprovado por Priscila De Lima em 2026-08-19. Metadata em `roles/`, deploy por
`package.xml` desta pasta.

**Criar o papel nao conserta o B2G + Head.** O papel vazio nao muda nada: o
`GetDirectorUser` continua sem achar ninguem. O que conserta e **atribuir o
Head de B2G ao papel novo** -- e essa atribuicao tem efeito colateral em
producao:

> Um usuario tem UM papel. Atribuir o Head a `B2B_Head_B2G` o TIRA do papel
> atual. Papel e hierarquia de compartilhamento: ele perde visibilidade dos
> registros que enxergava pela posicao antiga, e o pai do papel novo passa a
> enxergar os dele.

A aprovacao registrada cobre "criar o papel". **Qual usuario sera atribuido e
de qual papel ele sai ainda precisa de confirmacao explicita.**

Antes do deploy, preencher `<parentRole>` e conferir os access levels contra o
papel irmao:

```bash
sf project retrieve start -m Role:B2B_Head_B2B -o <org>
```

Depois do deploy e da atribuicao, validar:

```sql
SELECT Id, Name, IsActive, UserRole.DeveloperName FROM User
WHERE UserRole.DeveloperName = 'B2B_Head_B2G'
```

Tem de voltar **exatamente um** usuario ativo. Zero = o DeveloperName nao bate.
Mais de um = acabamos de recriar o problema de desempate que ja existe em
`B2B_Head_B2B`, porque o `GetDirectorUser` pega um usuario qualquer, sem
`LIMIT` e sem `IsActive`.

Ordem: sandbox -> testar caminho B2G + Head -> producao. O caminho ja esta
quebrado em producao hoje, antes de qualquer mudanca desta entrega.

## FlexiPage: dois achados na tela de visibilidade (2026-08-19, sandbox Staging)

A visibilidade do botao e de ACAO (Painel de destaques > Acoes > Revisao
Diretoria > Definir visibilidade da acao), com 6 filtros:

```
1  Registro   > Fase                Igual  Validacao tecnica
2  Registro   > Aprovado Arquitetura Igual false
3  Registro   > Equipe responsavel  Igual  Arquitetura
4  Permissoes > Permissao personalizada > SalesmanGR  Igual  true
5  Registro   > Tipo                Igual  B2B
6  Registro   > Tipo                Igual  B2G
```

O filtro 1 ja esta com `Validacao tecnica` -- a alteracao da W0382 esta feita
na tela. Como o App Builder monta o valor a partir da picklist, o risco de
acento/caixa que estava anotado acima NAO se aplica neste caminho.

### 1. Filtros 5 e 6 nao podem estar sob AND

`Tipo Igual B2B` **E** `Tipo Igual B2G` e contradicao: Tipo tem um valor so.
Se "Mostrar componente quando" estiver em **Todos os filtros sao verdadeiros**,
o botao nunca aparece, em fase nenhuma, para ninguem -- e o sintoma e
indistinguivel de "a fase esta errada".

O requisito e `Type IN (B2B, B2G)`, ou seja OR entre 5 e 6. Exige logica de
filtro personalizada:

```
1 AND 2 AND 3 AND 4 AND (5 OR 6)
```

CONFERIR rolando a tela abaixo do "Mostrar componente quando". Se ja houver
logica personalizada configurada, verificar se o parenteses em torno de 5 OR 6
existe.

### 2. Filtro 4 esta invertido em relacao ao documentado

O LEIAME registra o criterio como `NOT($Permission.CustomPermission.SalesmanGR)`
-- esconder do vendedor. A tela mostra `SalesmanGR Igual true`, que MOSTRA ao
vendedor. Um dos dois esta errado.

Nao foi alterado por esta entrega; decidir qual e o comportamento correto antes
de salvar, porque salvar congela o que estiver na tela.
