public with sharing class ApprovalWorkItemsController {

    private static final Integer MAX_ITEMS = 200;

    // NAO usar cacheable=true aqui. O LWC tem botao de atualizar e precisa
    // sempre bater no servidor; com cacheable o Lightning Data Service
    // responde do cache do cliente e o usuario ve o item de aprovacao antigo.
    @AuraEnabled
    public static List<ApprovalWorkItem> getApprovalWorkItems(Id recordId) {
        try {
            return [
                SELECT Id,
                       Name,
                       Status,
                       ReviewedBy.Name,
                       AssignedTo.Name,
                       Comments,
                       ReviewedDate
                FROM ApprovalWorkItem
                WHERE RelatedRecordId = :recordId
                ORDER BY CreatedDate DESC
                LIMIT :MAX_ITEMS
            ];
        } catch (Exception e) {
            // Antes o erro era engolido e a tabela aparecia vazia, o que e
            // indistinguivel de "nao ha aprovacao pendente". Agora propaga.
            // setMessage e obrigatorio: sem ele o LWC recebe apenas
            // "Script-thrown exception" no lugar da mensagem real.
            String msg = 'Erro ao buscar itens de trabalho de aprovacao: ' + e.getMessage();
            AuraHandledException ex = new AuraHandledException(msg);
            ex.setMessage(msg);
            throw ex;
        }
    }
}