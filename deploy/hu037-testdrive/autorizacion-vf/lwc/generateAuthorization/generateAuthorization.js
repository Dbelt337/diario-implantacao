import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import generateAuthorization
    from '@salesforce/apex/TestDriveAuthorizationCont.generateAuthorization';

/**
 * All countries. Headless quick action on the ServiceAppointment: generates
 * the test drive authorization PDF (server-side Visualforce render) and
 * opens the stored file for printing. Reception-facing (HU-037 RN 9).
 */
export default class GenerateAuthorization extends NavigationMixin(LightningElement) {
    @api recordId;
    isRunning = false;

    @api async invoke() {
        if (this.isRunning) {
            return;
        }
        this.isRunning = true;
        try {
            const contentDocumentId = await generateAuthorization({
                serviceAppointmentId: this.recordId
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Autorización generada',
                message: 'El PDF quedó en los archivos de la cita.',
                variant: 'success'
            }));
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: { pageName: 'filePreview' },
                state: { selectedRecordId: contentDocumentId }
            });
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No se pudo generar la autorización',
                message: error?.body?.message &#124;&#124; 'Error inesperado.',
                variant: 'error'
            }));
        } finally {
            this.isRunning = false;
        }
    }
}
