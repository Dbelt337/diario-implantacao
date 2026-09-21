@isTest
private class ApprovalWorkItemsControllerTest {

    // ApprovalWorkItem e gerado pela plataforma (Approval Orchestration).
    // Confirmar com ApprovalWorkItem.SObjectType.getDescribe().isCreateable():
    // se false, nao ha como montar massa e o teste fica limitado ao contrato
    // do metodo. Nesse caso a cobertura funcional vem do teste manual em sandbox.

    @isTest
    static void retornaListaVaziaQuandoNaoHaRecordId() {
        Test.startTest();
        List<ApprovalWorkItem> result = ApprovalWorkItemsController.getApprovalWorkItems(null);
        Test.stopTest();

        Assert.isNotNull(result, 'Deve retornar lista, nunca null');
        Assert.areEqual(0, result.size(), 'Sem recordId nao deve haver itens');
    }

    @isTest
    static void retornaListaVaziaParaOportunidadeSemAprovacao() {
        Opportunity opp = new Opportunity(
            Name      = 'Teste W0382',
            StageName = 'Em negociação',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        List<ApprovalWorkItem> result = ApprovalWorkItemsController.getApprovalWorkItems(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Deve retornar lista, nunca null');
        Assert.areEqual(0, result.size(), 'Oportunidade nova nao tem itens de aprovacao');
    }
}