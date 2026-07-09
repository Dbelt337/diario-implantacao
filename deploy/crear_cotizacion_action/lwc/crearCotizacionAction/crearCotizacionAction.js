import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

/**
 * Quick Action HEADLESS (lightning__RecordAction, actionType Action): al hacer clic,
 * navega a la featurePage del OmniScript GrupoQ/CrearCotizacion en pagina completa,
 * pasando el recordId como omniscript__recordId (la plataforma lo entrega como ContextId).
 *
 * Sin modal y sin embed: cero race de prefill. Sirve para Account y Opportunity
 * (el OmniScript resuelve 001/006 por el prefijo del Id).
 */
export default class CrearCotizacionAction extends NavigationMixin(LightningElement) {
    @api recordId;

    @api invoke() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url:
                    '/lightning/page/omnistudio/omniscript' +
                    '?omniscript__type=GrupoQ' +
                    '&omniscript__subType=CrearCotizacion' +
                    '&omniscript__language=English' +
                    '&omniscript__recordId=' + this.recordId
            }
        });
    }
}
