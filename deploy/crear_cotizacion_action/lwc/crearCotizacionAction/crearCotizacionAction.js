import { LightningElement, api } from 'lwc';

/**
 * Quick Action (lightning__RecordAction) que abre el OmniScript GrupoQ/CrearCotizacion
 * en un modal sobre la Cuenta (Persona Natural o Business) o la Oportunidad.
 *
 * IMPORTANTE (mismo patron que leadListaNegraAction): el OmniScript se renderiza SOLO
 * cuando recordId ya esta poblado (get ready). Sin ese gate, el OmniScript inicializa
 * antes de que el framework inyecte recordId y el prefill sube con ContextId vacio.
 *
 * El OmniScript resuelve el contexto por el prefijo del Id (001 Cuenta / 006 Oportunidad),
 * asi que basta ContextId = recordId. El mismo wrapper sirve para ambos objetos.
 */
export default class CrearCotizacionAction extends LightningElement {
    @api recordId;

    // Renderiza el OmniScript solo con recordId presente (evita ContextId vacio).
    get ready() {
        return !!this.recordId;
    }

    // Seed del Data JSON del OmniScript: la Integration Procedure Action usa %ContextId%.
    get prefill() {
        return {
            ContextId: this.recordId
        };
    }
}
