// Exporta as 3 consultas de saida/consultas.soql (geradas por validar_gerente.py) para saida/accounts.json, opps.json e
// users.json no formato do `sf data query --json`, prontos para a passada online do validador.
// A consulta 1 (contas por CNPJ nos dois formatos) passa de 57 KB com 1.500 linhas e o `sf data query` devolve HTTP 431
// (URL longa demais): ela roda em lotes de 250 valores e os registros sao juntados. As outras duas rodam inteiras.
// As consultas vao por arquivo (--file) porque o shim sf.cmd do Windows quebra com `%` e parenteses no -q.
// Uso: node exportar_contas_lotes.js [alias-da-org=btp-prod] [pasta=saida]
const fs=require('fs'),path=require('path'),{execFileSync}=require('child_process');
const ORG=process.argv[2]||'btp-prod', OUT=process.argv[3]||'saida', N=250;
const texto=fs.readFileSync(path.join(OUT,'consultas.soql'),'utf8');
const consultas={};
for(const bloco of texto.split(/^-- \d\) /m).filter(Boolean)){const [cab,...resto]=bloco.split('\n');consultas[cab.trim().replace('.json','')]=resto.join('\n').trim();}
function roda(soql,nome){
  const f=path.join(OUT,'q_'+nome+'.soql');fs.writeFileSync(f,soql+'\n');
  const out=execFileSync('sf.cmd',['data','query','-o',ORG,'--json','--file',f],{encoding:'utf8',maxBuffer:64*1024*1024,shell:true});
  const j=JSON.parse(out);if(j.status!==0)throw new Error(nome+': '+JSON.stringify(j).slice(0,300));
  return j.result.records;
}
for(const nome of ['opps','users']){const r=roda(consultas[nome],nome);fs.writeFileSync(path.join(OUT,nome+'.json'),JSON.stringify({status:0,result:{records:r,totalSize:r.length,done:true}}));console.log(nome+':',r.length,'registro(s)');}
const m=consultas.accounts.match(/^(.*WHERE DocumentNumber__c IN \()(.*)(\))\s*$/s);
const vals=m[2].split(',').map(s=>s.trim());let recs=[];
for(let i=0;i<vals.length;i+=N){const r=roda(m[1]+vals.slice(i,i+N).join(',')+m[3],'acc_lote');console.log('accounts lote',i/N+1,':',r.length,'registro(s) de',Math.min(N,vals.length-i),'valores');recs=recs.concat(r);}
fs.writeFileSync(path.join(OUT,'accounts.json'),JSON.stringify({status:0,result:{records:recs,totalSize:recs.length,done:true}}));
console.log('accounts:',recs.length,'registro(s) para',vals.length/2,'CNPJ(s)');
