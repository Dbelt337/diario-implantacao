# Alteração do Gerente da conta (contas e oportunidades) — BrasilTecPar

Mesmo método de `tools/lead_load` e `tools/mg_load`: **primeiro consulta, depois atualiza pelo Id**. Nada é gravado a partir da planilha do comercial; cada linha precisa casar com exatamente um registro da org.

Campos: `Account.AccountManager__c` ("Gerente da conta") e `Opportunity.ManagerAccount__c` ("Gerente da Conta", aprovador da etapa "Aprovação - Comercial" na orquestração `OpportunityApprovalSteps_B2B`). **OwnerId nunca é alterado.**

> Planilhas do comercial, exports e saídas ficam fora do git (`.gitignore`).

## Arquivos

| Arquivo | O que é |
|---|---|
| `gerar_template_gerente.py` | Gera `Template_Alterar_Gerente_Conta.xlsx` (abas Contas, Oportunidades, Listas, Instrucoes). Com `--contas` e `--opps` despeja as planilhas do comercial no template. |
| `validar_gerente.py` | Cruza com a org e gera `A_contas_update.csv` e `A_opps_update.csv` (por Id), `B_retidos.csv`, `C_sem_mudanca.csv`. Não faz DML. |
| `scripts/37_AlterarGerente_Planilha_1609.apex` | Aplica os arquivos A na org em duas fases, tratando cluster, bypass e item de aprovação. |

## Fluxo

1. Despejar as planilhas no template (ou o comercial preenche o template direto):
   ```bash
   python3 gerar_template_gerente.py --contas Contas_Alterar_Gerente.xlsx --opps Oportunidade_para_Aprovacao.xlsx \
       --gerente "Marcelo Barbosa De Carvalho" --saida Alterar_Gerente_Marcelo.xlsx
   ```
2. Passada offline (formato) e geração das consultas:
   ```bash
   python3 validar_gerente.py --arquivo Alterar_Gerente_Marcelo.xlsx --out saida/
   ```
3. Exportar da org as 3 consultas de `saida/consultas.soql` (`sf data query -o <org> --json -q "..." > accounts.json`, idem `opps.json` e `users.json`).
4. Passada online:
   ```bash
   python3 validar_gerente.py --arquivo Alterar_Gerente_Marcelo.xlsx --accounts accounts.json --opps opps.json --users users.json --out saida/
   ```
   Ler `relatorio.txt` e `B_retidos.csv` antes de seguir. Linhas retidas voltam para o comercial.
5. Subir `A_contas_update.csv` e `A_opps_update.csv` como arquivos na org e rodar o script 37: `EXECUTAR = false` (lista), conferir, `EXECUTAR = true` (grava), janelas de 500 contas.
6. Conferir o "DEPOIS" no log e registrar no diário.

## O que segura uma linha

- Conta: CNPJ sem registro, mais de um registro, nome divergente, CPF, gerente sem match/inativo/ambíguo.
- Oportunidade: conta + nome não encontrados entre as abertas, ou mais de uma com o mesmo nome na mesma conta.
- Já está com o gerente alvo: arquivo C, não é reenviada.

## Regras da org que o script 37 respeita (aprendidas nos chamados de 15 e 16/09)

- Conta B2B PJ sem `ClusterManual__c`: regra `$User.Cluster__c` vazio bloqueia; cluster temporário no executor, limpo ao final (script 31).
- Oportunidade em "Análise cliente" ou "Aguardando contrato": `Bypass__c = true` no mesmo update (o trigger devolve false).
- Oportunidade em aprovação: o campo não aceita edição nem com unlock (regra "não é possível editar enquanto em aprovação", 15/09). O script reatribui o item pendente "Aprovação - Comercial" ao novo gerente; o campo é ajustado após a aprovação. O item espelho `ApprovalWorkItem` não é editável pela API (esperado).
