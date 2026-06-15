import { LightningElement, api } from 'lwc';

/**
 * Wrapper que permite usar o OmniScript LeadListaNegra/CheckUI como Quick Action
 * (botao no Highlights Panel do Lead, ao lado de Edit/Delete/Clone).
 *
 * O LWC gerado pelo OmniScript nao tem o target lightning__RecordAction, entao nao
 * aparece sozinho no dropdown da New Action. Este wrapper tem esse target e embute
 * o OmniScript, repassando o Id do Lead como ContextId.
 */
export default class LeadListaNegraAction extends LightningElement {
    // recordId e injetado automaticamente quando o LWC roda como Record Action.
    @api recordId;

    // Parametros entregues ao OmniScript. ContextId = Id do Lead (o SetLeadId do
    // OmniScript faz leadId = %ContextId%).
    get omniPrefill() {
        return JSON.stringify({ ContextId: this.recordId, leadId: this.recordId });
    }
}
