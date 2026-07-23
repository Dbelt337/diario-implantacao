import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import RECORD_TYPE_NAME from '@salesforce/schema/Opportunity.RecordType.DeveloperName';

/**
 * All countries. Parent screen action for guided selling: routes to the
 * business-line child component by Record Type and context. Thin by design —
 * every rule and callout lives in the Apex service layer.
 */
export default class VentaGuiadaAction extends LightningElement {
    _recordId;

    // recordId arrives via setter, not in connectedCallback (GUIA note)
    @api
    set recordId(value) {
        this._recordId = value;
    }
    get recordId() {
        return this._recordId;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [RECORD_TYPE_NAME] })
    record;

    get recordTypeDeveloperName() {
        return getFieldValue(this.record.data, RECORD_TYPE_NAME);
    }

    get isVentaVehiculo() {
        return this.recordTypeDeveloperName === 'VentaVehiculo';
    }
    get isVentaUsados() {
        return this.recordTypeDeveloperName === 'VentaUsados';
    }
    get isContraventaRepuestos() {
        return this.recordTypeDeveloperName === 'ContraventaRepuestos';
    }
    get isVentaPA() {
        return this.recordTypeDeveloperName === 'VentaPA';
    }
}
