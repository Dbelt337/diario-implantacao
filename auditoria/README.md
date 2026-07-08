# Auditoria do Modelo Organizacional — GrupoQ DevSales

Toolkit de auditoria **somente leitura** para o modelo organizacional da frente de
Vendas do GrupoQ na sandbox `grupoq--devsales` (Account hierarchy, BusinessProfile,
InternalOrganizationUnit, BranchUnit/ServiceTerritory, BusinessBrand e configuração de
suporte: CMT, GVS, campos de User).

## Por que este toolkit existe (e não o relatório final)

A auditoria exige acesso vivo, em somente leitura, à org `grupoq--devsales`. O ambiente
remoto onde este material foi preparado **não tem esse acesso**, o que impediu rodar as
queries e, portanto, produzir achados com evidência. Verificado em sessão:

| Pré-requisito | Estado | Evidência |
|---|---|---|
| Salesforce CLI (`sf`) | Ausente | nenhum binário `sf`/`sfdx` no host |
| Instalar CLI via npm | Bloqueado | `403 Forbidden` no registro npm (política de egresso) |
| Alcançar `*.salesforce.com` | Bloqueado | CONNECT 403 no gateway p/ `grupoq--devsales.sandbox.my.salesforce.com`, `login.salesforce.com`, `test.salesforce.com` |
| Autenticação armazenada | Ausente | sem `~/.sf`/`~/.sfdx`, sem `SFDX_AUTH_URL`/`SF_*` |

Fabricar achados contrariaria a regra central do roteiro ("evidência antes de afirmação").
Em vez disso, este pacote entrega tudo pronto para rodar contra a org e consolidar o relatório.

## Como executar

Pré-requisito: Salesforce CLI autenticada no alias `grupoq--devsales`.

```bash
# 1. Autenticar (se ainda não estiver)
sf org login web -a grupoq--devsales -r https://test.salesforce.com
sf org display -o grupoq--devsales          # deve retornar API version/usuário/instância

# 2. Coletar todas as evidências (Fases 0–8, somente leitura)
cd auditoria/scripts
./run_auditoria.sh                           # grava em ../evidencias/

# 3. Anti-join dealers sem BP (após confirmar o lookup BP->Account no describe)
#    Reexporte 04_todos_bp.csv incluindo a coluna de lookup e rode:
node diff_dealers_sem_bp.js <coluna_lookup>  # ex.: ParentId

# 4. Extrair valores do GVS retrieved para CSV (coluna 'value'), depois reconciliar
#    (veja "GVS -> CSV" abaixo)
node reconciliacao_sociedades.js             # gera ../evidencias/07_matriz_reconciliacao.csv
```

### GVS -> CSV

O `run_auditoria.sh` faz o retrieve do `GlobalValueSet:GVS_Sociedad`. Extraia os valores
ativos para `evidencias/gvs_valores.csv` com cabeçalho `value` (um `<fullName>` por linha
onde `isActive` = true) antes de rodar `reconciliacao_sociedades.js`. O arquivo XML fica em
`force-app/.../globalValueSets/GVS_Sociedad.globalValueSet-meta.xml` (ou em `evidencias/mdt_gvs/`).

## O que "descobrir" antes de confiar nas queries

Algumas queries estão marcadas `[AJUSTAR APOS DESCOBERTA]` no `run_auditoria.sh` porque
dependem de nomes que só a org confirma. Rode o describe, confirme o nome real e ajuste:

- **Discriminador de nível de Account** — Record Type, campo custom, ou profundidade de
  `ParentId`. As contagens de nível usam profundidade como fallback; se houver RT/campo de
  nível, prefira-o (mais preciso).
- **Lookup BusinessProfile → Account** — confirme em `describe_BusinessProfile.json` (ex.:
  `ParentId`/`AccountId`) e inclua na projeção de `04_todos_bp.csv` para o anti-join.
- **`Account.BrandName__c`** — confirme existência antes das queries de preenchimento.
- **Campos de `Sociedad_Config__mdt`** — confirme se o código de sociedade está em
  `DeveloperName` ou `MasterLabel` e ajuste `reconciliacao_sociedades.js`.

## Estrutura

```
auditoria/
├── README.md                          (este arquivo)
├── RELATORIO_MODELO_ORGANIZACIONAL.md (scaffold do relatório — Seção 7 do roteiro)
├── referencia/
│   └── sociedades_canonicas.csv       (17 sociedades canônicas + país + flag -PROV)
├── scripts/
│   ├── run_auditoria.sh               (orquestrador Fases 0–8, somente leitura)
│   ├── extrai_campos.js               (campos custom de Account/User dos describes)
│   ├── diff_dealers_sem_bp.js         (anti-join dealer ↔ BP local)
│   └── reconciliacao_sociedades.js    (matriz GVS x CMT x Accounts x canônica)
├── evidencias/                        (saída: CSV/JSON + _apendice_comandos.log)
└── ajustes/                           (artefatos de correção — NÃO EXECUTADOS)
```

## Garantias de segurança

- **Nenhum DML/deploy/alteração.** Só `sf data query`, `sf sobject describe`,
  `sf project retrieve start` (leitura de metadado) e `sf org display`.
- **Governor-friendly:** contagens via `COUNT()`/`GROUP BY`; exports linha a linha só onde
  são evidência de achado.
- **Rastreabilidade:** cada comando é registrado em `evidencias/_apendice_comandos.log`
  na ordem de execução (Apêndice do relatório).
