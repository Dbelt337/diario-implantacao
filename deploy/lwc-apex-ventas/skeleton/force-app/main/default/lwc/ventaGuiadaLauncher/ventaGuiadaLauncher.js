import { LightningElement, api } from 'lwc';
import VentaGuiadaModal from 'c/ventaGuiadaModal';

/**
 * All countries. Headless quick action: opens the guided-selling experience in
 * a LARGE LightningModal. Replaces the earlier screen-action launcher (the
 * platform does not allow changing an action component type in place).
 */
export default class VentaGuiadaLauncher extends LightningElement {
    @api recordId;

    @api invoke() {
        VentaGuiadaModal.open({
            size: 'large',
            label: 'Venta guiada',
            recordId: this.recordId
        });
    }
}
