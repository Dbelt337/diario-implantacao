import { api } from 'lwc';
import LightningModal from 'lightning/modal';

/**
 * All countries. Stacked confirmation modal opened from the guided-selling
 * flow: secondary decision without leaving the main modal (pattern for the
 * "opens further modals" steps of the experience). The total shown comes
 * from the parent (reference total minus applied discount).
 */
export default class QuoteConfirmModal extends LightningModal {
    @api totalFmt;

    handleConfirm() {
        this.close('confirmar');
    }
    handleCancel() {
        this.close('cancelar');
    }
}
