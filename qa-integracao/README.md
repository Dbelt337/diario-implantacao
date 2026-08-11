# QA de Integração + Incidente de Segurança — Artefatos de execução

Handoff de 11/08/2026 (Diego Beltrão). Este diretório versiona os artefatos do
backlog A–H. Execução nas orgs é manual (sf CLI / Setup / Anonymous Apex),
seguindo as regras da casa: auditar antes de criar, describe antes de DML,
DRY_RUN antes de qualquer DML, PROD somente com Diego presente, sem emojis.

Org QA: `qabrasiltecpar--qa` · usuário `diegomoraes.t@brasiltecpar.com.br.qa`.

## Quadro de status do backlog

| Item | Descrição | Artefato neste diretório | Status |
|---|---|---|---|
| A | Verificar último teste do composite (Ticket 67890) | `scripts/a_verificar_ultimo_teste.soql` + `scripts/composite_teste_encadeado.apex` | Pronto para executar (primeira ação) |
| B | Reverter privilégio do svc_sales_integracao | `scripts/b_reverter_privilegios_svc_user.apex` (DRY_RUN) + `metadata/permissionsets/Integracao_Field_Service.permissionset` | Pronto; B.3 aguarda decisão do Diego (licenças FS) |
| C | Drift do IntegrationLog__c (Status__c/TargetSystem__c) | `scripts/c_auditar_campos_origem.soql` + `metadata/objects/IntegrationLog__c.object` | Metadata pronta com defaults; CONFIRMAR tipos na org de origem antes do deploy (regra 1) |
| D | Remediação de segurança do IntegrationLog | `scripts/d_remediacao_integrationlog.apex` (DRY_RUN) | Pronto para DRY_RUN; execução após aprovação |
| E | PROD — incidente Mullvad | `runbooks/e_prod_incidente_seguranca.md` | Aguarda janela com Diego |
| F | MuleAuth + Named Credential do QA | `runbooks/f_muleauth_named_credential_qa.md` | Aguarda insumo do Victor (canal seguro) |
| G | Pendências do Victor | seção no runbook F | Acompanhar |
| H | Runbook pós-refresh de sandbox | `runbooks/h_runbook_pos_refresh_sandbox.md` | Rascunho consolidado |

## Comandos de execução

```bash
# Item A — verificar o resultado do último teste
sf data query -o qabrasiltecpar--qa --file qa-integracao/scripts/a_verificar_ultimo_teste.soql

# Reexecutar o composite de teste, se necessário
sf apex run -o qabrasiltecpar--qa --file qa-integracao/scripts/composite_teste_encadeado.apex

# Item B — reverter privilégios (rodar 1x com DRY_RUN=true, revisar debug, depois false)
sf apex run -o qabrasiltecpar--qa --file qa-integracao/scripts/b_reverter_privilegios_svc_user.apex

# Item C — deploy dos campos + permission set (APOS confirmar tipos na origem)
sf project deploy start -o qabrasiltecpar--qa --metadata-dir qa-integracao/metadata

# Item D — remediação (mesmo protocolo DRY_RUN do item B)
sf apex run -o qabrasiltecpar--qa --file qa-integracao/scripts/d_remediacao_integrationlog.apex
```

## Avisos e níveis de certeza

- (A) `client_secret` do app `troubleTicket-app` foi exposto em chat pelo Victor
  em 11/08 (junto com curl de teste). Rotacionar no Keycloak-HML e reenviar por
  canal seguro. Registrado como entrada adicional do dossiê (ver runbook E/D).
- (B) O deploy do PS `Integracao_Field_Service` pode falhar na atribuição se a
  licença "Salesforce Integration" do usuário não cobrir WorkOrder /
  ServiceAppointment — é exatamente a decisão pendente do item B.3 (quais dos 5
  PS/licenças de Field Service precisam permanecer). Testar a atribuição em
  DRY_RUN e levar o resultado ao Diego.
- (C) Tipos dos campos `Status__c`/`TargetSystem__c` no `.object` são defaults
  razoáveis (picklist / texto 50) baseados no payload observado; a regra da casa
  exige confirmar com a query `c_auditar_campos_origem.soql` na org de origem
  antes do deploy e ajustar o XML se divergirem.
