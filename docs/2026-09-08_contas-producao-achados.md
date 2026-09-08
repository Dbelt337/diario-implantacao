# Contas em produção — achados de 08/09/2026 (continuação após queda da sessão)

Complementa a nota "CENARIO REAL DA ORG DE PRODUCAO (08/09)" gravada na W-000117 pelo script 09.

## Validação dos scripts
- Script 09: 2 notas gravadas (W-000117 e W-000103), sem exceção.
- Script 04 v7: `79 OK, 0 FALTANDO, 0 DUPLICADOS`.

## Hierarquia via ParentId (não é usada)
| Record type | Contas | Com ParentId |
|---|---|---|
| B2B - Pessoa jurídica | 54.485 | 0 |
| Pessoa Física | 53.061 | 0 |
| Pessoa Jurídica | 2.089 | 0 |
| Billing | 1.938 | 0 |
| (sem record type) | 4 | 2 |

Impacto: a RN-01 ("Billing e Service são filhas do cliente via ParentId") e o Cenário E
("toda conta Billing tem ParentId") descrevem um estado que não existe hoje. O vínculo
Billing -> cliente, se existir, está em outro campo (candidatos: `vlocity_cmt__RootAccountId__c`,
`EconomicGroup__c`) ou só nas linhas de pedido (`OrderItem.vlocity_cmt__BillingAccountId__c`).

## Contas por record type e ano de criação
| Record type | 2025 | 2026 |
|---|---|---|
| B2B - Pessoa jurídica | 49.818 | 4.667 |
| Pessoa Física | 41 | 53.020 |
| Pessoa Jurídica | 0 | 2.089 |
| Billing | 0 | 1.938 |
| (sem record type) | 4 | 0 |

Leitura: "B2B - Pessoa jurídica" é a base carregada em 2025 e ainda alimentada; "Pessoa Física",
"Pessoa Jurídica" e "Billing" nasceram todas em 2026, ou seja, são a operação corrente, não legado.
Isso inverte a hipótese do item (d) da nota (que tratava "Pessoa Jurídica" como legado).

## Quem cria as contas Billing (todas de 2026)
| Criador | Contas |
|---|---|
| Integracao Ordem Manual + "Integraçao Ordem Manual" (2 usuários) | 1.482 (76%) |
| Usuario Teste | 112 |
| Vendedores/BKO (19 pessoas) | 344 |

Pontos: o usuário de integração existe em duplicidade (com e sem cedilha); há 112 contas de
teste em produção; nenhuma Billing tem ParentId.

## Lookups de Account para Account existentes
`ParentId`, `MasterRecordId` (merge), `vlocity_cmt__RootAccountId__c` (Root Account).
Outros lookups relevantes: `vlocity_cmt__PartyId__c`, `vlocity_cmt__PremisesId__c`,
`vlocity_cmt__PrimaryContactId__c`, `vlocity_cmt__PersonContactId__c`, `EconomicGroup__c`.
Não existe lookup customizado "conta pagadora"/"conta principal" fora do pacote.

## Pendências para fechar a CAT-ACC-01
1. Descobrir como a Billing aponta para o cliente hoje (RootAccount? EconomicGroup? só via pedido?).
2. Explicar a diferença entre os dois record types de PJ pelos criadores/ano.
3. Identificar o External ID usado pela integração "Ordem Manual" nas Billing.
4. Registrar na W-000117 (script 11) o ajuste da RN-01/Cenário E com o campo de vínculo real.

## Person Accounts (Setup > Person Accounts, produção, 08/09)
Não habilitados. Readiness com 3 de 4 passos concluídos:
- Org Impact Acknowledgement: pendente (único passo que falta; o botão "Enable Person Accounts" fica cinza por causa dele).
- Create Accounts Record Type: ok (já existe record type de conta business).
- Set Read Permissions: ok.
- Set Organization-Wide Sharing: ok (Contact = Controlled By Parent, pré-requisito que costuma ser o bloqueio real).

Leitura: a habilitação é viável tecnicamente e não depende de projeto de preparação; a barreira é só
a decisão de negócio e a conversão dos 53 mil "Pessoa Física" (irreversível, um Contact por conta,
janela). Mantém a recomendação BTP da nota: opção (ii) na Onda 1 ("Pessoa Física" como Consumer,
Contact titular obrigatório, CPF único), reavaliar após go-live. NÃO clicar em "Enable Person Accounts"
sem decisão registrada com SysMap e Joel.
