import { LightningElement, api } from 'lwc';

/**
 * Quick Action (lightning__RecordAction) que abre el OmniScript GrupoQ/CrearCotizacion
 * en un modal sobre la Cuenta (Persona Natural o Business) o la Oportunidad.
 *
 * El OmniScript resuelve el contexto por el prefijo del Id (001 Cuenta / 006 Oportunidad),
 * asi que basta con inyectar ContextId = recordId via prefill. El mismo wrapper sirve para
 * ambos objetos, sin imports de campos especificos.
 *
 * OmniStudio Standard Runtime: se embebe con el componente base
 * lightning-omnistudio-omniscript (type/sub-type/language), igual que leadListaNegraAction.
 */
export default class CrearCotizacionAction extends LightningElement {
    @api recordId;

    // Seed del Data JSON del OmniScript: la Integration Procedure Action usa %ContextId%.
    get prefill() {
        return {
            ContextId: this.recordId
        };
    }
}
