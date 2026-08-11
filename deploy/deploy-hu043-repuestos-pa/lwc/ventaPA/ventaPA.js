import { LightningElement, api } from 'lwc';

/**
 * All countries. Thin business-line UI (Venta de Productos de Acabado,
 * HU-043): mismo grid reutilizable c-lineas-repuestos que Contraventa de
 * Repuestos — la linea PA comparte seleccion, carga masiva y verificacion
 * de disponibilidad (SapMuleClient/RepuestosLineService).
 */
export default class VentaPA extends LightningElement {
    @api recordId;
    @api companyCode;
    @api plant;
    @api pricebookId;
    @api currencyIsoCode;

    handleLineasGuardadas(event) {
        this.dispatchEvent(new CustomEvent('lineasguardadas', { detail: event.detail }));
    }
}
