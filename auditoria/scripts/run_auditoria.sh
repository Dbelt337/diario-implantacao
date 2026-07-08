#!/usr/bin/env bash
# =============================================================================
# Auditoria do Modelo Organizacional - GrupoQ DevSales
# Coletor de evidencia SOMENTE LEITURA. Nenhum DML, deploy ou alteracao.
#
# Uso:
#   cd auditoria/scripts && ./run_auditoria.sh
#
# Requisitos: Salesforce CLI (`sf`) autenticada no alias grupoq--devsales.
# Saidas: ../evidencias/*.csv|*.json  e  ../evidencias/_apendice_comandos.log
#
# Este script NAO altera a org. Cada bloco corresponde a uma fase do roteiro.
# Onde o roteiro exige "descobrir" um discriminador/lookup, o script primeiro
# faz o describe e depois roda a query; passos que dependem de um nome de campo
# ainda nao confirmado ficam marcados com [AJUSTAR APOS DESCOBERTA].
# =============================================================================
set -uo pipefail

ORG="grupoq--devsales"
EV="../evidencias"
LOG="$EV/_apendice_comandos.log"
mkdir -p "$EV"
: > "$LOG"

# ---- helpers ----------------------------------------------------------------
ts()   { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
note() { echo -e "\n### $* ###" | tee -a "$LOG"; }

# runs a labeled command, echoing it to the appendix log, tolerating failure
run() {
  local desc="$1"; shift
  echo -e "\n[$(ts)] $desc\n\$ $*" >> "$LOG"
  "$@" >> "$LOG" 2>&1
  local rc=$?
  echo "[exit $rc]" >> "$LOG"
  return $rc
}

# SOQL -> CSV evidence file
soql_csv() {
  local file="$1"; local q="$2"
  echo -e "\n[$(ts)] SOQL -> $file\n\$ sf data query -o $ORG -q \"$q\"" >> "$LOG"
  sf data query -o "$ORG" -q "$q" -r csv > "$EV/$file" 2>>"$LOG"
  local rc=$?
  echo "[exit $rc] linhas: $(wc -l < "$EV/$file" 2>/dev/null || echo 0)" >> "$LOG"
  echo "  -> $file (exit $rc)"
  return $rc
}

# object describe -> JSON evidence file (also flags presence/access)
describe() {
  local sobj="$1"
  echo -e "\n[$(ts)] DESCRIBE $sobj\n\$ sf sobject describe -o $ORG -s $sobj" >> "$LOG"
  if sf sobject describe -o "$ORG" -s "$sobj" --json > "$EV/describe_${sobj}.json" 2>>"$LOG"; then
    echo "  -> describe_${sobj}.json (OK)"
    echo "$sobj,PRESENTE" >> "$EV/_objetos_presenca.csv"
  else
    echo "  -> $sobj AUSENTE OU SEM ACESSO (ACHADO)"
    echo "$sobj,AUSENTE_OU_SEM_ACESSO" >> "$EV/_objetos_presenca.csv"
  fi
}

echo "Auditoria iniciada em $(ts) contra org '$ORG'" | tee -a "$LOG"

# =============================================================================
note "FASE 0 - Preparacao e autenticacao"
# =============================================================================
if ! sf org display -o "$ORG" --json > "$EV/00_org_display.json" 2>>"$LOG"; then
  echo "FALHA DE AUTENTICACAO. Rode: sf org login web -a $ORG -r https://test.salesforce.com" | tee -a "$LOG"
  echo "Abortando: sem org autenticada nao ha auditoria." | tee -a "$LOG"
  exit 1
fi
echo "  -> 00_org_display.json (API version / usuario / instancia)"

# =============================================================================
note "FASE 1 - Schema e licenciamento"
# =============================================================================
: > "$EV/_objetos_presenca.csv"
echo "sobject,status" >> "$EV/_objetos_presenca.csv"
for o in Account BusinessProfile InternalOrganizationUnit BranchUnit ServiceTerritory BusinessBrand User; do
  describe "$o"
done

soql_csv "01_account_recordtypes.csv" \
  "SELECT DeveloperName, Name, IsActive FROM RecordType WHERE SobjectType = 'Account' ORDER BY DeveloperName"

soql_csv "01_object_permissions.csv" \
  "SELECT Parent.Name, Parent.IsOwnedByProfile, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit FROM ObjectPermissions WHERE SobjectType IN ('BusinessProfile','InternalOrganizationUnit','BranchUnit','ServiceTerritory','BusinessBrand') ORDER BY SobjectType, Parent.Name"

soql_csv "01_permission_set_licenses.csv" \
  "SELECT MasterLabel, TotalLicenses, UsedLicenses, Status FROM PermissionSetLicense ORDER BY MasterLabel"

# Campos custom relevantes: extraidos dos describes acima (ver extrai_campos.js).
node ./extrai_campos.js "$EV" 2>>"$LOG" && echo "  -> _campos_custom_Account.csv / _campos_custom_User.csv"

# =============================================================================
note "FASE 2 - Inventario de dados (contagens)"
# =============================================================================
# Discriminador de nivel: descoberto na Fase 1 (RecordType e/ou campo custom).
# Contagem por RecordType (caminho preferido se houver RT de nivel):
soql_csv "02_account_por_recordtype.csv" \
  "SELECT RecordType.DeveloperName rt, COUNT(Id) qtd FROM Account GROUP BY RecordType.DeveloperName ORDER BY RecordType.DeveloperName"

# Contagem por profundidade de ParentId (fallback / verificacao cruzada):
soql_csv "02_account_nivel1_holding.csv" \
  "SELECT COUNT(Id) qtd FROM Account WHERE ParentId = null"
soql_csv "02_account_nivel2_pais.csv" \
  "SELECT COUNT(Id) qtd FROM Account WHERE ParentId != null AND Parent.ParentId = null"
soql_csv "02_account_nivel3_sociedade.csv" \
  "SELECT COUNT(Id) qtd FROM Account WHERE Parent.ParentId != null AND Parent.Parent.ParentId = null"
soql_csv "02_account_nivel4_dealer.csv" \
  "SELECT COUNT(Id) qtd FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null"
soql_csv "02_account_nivel5_ou_mais.csv" \
  "SELECT COUNT(Id) qtd FROM Account WHERE Parent.Parent.Parent.ParentId != null"

soql_csv "02_businessprofile_por_tipo.csv" \
  "SELECT BusinessPartnerType, COUNT(Id) qtd FROM BusinessProfile GROUP BY BusinessPartnerType ORDER BY BusinessPartnerType"

soql_csv "02_contagem_iou.csv"             "SELECT COUNT(Id) qtd FROM InternalOrganizationUnit"
soql_csv "02_contagem_branchunit.csv"      "SELECT COUNT(Id) qtd FROM BranchUnit"
soql_csv "02_contagem_serviceterritory.csv" "SELECT COUNT(Id) qtd FROM ServiceTerritory"
soql_csv "02_contagem_businessbrand.csv"   "SELECT COUNT(Id) qtd FROM BusinessBrand"

# =============================================================================
note "FASE 3 - Integridade da hierarquia de Account"
# =============================================================================
# [AJUSTAR APOS DESCOBERTA] Se houver RecordType/campo de nivel, troque as
# clausulas de profundidade abaixo pelo discriminador real (mais preciso).

# Orfaos de nivel pais/sociedade/dealer (ParentId nulo em quem nao deveria):
soql_csv "03_orfaos_parentid_nulo.csv" \
  "SELECT Id, Name, RecordType.DeveloperName, ParentId FROM Account WHERE ParentId = null ORDER BY Name"

# Profundidade acima de 4 niveis (achado estrutural):
soql_csv "03_profundidade_acima_4.csv" \
  "SELECT Id, Name, RecordType.DeveloperName FROM Account WHERE Parent.Parent.Parent.ParentId != null ORDER BY Name"

# Duplicidade de nome sob o mesmo pai:
soql_csv "03_dup_nome_sob_pai.csv" \
  "SELECT ParentId, Name, COUNT(Id) qtd FROM Account WHERE ParentId != null GROUP BY ParentId, Name HAVING COUNT(Id) > 1 ORDER BY COUNT(Id) DESC"

# Accounts candidatos a 'sociedade' (nivel 3) para reconciliacao com lista canonica.
# [AJUSTAR APOS DESCOBERTA] substitua BrandName__c/campo de codigo pelo campo real de codigo de sociedade.
soql_csv "03_sociedades_accounts_nivel3.csv" \
  "SELECT Id, Name, ParentId, Parent.Name FROM Account WHERE Parent.ParentId != null AND Parent.Parent.ParentId = null ORDER BY Name"

# =============================================================================
note "FASE 4 - BusinessProfile e chave SAP (CRITICIDADE MAXIMA)"
# =============================================================================
# Duplicidade de ExternalReferenceNumber (P0 se houver):
soql_csv "04_extref_duplicado.csv" \
  "SELECT ExternalReferenceNumber, COUNT(Id) qtd FROM BusinessProfile WHERE ExternalReferenceNumber != null GROUP BY ExternalReferenceNumber HAVING COUNT(Id) > 1 ORDER BY COUNT(Id) DESC"

# BP de dealer com ExternalReferenceNumber nulo (P0):
soql_csv "04_bp_salesdealer_sem_extref.csv" \
  "SELECT Id, BusinessPartnerRegisteredName, BusinessPartnerCode, ExternalReferenceNumber, BusinessPartnerType FROM BusinessProfile WHERE BusinessPartnerType = 'Sales Dealer' AND ExternalReferenceNumber = null ORDER BY BusinessPartnerRegisteredName"

# Todos os BP (para diff anti-join local dealer<->BP). [AJUSTAR] confirme o campo
# de lookup para Account no describe_BusinessProfile.json (ex.: ParentId/AccountId)
# e inclua-o na projecao para o cruzamento.
soql_csv "04_todos_bp.csv" \
  "SELECT Id, BusinessPartnerType, BusinessPartnerCode, BusinessPartnerRegisteredName, ExternalReferenceNumber FROM BusinessProfile ORDER BY BusinessPartnerType"

# Todos os Accounts candidatos a dealer (nivel 4) para o diff local:
soql_csv "04_dealers_accounts_nivel4.csv" \
  "SELECT Id, Name, ParentId FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null ORDER BY Name"

# =============================================================================
note "FASE 5 - InternalOrganizationUnit"
# =============================================================================
soql_csv "05_iou_lista.csv" \
  "SELECT Id, Name, AccountId, Account.Name FROM InternalOrganizationUnit ORDER BY Name"
soql_csv "05_iou_accountid_nulo.csv" \
  "SELECT Id, Name FROM InternalOrganizationUnit WHERE AccountId = null ORDER BY Name"

# =============================================================================
note "FASE 6 - BranchUnit / ServiceTerritory"
# =============================================================================
soql_csv "06_branchunit_lista.csv" \
  "SELECT Id, Name, ParentBranchUnitId, AccountId FROM BranchUnit ORDER BY Name"
soql_csv "06_serviceterritory_lista.csv" \
  "SELECT Id, Name, ParentTerritoryId FROM ServiceTerritory ORDER BY Name"

# =============================================================================
note "FASE 7 - Configuracao de suporte"
# =============================================================================
# CMT: [AJUSTAR APOS DESCOBERTA] confirme os campos via
#   sf sobject describe -o $ORG -s Sociedad_Config__mdt
describe "Sociedad_Config__mdt"
soql_csv "07_sociedad_config_mdt.csv" \
  "SELECT DeveloperName, MasterLabel FROM Sociedad_Config__mdt ORDER BY DeveloperName"

# GVS_Sociedad: retrieve para leitura local (comparacao feita no relatorio).
run "Retrieve GlobalValueSet GVS_Sociedad" \
  sf project retrieve start -o "$ORG" -m "GlobalValueSet:GVS_Sociedad" --target-metadata-dir "$EV/mdt_gvs" 2>/dev/null \
  || run "Retrieve GVS_Sociedad (fallback source-format)" \
     sf project retrieve start -o "$ORG" -m "GlobalValueSet:GVS_Sociedad"

# BrandName__c - taxa de preenchimento no escopo dealer (nivel 4):
# [AJUSTAR] confirme a existencia de Account.BrandName__c no describe_Account.json.
soql_csv "07_brandname_preenchido_dealers.csv" \
  "SELECT COUNT(Id) preenchidos FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null AND BrandName__c != null"
soql_csv "07_brandname_nulo_dealers.csv" \
  "SELECT COUNT(Id) nulos FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null AND BrandName__c = null"

# User.Sociedad__c e User.SucursalBP__c - preenchimento nos usuarios ativos:
soql_csv "07_user_sociedad_preenchimento.csv" \
  "SELECT Sociedad__c, COUNT(Id) qtd FROM User WHERE IsActive = true GROUP BY Sociedad__c ORDER BY Sociedad__c"
soql_csv "07_user_sucursalbp_nulo.csv" \
  "SELECT COUNT(Id) sem_sucursal FROM User WHERE IsActive = true AND SucursalBP__c = null"

# =============================================================================
note "FASE 8 - Automacoes e dependencias"
# =============================================================================
soql_csv "08_flows_ativos.csv" \
  "SELECT ApiName, Label, ProcessType, TriggerType, IsActive FROM FlowDefinitionView WHERE IsActive = true ORDER BY ProcessType, ApiName"

# Cascata de Leads: retrieve dos flows de derivacao de sociedade para inspecao do
# passo dealerCode lookup (chave esperada: BusinessProfile.ExternalReferenceNumber).
run "Retrieve Lead_BS_DeriveSociedad" \
  sf project retrieve start -o "$ORG" -m "Flow:Lead_BS_DeriveSociedad"

# Sharing rules de Account (dependem de BrandName__c / campo de sociedade):
run "Retrieve SharingRules de Account" \
  sf project retrieve start -o "$ORG" -m "SharingRules:Account"

echo -e "\nAuditoria de coleta concluida em $(ts)." | tee -a "$LOG"
echo "Evidencias em: $EV" | tee -a "$LOG"
echo "Proximo passo: preencher ../RELATORIO_MODELO_ORGANIZACIONAL.md a partir das evidencias."
