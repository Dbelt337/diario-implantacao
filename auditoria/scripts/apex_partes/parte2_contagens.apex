System.debug('AUDIT> n1 Holding[1]: '+[SELECT COUNT() FROM Account WHERE ParentId=null]);
System.debug('AUDIT> n2 Pais[6]: '+[SELECT COUNT() FROM Account WHERE ParentId!=null AND Parent.ParentId=null]);
System.debug('AUDIT> n3 Sociedade[17]: '+[SELECT COUNT() FROM Account WHERE Parent.ParentId!=null AND Parent.Parent.ParentId=null]);
System.debug('AUDIT> n4 Dealer[128]: '+[SELECT COUNT() FROM Account WHERE Parent.Parent.ParentId!=null AND Parent.Parent.Parent.ParentId=null]);
System.debug('AUDIT> n5+ (achado se>0): '+[SELECT COUNT() FROM Account WHERE Parent.Parent.Parent.ParentId!=null]);
System.debug('AUDIT> ParentId nulo (holding+orfaos): '+[SELECT COUNT() FROM Account WHERE ParentId=null]);
for(AggregateResult r:[SELECT RecordType.DeveloperName rt,COUNT(Id) c FROM Account GROUP BY RecordType.DeveloperName])
 System.debug('AUDIT> AccByRT '+r.get('rt')+'='+r.get('c'));
for(AggregateResult r:[SELECT ParentId p,Name n,COUNT(Id) c FROM Account WHERE ParentId!=null GROUP BY ParentId,Name HAVING COUNT(Id)>1])
 System.debug('AUDIT> DUP sob pai '+r.get('p')+' nome='+r.get('n')+' x'+r.get('c'));
