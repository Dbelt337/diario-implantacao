// 11 - CORRECAO das notas de 08/09 em W-000117 (CAT-ACC-01) e W-000103 (CAT-MIG-01),
// apos a auditoria das contas "Billing" em producao (3 rodadas de consultas, 08/09).
// Grava 1 nota por work no final do Details. Idempotente: se o cabecalho ja existir, pula.
// Esperado na 1a execucao: 2 notas gravadas. Rode o 04 (v8) depois para validar.
//
// ANTES DE RODAR, confirmar os 3 pontos marcados com [CONFIRMAR] no texto e ajustar se preciso.

Map<String, String> cabecalho = new Map<String, String>{
    'W-000117' => '--- CORRECAO APOS AUDITORIA DAS CONTAS BILLING (08/09) ---',
    'W-000103' => '--- CORRECAO DO PASSO 2 DA CARGA (08/09) ---'
};

Map<String, String> corpo = new Map<String, String>();

corpo.put('W-000117',
    'Consultas em produção (08/09, 2ª e 3ª rodadas). '
  + '(1) As 1.938 contas do record type "Billing" NÃO são Billing Accounts: todas têm CPF/CNPJ (DocumentNumber__c, External ID único), '
  + '1.936 têm Código SAP do Cliente (ExternalId__c), nenhuma tem ParentId, Root Account, grupo econômico ou contato primário; '
  + 'a amostra mostra pessoas físicas com CPF e Party próprio, criadas por "Integracao Ordem Manual" (1.482, usuário em duplicidade com e sem cedilha), '
  + '"Usuario Teste" (112) e vendedores/BKO (344). Como o CPF é único em Account, nenhuma delas duplica uma "Pessoa Física": são clientes cadastrados com o record type errado. '
  + '(2) Nos pedidos, as 2.505 linhas com Billing/Service preenchidas (549 pedidos) usam a própria conta "Pessoa Física" do cliente nos três papéis (cliente, Billing e Service); nenhuma conta "Billing" aparece em pedido. '
  + '(3) Party é 1:1 com Account (106.273 contas, 106.273 parties): não é vínculo entre contas. '
  + '(4) ParentId não é usado na org (2 contas em 111 mil) e Person Accounts, se habilitados, não participam de hierarquia de contas. '
  + '(5) External IDs existentes em Account: CPF/CNPJ (DocumentNumber__c, único), Código SAP do Cliente (ExternalId__c: 53.033 PF, 2.088 PJ, 1.936 "Billing", apenas 87 das 54.485 "B2B - Pessoa jurídica"), BillingAddressId/ShippingAddressId. '
  + '(6) "B2B - Pessoa jurídica" é a base importada em 2025 (49.526 contas por 2 usuários) mais a criação manual dos vendedores B2B em 2026; "Pessoa Jurídica" (2.089) é criada pelo "Usuário de Integração" em 2026 [CONFIRMAR qual sistema]. '
  + '(7) Readiness de Person Accounts em produção: 3 de 4 passos ok (Contact já em Controlled By Parent); falta só o acknowledgement, deixado sem confirmar de propósito.\n'
  + 'AJUSTES NA US (substituem os itens (b) e (d) da nota anterior): '
  + '(b\') o record type "Billing" atual não pode ser reaproveitado como Billing Account: reclassificar as 1.938 contas como "Pessoa Física" (mesmo CPF, mesmo Código SAP, sem perda de dado) e só então usar o record type "Billing" para o papel de cobrança, ou criar "Billing Account" novo e desativar o antigo. '
  + '(d\') o Business da RN-01 é "B2B - Pessoa jurídica"; as "Pessoa Jurídica" de integração devem ser unificadas nele (ou documentadas como PJ do canal B2C) antes da migração. '
  + 'RN-01: o vínculo Billing/Service -> cliente NÃO será ParentId (não usado na org e incompatível com Person Account) nem Party (1:1): criar lookup "Conta cliente" (Account) obrigatório nos record types Billing e Service, com External ID por papel. '
  + 'RN-06/RN-07: CPF/CNPJ é único em Account, logo a Billing Account não repete o documento do cliente; sua chave é o ID externo da conta de cobrança do Customer Core [CONFIRMAR se Customer Core = SAP e se o campo é ExternalId__c] mais o lookup do cliente. '
  + 'RN-02/RN-03/RN-04 (proposta para decisão com SysMap): manter na Onda 1 o padrão já exercitado em 549 pedidos, em que a conta do cliente é a própria Billing e Service padrão no Create Cart, e criar Billing Account separada só quando o pagador é outro (aprovação do BKO) e Service Account só a partir do segundo endereço; isso evita criar ~106 mil contas auxiliares na migração e mantém a decomposição do OM funcionando como hoje. '
  + 'Governança: unificar os dois usuários "Integracao/Integraçao Ordem Manual" [CONFIRMAR o que é a Ordem Manual], excluir ou inativar as 112 contas do "Usuario Teste", sanear as 4 contas sem record type, e carregar o Código SAP nas contas B2B antes da migração de ativos.\n'
  + 'CENÁRIO E (substitui o anterior): Dado a base atual, quando a US for entregue, então nenhuma conta com CPF/CNPJ de cliente está no record type Billing, toda Billing Account tem o lookup de cliente e o ID externo de cobrança preenchidos, e nenhuma conta fica sem record type.');

corpo.put('W-000103',
    'Auditoria de 08/09 (ver nota "CORRECAO APOS AUDITORIA DAS CONTAS BILLING" na W-000117): as 1.938 contas "Billing" existentes são clientes pessoa física com CPF e Código SAP, não contas de cobrança. '
  + 'O passo (2) da ordem de carga passa a ser: reclassificar essas contas como "Pessoa Física" e, se a decisão da CAT-ACC-01 mantiver a conta do cliente como Billing/Service padrão na Onda 1, não há Billing Accounts a carregar além dos casos de pagador diferente. '
  + 'Chave de reconciliação com o Customer Core: Código SAP do Cliente (ExternalId__c) [CONFIRMAR], preenchido em 99,9% das contas PF e PJ de 2026 e em apenas 87 das 54.485 "B2B - Pessoa jurídica": a base B2B precisa receber o código antes da carga de ativos (novo pré-requisito do passo 1). '
  + 'Limpeza prévia ao passo 1: 112 contas do "Usuario Teste", 4 contas sem record type, usuário de integração "Ordem Manual" em duplicidade. '
  + 'Volumetria confirmada em 08/09: 111.590 contas, 1 Asset, 549 pedidos com Billing/Service preenchidos.');

Integer gravadas = 0, puladas = 0;
List<agf__ADM_Work__c> paraAtualizar = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Details__c
                           FROM agf__ADM_Work__c WHERE Name IN :cabecalho.keySet()]) {
    System.debug('ALVO ' + w.Name + ' = ' + w.agf__Subject__c);
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    String cab = cabecalho.get(w.Name);
    if (det.contains(cab)) {
        System.debug('PULOU ' + w.Name + ' | nota ja existe: ' + cab);
        puladas++;
        continue;
    }
    w.agf__Details__c = det + '\n\n' + cab + '\n' + corpo.get(w.Name);
    paraAtualizar.add(w);
    System.debug('NOTA em ' + w.Name + ' | ' + cab + ' | +' + (corpo.get(w.Name).length() + cab.length()) + ' chars');
    gravadas++;
}
if (!paraAtualizar.isEmpty()) update paraAtualizar;
System.debug('SCRIPT 11 - notas gravadas: ' + gravadas + ', puladas: ' + puladas + ' (esperado na 1a execucao: 2 gravadas)');
