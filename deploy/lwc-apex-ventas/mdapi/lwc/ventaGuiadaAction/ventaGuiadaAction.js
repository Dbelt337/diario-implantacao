import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import RECORD_TYPE_NAME from '@salesforce/schema/Opportunity.RecordType.DeveloperName';

/**
 * All countries. Screen quick action for guided selling: the platform opens it
 * in a modal; the component walks the seller through the guided steps and
 * routes the business-line UI by Record Type. Thin by design — every rule and
 * callout lives in the Apex service layer.
 */
export default class VentaGuiadaAction extends LightningElement {
    _recordId;
    currentStep = 'seleccion';

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

    get isStepSeleccion() {
        return this.currentStep === 'seleccion';
    }
    get isStepPrecio() {
        return this.currentStep === 'precio';
    }
    get isStepCotizacion() {
        return this.currentStep === 'cotizacion';
    }
    get isFirstStep() {
        return this.currentStep === 'seleccion';
    }
    get isLastStep() {
        return this.currentStep === 'cotizacion';
    }

    handleNext() {
        if (this.currentStep === 'seleccion') {
            this.currentStep = 'precio';
        } else if (this.currentStep === 'precio') {
            this.currentStep = 'cotizacion';
        }
    }

    handleBack() {
        if (this.currentStep === 'cotizacion') {
            this.currentStep = 'precio';
        } else if (this.currentStep === 'precio') {
            this.currentStep = 'seleccion';
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
