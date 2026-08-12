import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchMaterials from '@salesforce/apex/GuidedSellingController.searchMaterials';
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

/** Espera tras la última tecla antes de ir a Apex (evita una llamada por tecla). */
const DEBOUNCE_MS = 300;
/** Mínimo de caracteres para buscar (misma regla que MaterialSearchService). */
const MIN_TERM = 3;

/**
 * All countries. HU-043 (Repuestos & PA): grid de líneas de material con
 * carga individual y masiva, verificación de disponibilidad contra SAP vía
 * MuleSoft (una llamada masiva por lote), leyenda de ubicación por línea,
 * marca de Venta Perdida y sincronización con la cotización (crear /
 * actualizar / eliminar con revalidación). SAP es el maestro del inventario:
 * este componente consulta y refleja, nunca calcula stock.
 *
 * US-021 dentro del flujo: el campo de código busca el catálogo mientras se
 * teclea (debounce + mínimo 3 caracteres); si la búsqueda no encuentra, el
 * asesor SOLICITA la creación del material sin salir de la venta guiada, y
 * al confirmarse la línea entra al grid y se consulta su disponibilidad.
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
    // búsqueda del catálogo (US-021 en el flujo)
    @track sugerencias = [];
    sinResultado = false;
    terminoBuscado = '';
    debounceTimer = null;
    // token de secuencia: descarta respuestas que llegan fuera de orden
    // (el asesor sigue tecleando mientras una búsqueda vieja viaja)
    busquedaSeq = 0;
    // US-021: alta de material (desde la búsqueda o desde la línea sinCatalogo)
    crearCodigo = null;
    crearSerie = '';
    crearVerDefault = false;
    crearOrigen = null; // 'busqueda' | 'grid'

    get mostrarCrear() { return this.crearCodigo !== null; }
    get mostrarSugerencias() { return this.sugerencias.length > 0; }
    get mostrarSinResultado() { return this.sinResultado && !this.mostrarCrear; }

    get hayLineas() { return this.lineas.length > 0; }
    get sinLineas() { return !this.hayLineas; }
    get consultarDisabled() { return this.isLoading || !this.hayLineas; }

    disconnectedCallback() {
        clearTimeout(this.debounceTimer);
    }

    // ---------- búsqueda del catálogo (debounce + secuencia) ----------

    handleCodigo(event) {
        this.codigoNuevo = event.target.value;
        this.sinResultado = false;
        clearTimeout(this.debounceTimer);
        const term = (this.codigoNuevo || '').trim();
        if (term.length < MIN_TERM) {
            this.sugerencias = [];
            return;
        }
        this.debounceTimer = setTimeout(() => this.buscarCatalogo(term), DEBOUNCE_MS);
    }

    async buscarCatalogo(term) {
        const seq = ++this.busquedaSeq;
        try {
            const matches = await searchMaterials({
                searchTerm: term, companyCode: this.companyCode, plant: this.plant
            });
            if (seq !== this.busquedaSeq) { return; } // llegó tarde: ya hay otra búsqueda
            this.terminoBuscado = term;
            this.sugerencias = (matches || []).slice(0, 8);
            this.sinResultado = this.sugerencias.length === 0;
        } catch (error) {
            if (seq !== this.busquedaSeq) { return; }
            this.sugerencias = [];
            this.sinResultado = false; // error de búsqueda NO es "no existe": no ofrecer crear
            this.toast('Búsqueda no disponible', this.mensaje(error), 'warning');
        }
    }

    handleElegirSugerencia(event) {
        // mousedown (no click): dispara antes del blur del input
        this.codigoNuevo = event.currentTarget.dataset.code;
        this.sugerencias = [];
        this.sinResultado = false;
    }

    handleBusquedaBlur() {
        // deja respirar al mousedown de la sugerencia antes de cerrar la lista
        setTimeout(() => { this.sugerencias = []; }, 200);
    }

    /** US-021: la búsqueda no encontró -> solicitar creación SIN salir del flujo. */
    handleCrearDesdeBusqueda() {
        this.crearCodigo = this.terminoBuscado.toUpperCase();
        this.crearSerie = '';
        this.crearVerDefault = false;
        this.crearOrigen = 'busqueda';
        this.sinResultado = false;
    }

    // ---------- captura de líneas ----------

    handleCantidad(event) { this.cantidadNueva = event.target.value; }

    handleAgregar() {
        const code = (this.codigoNuevo || '').trim().toUpperCase();
        if (!code) { return; }
        this.upsertLinea(code, Number(this.cantidadNueva) || 1);
        this.codigoNuevo = '';
        this.cantidadNueva = 1;
        this.sugerencias = [];
        this.sinResultado = false;
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

    // ---------- US-021: crear material (búsqueda sin resultado o línea sinCatalogo) ----------

    handleAbrirCrear(event) {
        this.crearCodigo = event.target.dataset.code;
        this.crearSerie = '';
        this.crearVerDefault = false;
        this.crearOrigen = 'grid';
    }

    handleCancelarCrear() { this.crearCodigo = null; this.crearOrigen = null; }
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
                if (this.crearOrigen === 'busqueda') {
                    // el material recién creado entra como línea del grid y
                    // sigue el camino normal: consulta -> guardar
                    this.upsertLinea(this.crearCodigo, Number(this.cantidadNueva) || 1);
                    this.codigoNuevo = '';
                    this.cantidadNueva = 1;
                }
                this.crearCodigo = null;
                this.crearOrigen = null;
                this.refrescarVista();
                await this.handleConsultar(); // la línea deja de estar sinCatalogo
            } else {
                // rechazo SAP: Case levantado al área (US-021)
                const nota = r.caseId ? ' Se levantó un caso al área.' : '';
                this.toast('SAP rechazó la creación', `${r.mensaje}${nota}`, 'warning');
                this.crearCodigo = null;
                this.crearOrigen = null;
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
