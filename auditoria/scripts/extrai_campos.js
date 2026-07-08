#!/usr/bin/env node
// Extrai campos custom relevantes dos describes (Account, User) coletados pelo
// run_auditoria.sh e grava CSVs de evidencia. Somente leitura de arquivos locais.
const fs = require('fs');
const path = require('path');

const EV = process.argv[2] || '../evidencias';

function loadFields(sobj) {
  const f = path.join(EV, `describe_${sobj}.json`);
  if (!fs.existsSync(f)) return null;
  const j = JSON.parse(fs.readFileSync(f, 'utf8'));
  const fields = (j.result && j.result.fields) || j.fields || [];
  return fields;
}

function dump(sobj, filter) {
  const fields = loadFields(sobj);
  if (!fields) { console.error(`describe_${sobj}.json ausente`); return; }
  const rows = fields
    .filter(filter)
    .map(x => [x.name, x.label, x.type, x.custom, x.unique, x.idLookup,
               (x.referenceTo || []).join('|')].join(','));
  const out = path.join(EV, `_campos_custom_${sobj}.csv`);
  fs.writeFileSync(out, 'name,label,type,custom,unique,idLookup,referenceTo\n' + rows.join('\n') + '\n');
}

// Account: campos custom + qualquer coisa de sociedade/marca/codigo
dump('Account', f => f.custom ||
  /sociedad|brand|marca|sap|codigo|code/i.test(f.name));

// User: campos alvo do roteiro
dump('User', f => f.custom ||
  /sociedad|sucursal|tipoauto|canal/i.test(f.name));

console.error('extrai_campos: OK');
