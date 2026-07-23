import { LightningElement, api } from 'lwc';
import VentaGuiadaModal from 'c/ventaGuiadaModal';

/**
 * All countries. Headless quick action: opens the guided-selling experience in
 * a LARGE LightningModal (modern modal API) so the flow has real screen space.
 * The step-by-step lives in ventaGuiadaModal; secondary confirmations open as
 * stacked modals from inside it.
 */
export default class VentaGuiadaAction extends LightningElement {
    @api recordId;

    @api invoke() {
        VentaGuiadaModal.open({
            size: 'large',
            label: 'Venta guiada',
            recordId: this.recordId
        });
    }
}
