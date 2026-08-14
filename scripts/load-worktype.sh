#!/usr/bin/env bash
#
# Carrega os WorkTypes de produção numa sandbox e valida as chaves geradas.
#
#   ./scripts/load-worktype.sh <alias-da-org> [--dry-run] [--yes] [--force]
#
# Requer o Salesforce CLI (sf) autenticado na org de destino.
# Roda em Linux, macOS, WSL e Git Bash.
#
# Só carrega os 11 campos graváveis. ServiceTypeKey__c e SkillType__c são
# fórmulas e se calculam sozinhos a partir de MacroCategory__c, Product__c,
# SubCategory__c e Criticality__c. DurationInMinutes é derivado pela plataforma.
# OwnerId fica de fora de propósito: os ids de usuário de produção não existem
# na sandbox, então o registro fica com quem executa a carga.

set -euo pipefail

CSV="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/data/worktype/WorkType.csv"
ORG=""; DRY_RUN=false; ASSUME_YES=false; FORCE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --yes|-y)  ASSUME_YES=true ;;
    --force)   FORCE=true ;;
    -*)        echo "opção desconhecida: $arg" >&2; exit 2 ;;
    *)         ORG="$arg" ;;
  esac
done

die() { echo "ERRO: $*" >&2; exit 1; }

[[ -n "$ORG" ]] || die "informe o alias da org: ./scripts/load-worktype.sh <alias> [--dry-run]"
command -v sf >/dev/null || die "Salesforce CLI (sf) não encontrado no PATH."
[[ -f "$CSV" ]] || die "arquivo não encontrado: $CSV"

# Lê uma única célula do resultado de uma query (sem depender de jq).
soql1() { sf data query -o "$ORG" -q "$1" --result-format csv | tail -n1 | tr -d '"\r'; }

echo "==> Org de destino: $ORG"
ORG_INFO="$(sf data query -o "$ORG" \
  -q "SELECT Name, IsSandbox, InstanceName FROM Organization" --result-format csv | tail -n1)"
ORG_NAME="$(cut -d, -f1 <<<"$ORG_INFO" | tr -d '"\r')"
IS_SANDBOX="$(cut -d, -f2 <<<"$ORG_INFO" | tr -d '"\r')"
INSTANCE="$(cut -d, -f3 <<<"$ORG_INFO" | tr -d '"\r')"
echo "    $ORG_NAME · instância $INSTANCE · IsSandbox=$IS_SANDBOX"

# Trava de segurança: nunca carregar em produção por acidente.
if [[ "$IS_SANDBOX" != "true" ]]; then
  if [[ "${ALLOW_PRODUCTION:-}" == "1" && "$FORCE" == true ]]; then
    echo "!!! PRODUÇÃO — prosseguindo porque ALLOW_PRODUCTION=1 e --force foram usados."
  else
    die "'$ORG' NÃO é sandbox. Recusando a carga.
     Se a intenção for mesmo produção: ALLOW_PRODUCTION=1 $0 $ORG --force"
  fi
fi

EXISTING="$(soql1 "SELECT COUNT(Id) total FROM WorkType")"
echo "==> WorkTypes já existentes na org: $EXISTING"
if [[ "$EXISTING" != "0" && "$FORCE" != true ]]; then
  die "a org já tem $EXISTING WorkType(s). Carregar agora criaria duplicatas.
     Revise antes, ou use --force se a duplicação for intencional."
fi

ROWS=$(( $(wc -l < "$CSV") - 1 ))
echo "==> Registros no CSV: $ROWS"

# Chave de integração = MacroCategory + Product + SubCategory + Criticality
# (colunas 6..9 do CSV). Avisa sobre colisões antes de carregar.
awk -F, 'NR>1 {print $6 $7 $8 $9}' "$CSV" | sort | uniq -d > /tmp/wt_dup.$$ || true
if [[ -s /tmp/wt_dup.$$ ]]; then
  echo "!!! ATENÇÃO: chaves ServiceTypeKey__c duplicadas no CSV:"
  sed 's/^/      /' /tmp/wt_dup.$$
  echo "    A composite usa records[0]; com chave repetida a escolha é não determinística."
fi
rm -f /tmp/wt_dup.$$

if [[ "$DRY_RUN" == true ]]; then
  echo "==> --dry-run: nada foi carregado."
  exit 0
fi

if [[ "$ASSUME_YES" != true ]]; then
  read -r -p "Carregar $ROWS WorkTypes em '$ORG_NAME'? [s/N] " ans
  [[ "$ans" =~ ^[sSyY]$ ]] || { echo "cancelado."; exit 0; }
fi

echo "==> Carregando..."
sf data import bulk --sobject WorkType --file "$CSV" --target-org "$ORG" --wait 10

echo "==> Validando as chaves geradas..."
sf data query -o "$ORG" \
  -q "SELECT ServiceTypeKey__c FROM WorkType" \
  --result-format csv | tail -n +2 | tr -d '"\r' | sort > /tmp/wt_got.$$
awk -F, 'NR>1 {print $6 $7 $8 $9}' "$CSV" | sort > /tmp/wt_want.$$

if diff -q /tmp/wt_want.$$ /tmp/wt_got.$$ >/dev/null; then
  echo "==> OK: as $ROWS chaves geradas batem com o esperado."
  STATUS=0
else
  echo "!!! DIVERGÊNCIA entre as chaves esperadas e as geradas:"
  diff /tmp/wt_want.$$ /tmp/wt_got.$$ | sed 's/^/      /' || true
  echo "    Causa provável: valor de picklist ausente ou diferente na org de destino"
  echo "    (MacroCategory__c, Product__c, SubCategory__c, Criticality__c)."
  STATUS=1
fi
rm -f /tmp/wt_got.$$ /tmp/wt_want.$$
exit $STATUS
