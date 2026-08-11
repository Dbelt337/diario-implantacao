import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkRepuestosAvailability from '@salesforce/apex/GuidedSellingController.checkRepuestosAvailability';
import saveRepuestosLines from '@salesforce/apex/GuidedSellingController.saveRepuestosLines';
import revalidateRepuestosLines from '@salesforce/apex/GuidedSellingController.revalidateRepuestosLines';
import createSapMaterial from '@salesforce/apex/GuidedSellingController.createSapMaterial';

const BADGE = {
    'Disponible': 'slds-badge slds-theme_success',
    'Parcial': 'slds-badge slds-theme_warning',
    'Otro Centro': 'slds-badge',
    'Otra Sociedad': 'slds-badge',
    'No Disponible': 'slds-badge slds-theme_error'
};

/**
 * All countries. HU-043 (Repuestos & PA): grid de líneas de material con
 * carga individual y masiva, verificación de disponibilidad contra SAP vía
 * MuleSoft (una llamada masiva por lote), leyenda de ubicación por línea,
 * marca de Venta Perdida y sincronización con la cotización (crear /
 * actualizar / eliminar con revalidación). SAP es el maestro del inventario:
 * este componente consulta y refleja, nunca calcula stock.
 */
export default class LineasRepuestos extends LightningElement {
    /** Cotización destino (record page de Quote o host de la venta guiada). */
    @api recordId;
    /** Sociedad, centro y canal del contexto comercial. */
    @api companyCode = 'C101';
    @api plant;
    @api canal = 'Q1';
    /** Pricebook/moneda de la cotización (el host los conoce; opcionales en record page). */
    @api pricebookId;
    @api currencyIsoCode;

    @track lineas = [];
    codigoNuevo = '';
    cantidadNueva = 1;
    cargaMasiva = '';
    mostrarMasiva = false;
    isLoading = false;
    // US-021: alta de material para la línea sinCatalogo
    crearCodigo = null;
    crearSerie = '';
    crearVerDefault = false;

    get mostrarCrear() { return this.crearCodigo !== null; }

    get hayLineas() { return this.lineas.length > 0; }
    get sinLineas() { return !this.hayLineas; }
    get consultarDisabled() { return this.isLoading || !this.hayLineas; }

    // ---------- captura de líneas ----------

    handleCodigo(event) { this.codigoNuevo = event.target.value; }
    handleCantidad(event) { this.cantidadNueva = event.target.value; }

    handleAgregar() {
        const code = (this.codigoNuevo || '').trim().toUpperCase();
        if (!code) { return; }
        this.upsertLinea(code, Number(this.cantidadNueva) || 1);
        this.codigoNuevo = '';
        this.cantidadNueva = 1;
        this.refrescarVista();
    }

    toggleMasiva() { this.mostrarMasiva = !this.mostrarMasiva; }
    handleMasivaInput(event) { this.cargaMasiva = event.target.value; }

    /** Carga masiva (GQ-PV-02-001-4): una línea por renglón, "CODIGO, CANTIDAD". */
    handleMasivaCargar() {
        (this.cargaMasiva || '').split('\n').forEach((renglon) => {
            const partes = renglon.split(/[,;\t]/).map((p) => p.trim());
            if (!partes[0]) { return; }
            this.upsertLinea(partes[0].toUpperCase(), Number(partes[1]) || 1);
        });
        this.cargaMasiva = '';
        this.mostrarMasiva = false;
        this.refrescarVista();
    }

    upsertLinea(productCode, cantidad) {
        const existente = this.lineas.find((l) => l.productCode === productCode);
        if (existente) {
            existente.cantidad = cantidad;
            existente.status = null; // cambio => requiere revalidación (GQ-PV-02-019)
        } else {
            this.lineas.push({ productCode, cantidad, ventaPerdida: false });
        }
    }

    handleCantidadLinea(event) {
        const code = event.target.dataset.code;
        const linea = this.lineas.find((l) => l.productCode === code);
        if (linea) {
            linea.cantidad = Number(event.target.value) || 1;
            linea.status = null; // modificación dinámica: se revalida
        }
        this.refrescarVista();
    }

    handleQuitar(event) {
        const code = event.target.dataset.code;
        this.lineas = this.lineas.filter((l) => l.productCode !== code);
        this.refrescarVista();
    }

    /** La línea sin stock no se excluye: el asesor decide (RN5 de la HU). */
    handleVentaPerdida(event) {
        const code = event.target.dataset.code;
        const linea = this.lineas.find((l) => l.productCode === code);
        if (linea) { linea.ventaPerdida = !linea.ventaPerdida; }
        this.refrescarVista();
    }

    // ---------- disponibilidad ----------

    async handleConsultar() {
        this.isLoading = true;
        try {
            const resultado = await checkRepuestosAvailability({
                requestJson: JSON.stringify({
                    companyCode: this.companyCode,
                    plant: this.plant,
                    pricebookId: this.pricebookId,
                    currencyIsoCode: this.currencyIsoCode,
                    lineas: this.lineas.map((l) => ({ productCode: l.productCode, cantidad: l.cantidad }))
                })
            });
            const porCodigo = new Map(resultado.map((r) => [r.productCode, r]));
            this.lineas = this.lineas.map((l) => {
                const r = porCodigo.get(l.productCode) || {};
                return { ...l, ...r, ventaPerdida: l.ventaPerdida };
            });
            this.refrescarVista();
        } catch (error) {
            // Esc.7: SAP/Mule sin respuesta => no se confirma disponibilidad
            this.toast('Disponibilidad no confirmada', this.mensaje(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleGuardar() {
        if (!this.recordId) {
            this.toast('Sin cotización', 'Este componente necesita una cotización destino (recordId).', 'warning');
            return;
        }
        this.isLoading = true;
        try {
            const r = await saveRepuestosLines({
                quoteId: this.recordId,
                lineasJson: JSON.stringify(this.lineas.map((l) => ({
                    productCode: l.productCode,
                    cantidad: l.cantidad,
                    status: l.status,
                    detalle: l.textoExistencia,
                    ventaPerdida: l.ventaPerdida === true
                })))
            });
            let detalle = `${r.creadas} creadas · ${r.actualizadas} actualizadas · ${r.eliminadas} eliminadas`;
            if (r.ventasPerdidas > 0) { detalle += ` · ${r.ventasPerdidas} venta(s) perdida(s) trazada(s)`; }
            if (r.sinCatalogo && r.sinCatalogo.length) {
                detalle += ` · sin catálogo (crear código, US-021): ${r.sinCatalogo.join(', ')}`;
            }
            this.toast('Líneas sincronizadas', detalle, r.sinCatalogo && r.sinCatalogo.length ? 'warning' : 'success');
            this.dispatchEvent(new CustomEvent('lineasguardadas', { detail: r }));
        } catch (error) {
            this.toast('No fue posible guardar', this.mensaje(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleRevalidar() {
        if (!this.recordId) { return; }
        this.isLoading = true;
        try {
            const resultado = await revalidateRepuestosLines({
                quoteId: this.recordId, companyCode: this.companyCode, plant: this.plant
            });
            const porCodigo = new Map(resultado.map((r) => [r.productCode, r]));
            this.lineas = this.lineas.map((l) => {
                const r = porCodigo.get(l.productCode) || {};
                return { ...l, ...r, ventaPerdida: l.ventaPerdida };
            });
            this.refrescarVista();
            this.toast('Disponibilidad revalidada', 'Las líneas reflejan la existencia actual de SAP.', 'success');
        } catch (error) {
            this.toast('Disponibilidad no confirmada', this.mensaje(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------- US-021: crear material (línea sinCatalogo) ----------

    handleAbrirCrear(event) {
        this.crearCodigo = event.target.dataset.code;
        this.crearSerie = '';
        this.crearVerDefault = false;
    }

    handleCancelarCrear() { this.crearCodigo = null; }
    handleCrearSerie(event) { this.crearSerie = event.target.value; }
    handleCrearVerDefault(event) { this.crearVerDefault = event.target.checked; }

    async handleConfirmarCrear() {
        if (!this.crearSerie) {
            this.toast('Serie requerida', 'Los materiales ZREP exigen serie (regla SAP).', 'warning');
            return;
        }
        this.isLoading = true;
        try {
            const r = await createSapMaterial({
                requestJson: JSON.stringify({
                    material: this.crearCodigo,
                    sociedad: this.companyCode,
                    canal: this.canal,
                    serie: this.crearSerie,
                    verDefault: this.crearVerDefault,
                    pricebookId: this.pricebookId,
                    currencyIsoCode: this.currencyIsoCode
                })
            });
            if (r.ok) {
                this.toast('Material creado en SAP', r.mensaje, 'success');
                this.crearCodigo = null;
                await this.handleConsultar(); // la línea deja de estar sinCatalogo
            } else {
                // rechazo SAP: Case levantado al área (US-021)
                const nota = r.caseId ? ' Se levantó un caso al área.' : '';
                this.toast('SAP rechazó la creación', `${r.mensaje}${nota}`, 'warning');
                this.crearCodigo = null;
            }
        } catch (error) {
            this.toast('No fue posible crear el material', this.mensaje(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ---------- presentación ----------

    refrescarVista() {
        this.lineas = this.lineas.map((l) => ({
            ...l,
            badgeClass: l.ventaPerdida ? 'slds-badge slds-theme_error' : (BADGE[l.status] || 'slds-badge slds-badge_lightest'),
            statusLabel: l.ventaPerdida ? 'Venta Perdida' : (l.status || 'Sin consultar'),
            saldoLabel: l.saldoDisponible === undefined || l.saldoDisponible === null
                ? '—' : `${l.saldoDisponible} (piso ${l.piso} / reserva ${l.reserva})`,
            perdidaVariant: l.ventaPerdida ? 'brand' : 'neutral',
            mostrarCrearMaterial: l.sinCatalogo === true,
            rowClass: l.sinCatalogo ? 'slds-hint-parent fila-sin-catalogo' : 'slds-hint-parent'
        }));
    }

    mensaje(error) {
        return (error && error.body && error.body.message) || 'Error inesperado. Intente de nuevo.';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
