#!/usr/bin/env bash
# Valida cada slide e o presentation.xml de um .pptx contra o XSD oficial (ISO/IEC 29500-4 pml.xsd) com xmllint.
# Uso: scripts/validar_pptx_xsd.sh arquivo.pptx caminho/para/schemas/ISO-IEC29500-4_2016
set -euo pipefail
PPTX="$1"; XSD="$2/pml.xsd"; TMP=$(mktemp -d)
python3 -c "import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$PPTX" "$TMP"
rc=0
for f in "$TMP"/ppt/slides/slide*.xml "$TMP"/ppt/presentation.xml; do
  if ! xmllint --noout --schema "$XSD" "$f" >/dev/null 2>"$TMP/err.txt"; then echo "FALHA: ${f#$TMP/}"; cat "$TMP/err.txt"; rc=1; fi
done
[ $rc -eq 0 ] && echo "OK: todos os slides e presentation.xml validam contra pml.xsd"
rm -rf "$TMP"; exit $rc
