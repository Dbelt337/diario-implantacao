import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Lead.Name';
import DOC_FIELD from '@salesforce/schema/Lead.NationalId__c';

const FIELDS = [NAME_FIELD, DOC_FIELD];

/**
 * Quick Action (lightning__RecordAction) que abre o OmniScript LeadListaNegra/CheckUI
 * num modal sobre o Lead.
 *
 * Carrega os dados do possivel cliente (Name -> nome, NationalId__c -> documento) e os
 * injeta via prefill, para o modal ja subir preenchido. O OmniScript faz a consulta
 * (IP LeadListaNegra_Check) e grava o status no Lead.
 *
 * No OmniStudio Standard Runtime nao existe LWC gerado por OmniScript; usa-se o
 * componente base lightning-omnistudio-omniscript (type/sub-type/language).
 */
export default class LeadListaNegraAction extends LightningElement {
    @api recordId;

    nome;
    documento;
    ready = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ data, error }) {
        if (data) {
            this.nome = getFieldValue(data, NAME_FIELD);
            this.documento = getFieldValue(data, DOC_FIELD);
        }
        // Mesmo em erro, libera o OmniScript (usuario digita os dados manualmente).
        this.ready = true;
    }

    // Seed do Data JSON do OmniScript. Os elementos Text "nome"/"documento" sobem
    // preenchidos; SetLeadId usa %ContextId%/leadId.
    get prefill() {
        return {
            ContextId: this.recordId,
            leadId: this.recordId,
            nome: this.nome,
            documento: this.documento
        };
    }
}
