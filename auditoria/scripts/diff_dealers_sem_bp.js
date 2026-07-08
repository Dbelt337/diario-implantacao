#!/usr/bin/env node
// Anti-join local: dealers (Account nivel 4) SEM BusinessProfile 'Sales Dealer'.
// Roda depois de run_auditoria.sh, quando o campo de lookup BP->Account estiver
// confirmado no describe_BusinessProfile.json e adicionado a 04_todos_bp.csv.
//
// Uso:
//   node diff_dealers_sem_bp.js <col_lookup_no_bp>
//   ex.: node diff_dealers_sem_bp.js ParentId
//
// Le:  ../evidencias/04_dealers_accounts_nivel4.csv  (Id,Name,ParentId)
//      ../evidencias/04_todos_bp.csv                 (deve conter a coluna de lookup)
// Grava: ../evidencias/04_dealers_sem_bp.csv
const fs = require('fs');
const path = require('path');

const EV = '../evidencias';
const lookupCol = process.argv[2];
if (!lookupCol) {
  console.error('Informe a coluna de lookup BP->Account. Ex.: node diff_dealers_sem_bp.js ParentId');
  process.exit(1);
}

function parseCsv(file) {
  const txt = fs.readFileSync(path.join(EV, file), 'utf8').trim();
  const lines = txt.split(/\r?\n/);
  const head = lines.shift().split(',');
  return lines.map(l => {
    const cells = l.split(',');
    const o = {}; head.forEach((h, i) => o[h.trim()] = (cells[i] || '').trim());
    return o;
  });
}

const dealers = parseCsv('04_dealers_accounts_nivel4.csv');
const bps = parseCsv('04_todos_bp.csv').filter(b => (b.BusinessPartnerType || '') === 'Sales Dealer');

if (!(lookupCol in (bps[0] || {}))) {
  console.error(`Coluna '${lookupCol}' ausente em 04_todos_bp.csv. Reexporte o BP incluindo o lookup real (ver describe_BusinessProfile.json).`);
  process.exit(2);
}

const bpByAccount = new Set(bps.map(b => b[lookupCol]).filter(Boolean));
const semBp = dealers.filter(d => !bpByAccount.has(d.Id));

const out = 'AccountId,Name,ParentId\n' +
  semBp.map(d => `${d.Id},${d.Name},${d.ParentId}`).join('\n') + '\n';
fs.writeFileSync(path.join(EV, '04_dealers_sem_bp.csv'), out);
console.error(`dealers nivel4: ${dealers.length} | BP Sales Dealer: ${bps.length} | dealers SEM BP: ${semBp.length}`);
