# Sustentação B2B: hierarquia comercial do time do Rodrigo Piccolo (chamado via Samuel Vitor, 15-16/09/2026)

Pedido original (Tatiane Pompermaier, planejamento): "Gabriel sob gestão do Rodrigo Nascimento Piccolo", porque interfere nos relatórios de funil/forecast. Levantamento do Diego (15/09): na hierarquia de papéis o Gabriel já está abaixo do Rodrigo, como todo o time de Operadoras e Utilities; a divergência está no campo **Gerente da conta** (`Account.AccountManager__c`), usado nos relatórios: 6 contas com Wesley (3 Gabriel, 3 Tatiane), 27 em branco (Luan, Lucidia, Tamires, Tatiane), 13 oportunidades abertas com aprovador (`Opportunity.ManagerAccount__c`) diferente do Rodrigo, 6 delas do Gabriel travadas na aprovação de Arquitetura.

Decisão (Tatiane, 16/09, confirmada com o planejamento): contas passam para o Rodrigo como gerente, tanto as com Wesley quanto as em branco; **não mudar o dono da conta nem o dono da oportunidade** (são o gerente de relacionamento).

Execução: `scripts/29_GerenteConta_TimeRodrigo_1609.apex` (duas fases). Time = usuários ativos nos papéis abaixo do papel do Rodrigo (até 3 níveis). Contas: gerente Wesley ou em branco → Rodrigo. Oportunidades abertas do time com aprovador ≠ Rodrigo → Rodrigo (as travadas em aprovação falham na regra de validação e ficam para depois da aprovação ou para reatribuição pelo script 27). Owner nunca é tocado.

Contexto relacionado: o mesmo campo Gerente da Conta foi a causa do chamado da Tayza (SENAC, 15/09): o `ManagerAccount__c` da oportunidade é copiado na criação e define o aprovador da etapa comercial na orquestração `OpportunityApprovalSteps_B2B`.

## Fase 1 do script 29 (log de 16/09)

Time do Rodrigo (papéis "B2B Vendedor Alt e GGNet Operadoras / Utilities", "... - Terceiro" e "B2B Coordenador ... - Terceiro"): Bruno Tavares Jose, Gabriel Henrique De Freitas Feliciano, Luan Jair Geraldo, Lucas Teixeira Dos Santos, Lucidia Anzanello Ampessan, Tamires Moreira Antero, Tatiane Pompermaier (7). Números batem com o levantamento de 15/09: **33 contas** (6 com Wesley: TELEFONICA SP, TIM MS, TIM SC do Gabriel; FLIX FIBRA, QUALITYFIBRA, TELESPAZIO da Tatiane; 27 em branco: 9 Luan, 8 Lucidia, 9 Tamires, 1 Tatiane) e **13 oportunidades** abertas com aprovador ≠ Rodrigo: 6 do Gabriel (gerente Wesley) travadas na aprovação de Arquitetura (fase "Viabilidade e desenho da solução"); 4 do Luan (Ronimar Brugnerotto / Erich Hannes), 1 da Tamires (em branco), 2 da Tatiane (Wesley), todas destravadas. Fase 2 autorizada pela decisão da Tatiane; as 6 travadas devem falhar na regra de validação e serão tratadas quando chegarem à etapa comercial (reatribuição) ou após a aprovação.

## Fase 2 do script 29 (log de 16/09)

**Contas: 30 de 33 atualizadas.** As 3 que falharam continuam com Wesley; erro de regra de validação "seu usuário não está definido a um cluster" (depende do usuário que executa, não da conta). Depois: 235 contas do time com gerente Rodrigo, 3 com Wesley, 0 em branco.

**Oportunidades: 8 de 13 atualizadas** (as 6 do Gabriel travadas em Arquitetura entraram; 2 do Luan em "Aguardando instalação" entraram). 5 falharam por regra de validação de fase: FIREWALL - NOVOS SO GRUPO V ARAUCARIA (Luan, "Aguardando contrato": só a seção Informações pode ser editada), VIA CAMPO (Luan), SONDA DO BRASIL (Tamires), COTAÇÃO LINK TERRESTRE - COT CAMPINAS e COTAÇÃO TELESPAZIO 4 LINKS (Tatiane), todas "Análise cliente": "usuário não possui autorização para manipular o registro nesta fase". Nenhum dono alterado. O trigger de Opportunity criou 1 Task durante o update (a identificar, script 30).

Resíduo: 3 contas + 5 oportunidades. Script 30 (leitura) identifica os registros, os campos de cluster do usuário e a task criada; a solução passa pelo bypass das regras de validação (formulas a obter) ou pela execução por usuário autorizado.

## Script 30 (log de 16/09): resíduo identificado

- **3 contas pendentes**: TELESPAZIO BRASIL S/A, FLIX FIBRA LTDA, QUALITYFIBRA E MONITORAMENTO ELETRONICO LTDA (todas da Tatiane, RT "B2B - Pessoa jurídica", gerente Wesley). As 3 do Gabriel com Wesley entraram. Campo `User.Cluster__c` existe e está vazio tanto no Diego (Administrador do sistema) quanto no Rodrigo (perfil B2B - Gerência); a conta tem `Cluster__c` e `ClusterManual__c`. A regra "seu usuário não está definido a um cluster" disparou só nessas 3, então depende de algo da conta (provavelmente cluster em branco) combinado com o cluster do usuário.
- **5 oportunidades pendentes** (RT B2B): COTAÇÃO LINK TERRESTRE - COT CAMPINAS (006V200000lw281IAA) e COTAÇÃO TELESPAZIO 4 LINKS (006V200000gRYBuIAO), Tatiane, gerente Wesley; SONDA DO BRASIL (006V200000d9ULNIA2), Tamires, gerente vazio; VIA CAMPO (006V200000u8m41IAA), Luan, gerente Erich Hannes, todas em "Análise cliente"; FIREWALL - NOVOS SO GRUPO V ARAUCARIA (006V200000iJjw9IAC), Luan, gerente Erich Hannes, "Aguardando contrato".
- Nenhuma Task criada hoje pelo usuário executor: o insert visto no log da fase 2 pertencia ao trigger de uma oportunidade que falhou e foi desfeito junto.

Próximo passo depende das fórmulas das 3 regras de validação (Conta: cluster; Oportunidade: "não possui autorização nesta fase" e "Aguardando contrato").

## Regras de validação (texto enviado pelo Diego, 16/09)

- Conta: `AND(RecordTypeName__c = "B2B - Pessoa jurídica", ISPICKVAL($User.Cluster__c, ""), OR(ISPICKVAL(ClusterManual__c, ""), ISBLANK(TEXT(ClusterManual__c))))`. Explica o resíduo: as 3 contas da Tatiane estão sem ClusterManual e o executor (admin) não tem cluster; as do Gabriel tinham ClusterManual preenchido.
- Oportunidade `BloqueiaAlteracaoAnaliseCliente`: RT B2B, não nova, fase "Análise cliente", `Bypass__c = false` e `NOT(ISCHANGED(Bypass__c))`, salvo mudanças de fase/aprovação/data/valor. Ou seja, mudar `Bypass__c` no mesmo update libera a edição (mecanismo de bypass previsto na org). Oportunidade `BloqueiaAlteracaoAguardandoContrato`: RT B2B, fase "Aguardando contrato", `NOT(Bypass__c)` e `NOT(ISCHANGED(Bypass__c))`, salvo mudanças dos campos de contrato. Mesmo mecanismo de bypass.

Script 31 (duas fases): contas com cluster temporário no executor (copiado da Tatiane) e limpeza em seguida; oportunidades com `Bypass__c = true` junto com a troca e `false` logo depois. Não altera regra nenhuma nem donos.
