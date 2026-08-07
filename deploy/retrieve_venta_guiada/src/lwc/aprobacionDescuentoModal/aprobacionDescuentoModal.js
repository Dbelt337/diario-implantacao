import { api } from 'lwc';
import LightningModal from 'lightning/modal';

/**
 * All countries. Stacked modal opened from the guided-selling discount step
 * when the requested discount goes below the minimum price. Presentation
 * mock: shows what the seller submits for approval. Real implementation:
 * native Approval Process assigned to the branch manager; the minimum price
 * per model comes from a BRE Decision Matrix maintained by the business.
 */
export default class AprobacionDescuentoModal extends LightningModal {
    @api descuentoFmt;
    @api maxDirectoFmt;
    @api excesoFmt;

    handleEnviar() {
        this.close('enviar');
    }
    handleCancel() {
        this.close('cancelar');
    }
}