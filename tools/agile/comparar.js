// Compara as works da org (saida/01_works.json) com o CSV do pacote (time, sprint, prioridade, responsavel, status) e com o
// mapa de prioridades do script 40 v2. Somente leitura local. Uso: node comparar.js [saida] [csv]
const fs=require('fs'),path=require('path');
const OUT=process.argv[2]||path.join(__dirname,'saida'), CSV=process.argv[3]||path.join(__dirname,'..','..','docs','2026-09-15-works-validadas-pacote-marcelo.csv');
const w=JSON.parse(fs.readFileSync(path.join(OUT,'01_works.json'),'utf8')).result.records;const g=(r,p)=>r[p]&&r[p].Name||'';
const csv=fs.readFileSync(CSV,'utf8').replace(/^\uFEFF/,'').split(/\r?\n/).filter(Boolean);const H=csv[0].split(';');const P={};
for(const l of csv.slice(1)){const f=l.split(';');const o={};H.forEach((h,i)=>o[h]=f[i]||'');P[o.Work]=o;}
const norm=s=>(s||'').replace(/\s*\(alterado.*?\)\s*$/,'').replace(/,\s*alterado em \d+\/\d+\)/,')').trim();
const W={};for(const r of w)W[r.Name]=r;
const cnt=f=>{const c={};for(const r of w){const k=f(r)||'(vazio)';c[k]=(c[k]||0)+1;}return c;};
console.log('TOTAL works:',w.length,'| status:',JSON.stringify(cnt(r=>r.agf__Status__c)));
console.log('por sprint:',JSON.stringify(cnt(r=>g(r,'agf__Sprint__r'))));
const emSprint=w.filter(r=>g(r,'agf__Sprint__r'));console.log('com sprint:',emSprint.length,'| em Sprint 1-4:',emSprint.filter(r=>/^Sprint [1-4] - /.test(g(r,'agf__Sprint__r'))).length,'| em Jun/Jul Time Salesforce:',emSprint.filter(r=>/Time Salesforce/.test(g(r,'agf__Sprint__r'))).length);
console.log('por time:',JSON.stringify(cnt(r=>g(r,'agf__Scrum_Team__r'))),'| por prioridade:',JSON.stringify(cnt(r=>r.agf__Priority__c)));
console.log('story points preenchidos:',w.filter(r=>r.agf__Story_Points__c!=null).length,'->',w.filter(r=>r.agf__Story_Points__c!=null).map(r=>r.Name.replace('W-000','')+'='+r.agf__Story_Points__c).join(' '));
console.log('internas -i (Subject termina em -i ou i):',w.filter(r=>/-\s*i\s*$/i.test(r.agf__Subject__c||'')).map(r=>r.Name+' "'+r.agf__Subject__c.slice(-25)+'" sprint='+(g(r,'agf__Sprint__r')||'-')).join(' ; ')||'nenhuma');
console.log('sem epico:',w.filter(r=>!g(r,'agf__Epic__r')).map(r=>r.Name+'('+r.agf__Status__c+')').join(' '));
console.log('sem priority:',w.filter(r=>!r.agf__Priority__c).map(r=>r.Name).join(' ')||'nenhuma','| sem tag:',w.filter(r=>!g(r,'agf__Product_Tag__r')).map(r=>r.Name).join(' ')||'nenhuma','| sem details:',w.filter(r=>!r.agf__Details__c).map(r=>r.Name).join(' ')||'nenhuma');
console.log('sem responsavel (abertas):',w.filter(r=>r.agf__Status__c!=='Closed'&&!g(r,'agf__Assignee__r')).map(r=>r.Name).join(' ')||'nenhuma');
console.log('P0 fora de sprint:',w.filter(r=>r.agf__Priority__c==='P0'&&!g(r,'agf__Sprint__r')).map(r=>r.Name).join(' ')||'nenhuma');
console.log('em sprint de outro time:',w.filter(r=>r.agf__Sprint__r&&r.agf__Sprint__r.agf__Scrum_Team__r&&r.agf__Sprint__r.agf__Scrum_Team__r.Name!==g(r,'agf__Scrum_Team__r')).map(r=>r.Name).join(' ')||'nenhuma');
console.log('\n=== DIVERGENCIAS vs CSV (93) ===');const div=[];
for(const [k,o] of Object.entries(P)){const r=W[k];if(!r){div.push([k,'existencia','no CSV','NAO EXISTE']);continue;}
 const chk=(cat,esp,enc)=>{if((esp||'')!==(enc||''))div.push([k,cat,esp||'(vazio)',enc||'(vazio)',g(r,'LastModifiedBy'),r.LastModifiedDate.slice(0,16)]);};
 chk('time',norm(o['Time (Scrum Team)']),g(r,'agf__Scrum_Team__r'));chk('sprint',norm(o['Sprint (Agile, 15/09)']),g(r,'agf__Sprint__r'));chk('prioridade',o['Prioridade (Agile, 16/09)'],r.agf__Priority__c);chk('responsavel',norm(o['Responsável (Agile, 15/09)']),g(r,'agf__Assignee__r'));chk('status',o['Status'],r.agf__Status__c);chk('epico',o['Épico'],g(r,'agf__Epic__r'));}
for(const d of div)console.log(d.join(' | '));console.log('total divergencias:',div.length);
console.log('\n=== FORA DO CSV ===');for(const r of w.filter(r=>!P[r.Name]))console.log(r.Name,'|',g(r,'agf__Scrum_Team__r'),'|',g(r,'agf__Sprint__r')||'-','|',r.agf__Priority__c||'-','|',r.agf__Status__c,'|',g(r,'agf__Epic__r')||'SEM EPICO','|',g(r,'agf__Assignee__r')||'-','|',JSON.stringify(r.agf__Subject__c));
console.log('\n=== COMPOSICAO SPRINTS ===');for(const sp of [...new Set(w.map(r=>g(r,'agf__Sprint__r')).filter(Boolean))].sort()){const x=w.filter(r=>g(r,'agf__Sprint__r')===sp);console.log('## '+sp+' ('+x.length+')');for(const r of x)console.log('  '+r.Name+' | '+(r.agf__Priority__c||'-')+' | '+(g(r,'agf__Epic__r')||'-').slice(0,32)+' | '+(g(r,'agf__Assignee__r')||'sem resp')+' | '+r.agf__Status__c+' | '+(r.agf__Subject__c||'').slice(0,60));}
console.log('\n=== BACKLOG SysMap (sem sprint) por grupo ===');const bl=w.filter(r=>!g(r,'agf__Sprint__r')&&g(r,'agf__Scrum_Team__r')==='SysMap');const grp=r=>{const s=r.agf__Subject__c||'';return /EPC-|CAT-|QUAL-/.test(s)?'catalogo':/TEC-INT/.test(s)?'TEC-INT':/B2C|TEC-B2C/.test(s)?'B2C':/B2B/.test(s)?'B2B':/TEC-DEV|TEC-OM|CPQ/.test(s)?'tecnico':'outro';};const gc={};for(const r of bl){const k=grp(r)+' '+(r.agf__Priority__c||'-');(gc[k]=gc[k]||[]).push(r.Name.replace('W-000',''));}for(const [k,v] of Object.entries(gc).sort())console.log(k.padEnd(14),v.length,':',v.join(' '));
