# W0382 — Botão "Revisão Diretoria" (aprovação C-Level) — dossiê de diagnóstico e checklist de produção

**Data:** 25/08/2026
**Ambiente do diagnóstico:** sandbox Staging (`preprod-brasiltecpar--staging`)
**Resultado:** botão funcionando em staging às ~15h de 25/08 (registro Teste Sr Vilson Parte 15, usuário admin).

## Componentes da solução (nomes confirmados via retrieve)

| Tipo | Nome | Observação |
|---|---|---|
| QuickAction | `Opportunity.ReassignCLevelApproval` | Label "Revisão Diretoria", type Flow — **não estava no manifest original** |
| Flow (screen) | `OpportunitySendCLevelApproval_B2B` | "[Oportunidade] Encaminhar para C-Level", v8 ativa |
| Flow | `OpportunityStageApprovalProcess_B2B` | referencia `ArchitectureApproved__c` |
| FlexiPage | `OpportunityRecordPageB2B` | visibilidade do botão no highlights panel |
| CustomField | `Opportunity.ArchitectureApproved__c` | checkbox "Aprovado Arquitetura", default false, history tracking |
| CustomPermission | `SalesmanGR` | concedida por: Administrativo / Validação B2B, Vendedor / GR B2B, B2B - Vendedor, B2B - Administrativo |
| ApexClass | `ApprovalWorkItemsController` (+Test) | lista de itens de trabalho de aprovação |

## Regra de visibilidade do botão (metadado real de staging)

```
booleanFilter: 1 AND 2 AND 3 AND NOT(4) AND (5 OR 6)
1. Record.StageName = 'Validação técnica'
2. Record.ArchitectureApproved__c = false
3. Record.ResponsibleTeam__c = 'Arquitetura'
4. $Permission.SalesmanGR = true        → NOT: só quem NÃO tem a permission vê
5. Record.Type = 'B2B'                  → (5 OR 6)
6. Record.Type = 'B2G'
```

Nota de método: a tela do App Builder lista os critérios sem exibir o `booleanFilter` — conclusões sobre lógica de visibilidade devem sair do metadado (retrieve), não do print da UI.

## Causa raiz do "botão sumido"

**Campo deployado sem field-level security.** `ArchitectureApproved__c` foi entregue via Metadata API sem FLS nos perfis → invisível para todos (FLS vale inclusive para admins). Consequências em cascata:
- SOQL retornava "No such column" e `FieldDefinition` vinha vazia (o campo existia; o usuário não tinha leitura);
- na visibilidade da página, `{!Record.ArchitectureApproved__c}` resolvia null → critério 2 nunca satisfeito → **botão oculto para todos**, com registro e demais critérios corretos;
- os ramos da visibilidade do botão "Anexar Arquivos" que usam o mesmo campo também estavam silenciosamente quebrados.

**Correção aplicada em staging:** FLS Visible para os perfis *B2B - Especialistas* e *System Administrator* (via Set Field-Level Security). Botão passou a aparecer imediatamente (hard refresh).

## Defeitos encontrados nos testes de 25/08 (todos corrigidos em staging)

| # | Sintoma | Causa raiz | Correção (pacote) |
|---|---|---|---|
| 1 | Botão invisível para todos | `ArchitectureApproved__c` deployado sem FLS | FLS por perfil (paliativo) → PS `FunilB2B_CamposAprovacao` (v5) |
| 2 | Submission "Errored" ao aprovar | Ramos `UpdateApproved_AprovacaoTecnica[_CLevel]` sem `Bypass__c=true` → validation rule derrubava o DML | `deploy-w0382-bypass-fix.zip` |
| 3 | Work item "Retirado" ~2 min após o clique no botão | Botão setava `Send4Approval__c=false` → registro deixava de atender ao gatilho da orquestração → plataforma retirava a submission | v3 do botão (remove só o `Send4Approval=false`; mantém `ResponsibleTeam` e `SolutionArchitect`) |
| 4 | Reprovação sem efeito na oportunidade | **Estágio "Send Approval - Arquitetura" nunca conclui**: tem 2 approval steps alternativos (fila × arquiteto nomeado); o que não se aplica fica `NotStarted` para sempre → o estágio 2 com o "Update record" nunca inicia. Provado via `FlowOrchestrationStepInstance` (step decidido `Completed` + irmão `NotStarted` + estágio `InProgress` + zero instâncias do estágio de update) | **v6**: `deploy-w0382-v6-orquestracao-update-no-estagio.zip` — os 2 background steps "Update record" movidos para DENTRO do estágio de aprovação, com entrada "quando `ApprovalStep_X.Status = Completed`"; estágio 2 morto removido |
| 5 | `UNABLE_TO_LOCK_RECORD` no estágio de envio + rejeição em item órfão sem efeito | Registros de teste reutilizados (Parte 14–19) presos com lock de submissions antigas (`shouldLock`); runs velhos em versão antiga do flow | Cancelar runs presos (Automation App → Orchestration Runs) ou `Approval.unlock(recordId)`; **testar sempre em registro novo** |
| 6 | Flow Builder acusa "field doesn't exist or you don't have access" (`BackofficeForm__c`, `ManagerAccount__r.Username`) ao abrir elementos do V7 | Mesma doença do item 1: campos deployados sem FLS; Builder valida com o acesso do usuário logado (runtime em system mode não é afetado, mas impede salvar nova versão pela UI) | v5 (PS de leitura dos 18 campos) atribuído a admins + personas |

**Achado crítico (25/08, noite):** Setup → Paused and Failed Flow Interviews em staging tinha **18 runs de `OpportunityApprovalSteps_B2B` pendurados no estágio "Send Approval - Arquitetura" desde 27/11/2025** (versões 2, 4, 5, 6 e 7) — o defeito estrutural existe desde a primeira versão, cada envio de aprovação da Arquitetura fica preso e segura trava de registro. Correção definitiva no **v7** (`deploy-w0382-v7-orquestracao-exit-conditions.zip`): condição de saída OR no estágio de aprovação (conclui quando qualquer approval step decide) + "Update record" de volta no estágio 2, que roda com a trava já liberada (padrão idêntico ao Comercial/Crédito). O v6 (update no mesmo estágio) morria em `UNABLE_TO_LOCK_RECORD` porque disparava 2s após a decisão com o `shouldLock` ainda ativo. **Em prod: auditar essa mesma lista, deletar os runs presos e destravar as oportunidades reais ANTES do go-live** — a lista de Paused é o indicador de saúde pós-deploy (ciclo completo não deve deixar resíduo).

Aviso recorrente do deploy (Info): **"Automated Process User has no valid email address"** — sem esse e-mail a orquestração não envia notificações de step (nem e-mails de erro chegam). Preencher em Setup → Process Automation Settings. Fazer o mesmo em prod.

## Checklist para produção (fazer TUDO, na ordem)

1. **Retrieve de conferência em prod** com o mesmo package (`deploy/w0382/package-retrieve-w0382.xml`) para verificar o estado real: campo existe? com FLS? QuickAction existe? qual versão da página?
2. **FLS do `ArchitectureApproved__c`** — preferencialmente via **permission set** "Funil B2B - Campos de aprovação" (leitura; edição fica com os flows em system mode) atribuído às personas do funil: Especialistas/arquitetura, Vendedor/SDR, Backoffice, Gerência. Em staging foi feito por perfil (Especialistas + SysAdmin) — replicar a decisão final, não o paliativo.
3. **Deploy do QuickAction** `Opportunity.ReassignCLevelApproval` (ausente no manifest original da W0382).
4. **Deploy da FlexiPage** `OpportunityRecordPageB2B` retrieveada **de staging** (versão validada). Pré-requisito: prod ter todos os campos que a página referencia (em staging o deploy já falhou por `SDR__c` — a página atual de staging não referencia mais SDR__c, conferido no retrieve; validar a versão final antes).
5. **Flows** (versões validadas em staging): `OpportunitySendCLevelApproval_B2B` (v3 do botão), `OpportunityStageApprovalProcess_B2B` (com Bypass nos 2 ramos), `OpportunityApprovalSteps_B2B` (v6 — update dentro do estágio). Conferir se chegam ativos.
5a. **Permission set `FunilB2B_CamposAprovacao`** (v5) no pacote + Manage Assignments para admins e personas do funil.
5b. **E-mail do Automated Process User** preenchido em Process Automation Settings.
5c. **Antes do go-live**: cancelar orchestration runs de teste pendentes e destravar registros com lock de aprovação (`Approval.unlock`); nunca validar em registro reutilizado/lockado.
6. **Teste em prod**: registro B2B/B2G em "Validação técnica", equipe Arquitetura, não aprovado; usuário SEM SalesmanGR vê o botão; usuário COM SalesmanGR não vê; Login As para validar as duas personas.
7. **Smoke test do "Anexar Arquivos"** nos ramos que dependem de `ArchitectureApproved__c` (a FLS nova muda o comportamento deles também).

## Pendência de negócio (decidir ANTES do deploy)

**Quem deve ver "Revisão Diretoria"?** A regra atual é `NOT(SalesmanGR)` — vendedores/GRs e o administrativo B2B (que também tem a permission) **nunca veem**; a Tayza, por exemplo, não vê (comportamento confirmado por design). Se arquitetura/backoffice deve clicar, substituir o critério 4 por uma custom permission positiva (ex.: `ArchitectureTeam`) atribuída ao PS da arquitetura. Regra por negação de permission alheia é frágil: quebra quando alguém recebe um permission set não relacionado.

## Lições registradas (padrões da org)

1. **Campo deployado via Metadata API nasce sem FLS** — todo deploy de `CustomField` deve levar junto as field permissions (permission set no pacote). Sintoma típico: "No such column" para campo que existe + componente/visibilidade que nunca satisfaz.
2. **Manifest de tela sem o QuickAction** — botão em highlights panel = FlexiPage (referência) + QuickAction (definição). Deployar só a página não cria o botão.
3. **Visibilidade tem `booleanFilter`** — auditar lógica pelo metadado.
4. Ambientes dessincronizados geram diagnóstico falso (campo `SDR__c` inexistente em staging derrubando deploy da página; perfil da Tayza diferente entre prod e staging). Retrieve comparativo antes de qualquer promoção.
