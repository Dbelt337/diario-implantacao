import { LightningElement, api } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import VentaGuiadaModal from 'c/ventaGuiadaModal';

/**
 * All countries. Headless quick action: opens the guided-selling experience in
 * a LARGE LightningModal. Replaces the earlier screen-action launcher (the
 * platform does not allow changing an action component type in place).
 * After the modal closes with a created quote, fires the RefreshView API
 * (RefreshEvent) so the opportunity page and its related lists show the new
 * quote without a manual reload. The event must be dispatched from THIS
 * component: the modal renders in an overlay outside the record page DOM,
 * so events fired inside it never reach the page container.
 */
export default class VentaGuiadaLauncher extends LightningElement {
    @api recordId;

    @api async invoke() {
        const result = await VentaGuiadaModal.open({
            size: 'large',
            label: 'Venta guiada',
            recordId: this.recordId
        });
        // 'cotizacion-creada' (vehiculos) or 'cotizacion-repuestos-mock' (repuestos)
        if (result && String(result).startsWith('cotizacion')) {
            this.dispatchEvent(new RefreshEvent());
        }
    }
}
