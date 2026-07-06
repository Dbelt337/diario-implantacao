/* US-006a CR — adiciona o usuario ATUAL como membro de todos os grupos MDG_*
   (destrava o teste: o flow precisa de >=1 membro no grupo resolvido).
   Idempotente: nao duplica se ja for membro. */
Id uid = UserInfo.getUserId();
Set<Id> jaTem = new Set<Id>();
for (GroupMember gm : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :uid])
    jaTem.add(gm.GroupId);
List<GroupMember> novos = new List<GroupMember>();
for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type='Regular' AND DeveloperName LIKE 'MDG_%']) {
    if (!jaTem.contains(g.Id)) novos.add(new GroupMember(GroupId=g.Id, UserOrGroupId=uid));
}
if (!novos.isEmpty()) insert novos;
System.debug(LoggingLevel.ERROR, 'MDG | adicionado a ' + novos.size() + ' grupos MDG (user=' + UserInfo.getName() + ')');
