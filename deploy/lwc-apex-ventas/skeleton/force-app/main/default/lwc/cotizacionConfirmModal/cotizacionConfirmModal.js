import LightningModal from 'lightning/modal';

/**
 * All countries. Stacked confirmation modal opened from the guided-selling
 * flow: secondary decision without leaving the main modal (pattern for the
 * "opens further modals" steps of the experience).
 */
export default class CotizacionConfirmModal extends LightningModal {
    handleConfirm() {
        this.close('confirmar');
    }
    handleCancel() {
        this.close('cancelar');
    }
}
