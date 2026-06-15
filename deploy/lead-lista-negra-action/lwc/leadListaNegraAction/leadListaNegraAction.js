import { LightningElement, api } from 'lwc';

/**
 * Wrapper que permite usar o OmniScript LeadListaNegra/CheckUI como Quick Action
 * (botao no Highlights Panel do Lead, ao lado de Edit/Delete/Clone).
 *
 * No OmniStudio Standard Runtime nao existe um LWC gerado por OmniScript; usa-se o
 * componente base lightning-omnistudio-omniscript, identificando o script por
 * type/sub-type/language. Este wrapper tem o target lightning__RecordAction (que o
 * OmniScript sozinho nao tem) e injeta o Id do Lead via prefill.
 */
export default class LeadListaNegraAction extends LightningElement {
    // recordId e injetado automaticamente quando o LWC roda como Record Action.
    @api recordId;

    // prefill alimenta o Data JSON do OmniScript. O SetLeadId faz leadId = %ContextId%;
    // mandamos ContextId e leadId para cobrir os dois caminhos.
    get prefill() {
        return { ContextId: this.recordId, leadId: this.recordId };
    }
}
