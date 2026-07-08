#!/usr/bin/env node
// Matriz de reconciliacao de 4 colunas: lista canonica x GVS_Sociedad x
// Sociedad_Config__mdt x Accounts de sociedade. Qualquer valor a mais, a menos
// ou grafado diferente e achado (Fase 7 / Sec 4.6). Somente leitura local.
//
// Uso: node reconciliacao_sociedades.js
// Le:
//   ../referencia/sociedades_canonicas.csv          (coluna codigo_sociedad)
//   ../evidencias/07_sociedad_config_mdt.csv         (DeveloperName ou MasterLabel = codigo)
//   ../evidencias/03_sociedades_accounts_nivel3.csv  (Name contem/equivale ao codigo)
//   ../evidencias/gvs_valores.csv                    (coluna 'value' - ver README p/ extrair)
// Grava: ../evidencias/07_matriz_reconciliacao.csv
const fs = require('fs');
const path = require('path');
const EV = '../evidencias';
const REF = '../referencia';

function readCol(file, col, base) {
  const full = path.join(base, file);
  if (!fs.existsSync(full)) { console.error(`(aviso) ${file} ausente - coluna ficara vazia`); return new Set(); }
  const lines = fs.readFileSync(full, 'utf8').trim().split(/\r?\n/);
  const head = lines.shift().split(',').map(h => h.trim());
  const idx = head.indexOf(col);
  if (idx < 0) { console.error(`(aviso) coluna '${col}' ausente em ${file}`); return new Set(); }
  return new Set(lines.map(l => (l.split(',')[idx] || '').trim()).filter(Boolean));
}

const canon = readCol('sociedades_canonicas.csv', 'codigo_sociedad', REF);
// CMT: usa DeveloperName; ajuste para MasterLabel se o codigo estiver la.
const cmt   = readCol('07_sociedad_config_mdt.csv', 'DeveloperName', EV);
// Accounts nivel 3: assume que o codigo aparece em Name; ajuste conforme padrao real.
const accs  = readCol('03_sociedades_accounts_nivel3.csv', 'Name', EV);
const gvs   = readCol('gvs_valores.csv', 'value', EV);

const all = new Set([...canon, ...cmt, ...accs, ...gvs]);
const rows = [...all].sort().map(v => {
  const c = canon.has(v) ? 'X' : '';
  const g = gvs.has(v) ? 'X' : '';
  const m = cmt.has(v) ? 'X' : '';
  const a = accs.has(v) ? 'X' : '';
  const ok = (c && g && m && a) ? 'OK' : 'DIVERGENCIA';
  return `${v},${c},${g},${m},${a},${ok}`;
});
const out = 'valor,canonica,gvs,cmt,account,status\n' + rows.join('\n') + '\n';
fs.writeFileSync(path.join(EV, '07_matriz_reconciliacao.csv'), out);

const div = rows.filter(r => r.endsWith('DIVERGENCIA')).length;
console.error(`Reconciliacao: ${rows.length} valores | ${div} divergencias -> 07_matriz_reconciliacao.csv`);
console.error(`canonica=${canon.size} gvs=${gvs.size} cmt=${cmt.size} accounts=${accs.size}`);
