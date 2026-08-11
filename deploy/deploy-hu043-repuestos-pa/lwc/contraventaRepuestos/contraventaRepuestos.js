import { LightningElement, api } from 'lwc';

/**
 * All countries. Thin business-line UI (Contraventa de Repuestos, HU-043):
 * delega la seleccion/carga/modificacion de lineas y la verificacion de
 * disponibilidad en c-lineas-repuestos (grid reutilizable). La capa de
 * servicio Apex es RepuestosLineService via GuidedSellingController.
 */
export default class ContraventaRepuestos extends LightningElement {
    @api recordId;
    @api companyCode;
    @api plant;
    @api pricebookId;
    @api currencyIsoCode;

    handleLineasGuardadas(event) {
        // reemite hacia el host (ventaGuiadaModal) para avanzar de paso
        this.dispatchEvent(new CustomEvent('lineasguardadas', { detail: event.detail }));
    }
}
