import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GRUPOQ_LOGO from '@salesforce/resourceUrl/GrupoQLogo';
import hasViewInventoryQuantities from '@salesforce/customPermission/ViewInventoryQuantities';
import CotizacionConfirmModal from 'c/cotizacionConfirmModal';
import AprobacionDescuentoModal from 'c/aprobacionDescuentoModal';

import createQuote from '@salesforce/apex/GuidedSellingController.createQuote';
import getFinancingOptions from '@salesforce/apex/GuidedSellingController.getFinancingOptions';

/**
 * All countries. Large modal with the guided-selling step-by-step. CURRENT
 * STATE: presentation mock (simulated data) showing the target experience;
 * each step gets wired to its Apex service through GuidedSellingController.
 * NEW vs USED split: new-vehicle price/stock come from SAP via MuleSoft
 * (live query); used-vehicle inventory and price are OWNED by Salesforce.
 * Accessories: additional quote lines from the sociedad price book
 * ("Vehiculos y accesorios"); model compatibility pending business input.
 * Future-order states (stock / in transit / none) drive the final button
 * label per the no-stock quotation user story.
 * MULTI-VEHICLE (prototipo Gaston 31/07): the seller picks one or MORE
 * vehicles; the accessories step shows a vertical tab per vehicle with its
 * compatible catalog and a right panel summarizing the selection. One
 * native quote per vehicle at the end (QuoteOrderService already loops).
 */

const STEPS = ['tipo', 'seleccion', 'accesorios', 'precio', 'descuento', 'pago', 'cotizacion'];
// Repuestos y PA: sin paso de accesorios (los repuestos SON las lineas)
const STEPS_REPUESTOS = ['tipo', 'seleccion', 'precio', 'descuento', 'pago', 'cotizacion'];

const STEP_TITULOS = {
    tipo: '¿Qué vas a vender?',
    seleccion: 'Selección de vehículos',
    accesorios: 'Accesorios',
    precio: 'Precio y stock',
    descuento: 'Descuentos',
    pago: 'Forma de pago',
    cotizacion: 'Cotización'
};

const STEP_TITULOS_REPUESTOS = {
    tipo: '¿Qué vas a vender?',
    seleccion: 'Selección de repuestos',
    precio: 'Precio en línea (SAP)',
    descuento: 'Descuentos',
    pago: 'Forma de pago',
    cotizacion: 'Cotización'
};

/**
 * Router por Record Type de la Opportunity: mapa deterministico por
 * DeveloperName (inmune a traduccion de labels). Tipos NO mapeados bloquean
 * la venta guiada con un aviso amigable en lugar de caer en "nuevo".
 */
const TIPO_POR_RECORD_TYPE = {
    GQOpportunitiesAutos: 'nuevo',
    GQOpportunitiesMotos: 'nuevo',
    GQOpportunitiesUsados: 'usado',
    GQOpportunitiesRepuestosPA: 'repuestos'
    // GQOpportunitiesFlotas: 'nuevo', // RELEASE 2 - no entregar en R1 (decision 04/08/2026)
    // GQOpportunitiesMayorista: ...,  // experiencia pendiente de definicion de negocio
};

const VIGENCIA_DIAS = 15;

// ------- parametros SIMULADOS (los reemplazan BRE / frente financiera) -------
const MAX_DESCUENTO_DIRECTO = 700000;
const TASA_ANUAL_REFERENCIA = 9.5;

/**
 * Moneda de la cotizacion = moneda de la Opportunity (multimoneda nativa: la
 * Quote hereda la moneda de la oportunidad y cada moneda tiene su propia
 * PricebookEntry). Los precios MOCK estan en CRC; para demo en USD se
 * convierten con la tasa de la org. REAL: sin conversion en la UI — el
 * precio por moneda viene de su PricebookEntry (via GuidedSellingController).
 */
const TASAS_MOCK = { CRC: 1, USD: 0.00196 };

function moneda(value, iso) {
    const tasa = TASAS_MOCK[iso] || 1;
    const n = Math.round((value || 0) * tasa);
    const sign = n < 0 ? '- ' : '';
    return sign + iso + ' ' + Math.abs(n).toLocaleString('de-DE');
}

export default class VentaGuiadaModal extends LightningModal {
    @api recordId;

    currentStep = 'tipo';
    ventaTipo = '';
    tipoAutomatico = false;
    recordTypeNombre = '';
    monedaIso = 'CRC';
    selectedVehicles = [];
    activeVehicleId;
    searchTerm = '';
    filtroMarca = '';
    filtroAnio = '';
    // Repuestos: seleccion { partId: true } y cantidades { partId: n }
    repuestosSel = {};
    repuestosCant = {};
    // Record type fuera del alcance R1 (Flotas/Mayorista): bloquea el paso tipo
    ventaNoDisponible = false;

    /**
     * Router por Record Type: lee el record type de la Opportunity via UI API
     * (data.recordTypeInfo, sin campos adicionales) y resuelve el tipo de
     * venta, saltando el paso "tipo". Si el record type no identifica la
     * linea, la pantalla de tipo se muestra normalmente.
     */
    @wire(getRecord, { recordId: '$recordId', fields: ['Opportunity.Name', 'Opportunity.CurrencyIsoCode', 'Opportunity.RecordType.DeveloperName'] })
    wiredOpp({ data }) {
        if (!data) return;
        // moneda de la cotizacion = moneda de la Opportunity (multimoneda)
        this.monedaIso = data.fields?.CurrencyIsoCode?.value || 'CRC';
        if (this.ventaTipo) return;
        this.recordTypeNombre = data.recordTypeInfo?.name || '';
        const devName = data.fields?.RecordType?.value?.fields?.DeveloperName?.value || '';
        const tipo = TIPO_POR_RECORD_TYPE[devName];
        if (devName && !tipo && this.currentStep === 'tipo') {
            // Flotas (R2) / Mayorista (sin definicion): bloquear con aviso
            this.ventaNoDisponible = true;
            return;
        }
        if (tipo && this.currentStep === 'tipo') {
            this.setTipo(tipo);
            this.tipoAutomatico = true;
            this.currentStep = 'seleccion';
        }
    }

    /** Formatea un monto (mock en CRC) en la moneda de la oportunidad. */
    m(value) {
        return moneda(value, this.monedaIso);
    }
    get monedaBadge() {
        return `Moneda: ${this.monedaIso}`;
    }

    // paso Descuentos
    descuento = 0;
    descuentoAprobado = false;

    // paso Pago
    formaPago = '';
    prima;
    plazo = '60';
    // Financiamiento (CrediQ): opciones devueltas por la frente financiera y
    // la eleccion del cliente. Cambiar prima/plazo INVALIDA las opciones
    // cargadas (oferta calculada sobre otro monto) — se vuelven a consultar.
    financingOptions = [];
    financingLoading = false;
    selectedFinancingId = '';

    // ------- datos SIMULADOS (los reemplazan los servicios Apex) -------
    vehiclesNuevos = [
        { id: 'V1', marca: 'Hyundai', modelo: 'Hyundai Tucson GLS 2.0', anio: '2026',
          color: 'Blanco Polar', colorInt: 'Negro',
          precio: 'CRC 21.500.000', precioNum: 21500000, stockCentral: 3, stockDealer: 1 },
        { id: 'V2', marca: 'Hyundai', modelo: 'Hyundai Tucson Limited', anio: '2026',
          color: 'Gris Titanio', colorInt: 'Beige',
          precio: 'CRC 24.900.000', precioNum: 24900000, stockCentral: 1, stockDealer: 0 },
        { id: 'V3', marca: 'Hyundai', modelo: 'Hyundai Creta GL 1.5', anio: '2026',
          color: 'Rojo Fuego', colorInt: 'Negro',
          precio: 'CRC 16.800.000', precioNum: 16800000, stockCentral: 5, stockDealer: 2 },
        { id: 'V4', marca: 'Hyundai', modelo: 'Hyundai Tucson Híbrida', anio: '2026',
          color: 'Azul Océano', colorInt: 'Gris',
          precio: 'CRC 27.900.000', precioNum: 27900000, stockCentral: 0, stockDealer: 0,
          disponibilidad: { cantidad: 2, eta: '15/09/2026', fuente: 'pedido_importacion' } },
        { id: 'V5', marca: 'Hyundai', modelo: 'Hyundai Santa Fe', anio: '2027',
          color: 'Negro Fantasma', colorInt: 'Marrón',
          precio: 'CRC 32.500.000', precioNum: 32500000, stockCentral: 0, stockDealer: 0,
          disponibilidad: { cantidad: 2, eta: '29/08/2026', fuente: 'recepcion_futura' } },
        { id: 'V6', marca: 'Chevrolet', modelo: 'Chevrolet Groove LT', anio: '2026',
          color: 'Plata Estelar', colorInt: 'Negro',
          precio: 'CRC 15.900.000', precioNum: 15900000, stockCentral: 4, stockDealer: 1 },
        { id: 'V7', marca: 'Hyundai', modelo: 'Hyundai Ioniq 6', anio: '2027',
          color: 'Blanco Lunar', colorInt: 'Negro',
          precio: 'CRC 38.900.000', precioNum: 38900000, stockCentral: 0, stockDealer: 0 }
    ];

    vehiclesUsados = [
        { id: 'U1', marca: 'Hyundai', modelo: 'Hyundai Accent 1.6', anio: '2022', km: '45.000 km',
          vin: '3KPC24...4885', precio: 'CRC 12.900.000', precioNum: 12900000, ubicacion: 'La Uruca' },
        { id: 'U2', marca: 'Hyundai', modelo: 'Hyundai Tucson GLS', anio: '2021', km: '62.000 km',
          vin: 'KM8J33...1207', precio: 'CRC 16.500.000', precioNum: 16500000, ubicacion: 'Lindora' },
        { id: 'U3', marca: 'Chevrolet', modelo: 'Chevrolet Onix LT', anio: '2023', km: '28.000 km',
          vin: '9BGKS48...3341', precio: 'CRC 11.800.000', precioNum: 11800000, ubicacion: 'La Uruca' }
    ];

    /**
     * Catalogo SIMULADO de piezas y accesorios asociado al vehiculo:
     * "modelos" lista los vehiculos demo compatibles. Real: materiales SAP
     * del pricebook "Vehiculos y accesorios" de la sociedad, filtrados por
     * la matriz de compatibilidad accesorio x modelo (insumo GrupoQ).
     */
    accesoriosCatalogo = [
        { id: 'A1', nombre: 'Juego de tapetes', categoria: 'Confort', precio: 45000,
          modelos: ['V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'U1', 'U2', 'U3'] },
        { id: 'A2', nombre: 'Rack de techo', categoria: 'Exterior', precio: 120000,
          modelos: ['V1', 'V2', 'V4', 'V5', 'U2'] },
        { id: 'A3', nombre: 'Polarizado de ventanas', categoria: 'Confort', precio: 85000,
          modelos: ['V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'U1', 'U2', 'U3'] },
        { id: 'A4', nombre: 'Kit de seguridad (triángulo + extintor)', categoria: 'Seguridad', precio: 35000,
          modelos: ['V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'U1', 'U2', 'U3'] },
        { id: 'A5', nombre: 'Estribos laterales', categoria: 'Exterior', precio: 160000,
          modelos: ['V1', 'V2', 'V4', 'V5', 'U2'] },
        { id: 'A6', nombre: 'Cámara de retroceso adicional', categoria: 'Seguridad', precio: 95000,
          modelos: ['V3', 'V6', 'U1', 'U3'] },
        { id: 'A7', nombre: 'Protector de maletero', categoria: 'Exterior', precio: 55000,
          modelos: ['V1', 'V2', 'V3', 'V4', 'V6', 'U1', 'U3'] },
        { id: 'A8', nombre: 'Sensor de parqueo delantero', categoria: 'Seguridad', precio: 110000,
          modelos: ['V3', 'V5', 'V6', 'U1', 'U3'] }
    ];
    // seleccion de accesorios POR VEHICULO: { vehicleId: { accesorioId: true } }
    accesoriosSel = {};

    gastosExtrasNuevo = [
        { id: 'p2', concepto: 'Gastos (matrícula + entrega)', valorNum: 850000 },
        { id: 'p3', concepto: 'Impuesto de referencia 13% (Decision Matrix BRE)', valorNum: 2795000 },
        { id: 'p4', concepto: 'Cashback vigente', valorNum: -500000 },
        { id: 'p5', concepto: 'Valor de trade-in (avalúo aceptado)', valorNum: -14000 }
    ];

    gastosExtrasUsado = [
        { id: 'u2', concepto: 'Gastos de traspaso', valorNum: 350000 },
        { id: 'u3', concepto: 'Impuesto de referencia 13% (Decision Matrix BRE)', valorNum: 1677000 }
    ];

    /**
     * Catalogo SIMULADO de repuestos (HU-028, Cenario 1): SAP es el maestro,
     * el precio NO se persiste en Salesforce — se consulta en linea via
     * MuleSoft (RFC Get_Price_ZGQREF) al armar la pantalla de precio. Los
     * combos son SKU propio en SAP. "sinPrecio" simula un material sin
     * respuesta de SAP (dispara la nota de solicitud de material, HU-039).
     */
    repuestosCatalogo = [
        { id: 'R1', codigo: '04465-0K340', nombre: 'Juego de pastillas de freno delanteras', marca: 'Toyota',
          precio: 42500, disponibilidad: 'Bodega Central', stock: 24 },
        { id: 'R2', codigo: '90915-YZZD4', nombre: 'Filtro de aceite', marca: 'Toyota',
          precio: 6800, disponibilidad: 'Bodega Central', stock: 120 },
        { id: 'R3', codigo: '28113-2E100', nombre: 'Filtro de aire de motor', marca: 'Hyundai',
          precio: 9400, disponibilidad: 'Sucursal Lindora', stock: 15 },
        { id: 'R4', codigo: 'COMBO-FR-TUCSON', nombre: 'Combo frenos Tucson (pastillas + discos + mano de obra)', marca: 'Hyundai',
          precio: 155000, disponibilidad: 'Bodega Central', stock: 8 },
        { id: 'R5', codigo: '25212-2W000', nombre: 'Correa de accesorios', marca: 'Hyundai',
          precio: 18700, disponibilidad: 'En tránsito', stock: 0 },
        { id: 'R6', codigo: 'ZZ-NO-SAP-001', nombre: 'Kit deflector de capó (material nuevo)', marca: 'Chevrolet',
          precio: null, disponibilidad: 'Sin código SAP', stock: 0, sinPrecio: true }
    ];

    fichaUsado = [
        { id: 'f1', etiqueta: 'VIN', valor: '3KPC24...4885' },
        { id: 'f2', etiqueta: 'Kilometraje', valor: '45.000 km (capturado en Salesforce)' },
        { id: 'f3', etiqueta: 'Dueños anteriores', valor: '1 — vendido nuevo por GrupoQ (unidad re-vinculada)' },
        { id: 'f4', etiqueta: 'Tipo de adquisición', valor: 'Trade-in (avalúo HU-036)' },
        { id: 'f5', etiqueta: 'Estado', valor: 'Disponible — La Uruca' }
    ];
    // -------------------------------------------------------------------

    // ------- navegacion -------
    get isStepTipo() { return this.currentStep === 'tipo'; }
    get isStepSeleccion() { return this.currentStep === 'seleccion'; }
    get isStepAccesorios() { return this.currentStep === 'accesorios'; }
    get isStepPrecio() { return this.currentStep === 'precio'; }
    get isStepDescuento() { return this.currentStep === 'descuento'; }
    get isStepPago() { return this.currentStep === 'pago'; }
    get isStepCotizacion() { return this.currentStep === 'cotizacion'; }
    get isFirstStep() { return this.currentStep === STEPS[0]; }

    get esNuevo() { return this.ventaTipo === 'nuevo'; }
    get esUsado() { return this.ventaTipo === 'usado'; }
    get esRepuestos() { return this.ventaTipo === 'repuestos'; }
    get esVehiculo() { return this.esNuevo || this.esUsado; }
    get stepsActuales() { return this.esRepuestos ? STEPS_REPUESTOS : STEPS; }
    // titulo por paso (acuerdo Gaston 31/07): el header del LightningModal es
    // nuestro, se actualiza con una property reactiva
    get tituloModal() {
        if (this.isStepTipo || !this.ventaTipo) return 'Venta guiada';
        if (this.esRepuestos) {
            return `Venta guiada — Repuestos y PA · ${STEP_TITULOS_REPUESTOS[this.currentStep]}`;
        }
        const base = this.esUsado ? 'Venta guiada — Vehículo usado' : 'Venta guiada — Vehículo nuevo';
        return `${base} · ${STEP_TITULOS[this.currentStep]}`;
    }
    // chip informativo cuando el tipo vino del Record Type de la Opportunity
    get leyendaTipoAutomatico() {
        return this.tipoAutomatico
            ? `Tipo definido por el registro: ${this.recordTypeNombre}`
            : '';
    }

    get nextDisabled() {
        if (this.isStepTipo) return !this.ventaTipo;
        if (this.isStepSeleccion) {
            return this.esRepuestos
                ? this.repuestosSeleccionados.length === 0
                : this.selectedVehicles.length === 0;
        }
        if (this.isStepDescuento) return this.descuentoRequiereAprobacion && !this.descuentoAprobado;
        // Financiado: el cliente debe ELEGIR una opcion de financiamiento
        if (this.isStepPago) return !this.formaPago || (this.isFinanciado && !this.selectedFinancingId);
        return this.isStepCotizacion;
    }

    handleNext() {
        const steps = this.stepsActuales;
        const i = steps.indexOf(this.currentStep);
        if (i < steps.length - 1) this.currentStep = steps[i + 1];
    }
    handleBack() {
        const steps = this.stepsActuales;
        const i = steps.indexOf(this.currentStep);
        if (i > 0) this.currentStep = steps[i - 1];
    }

    // ------- paso Tipo -------
    handleTipoNuevo() { this.setTipo('nuevo'); }
    handleTipoUsado() { this.setTipo('usado'); }
    handleTipoRepuestos() { this.setTipo('repuestos'); }
    setTipo(tipo) {
        if (this.ventaTipo !== tipo) {
            this.ventaTipo = tipo;
            this.tipoAutomatico = false;
            this.selectedVehicles = [];
            this.activeVehicleId = undefined;
            this.descuento = 0;
            this.descuentoAprobado = false;
            this.formaPago = '';
            this.prima = undefined;
            this.resetFinanciamiento();
            this.accesoriosSel = {};
            this.repuestosSel = {};
            this.repuestosCant = {};
            this.searchTerm = '';
            this.filtroMarca = '';
            this.filtroAnio = '';
        }
    }
    get tipoNuevoClass() { return this.esNuevo ? 'tipo-card tipo-card-selected' : 'tipo-card'; }
    get tipoUsadoClass() { return this.esUsado ? 'tipo-card tipo-card-selected' : 'tipo-card'; }
    get tipoRepuestosClass() { return this.esRepuestos ? 'tipo-card tipo-card-selected' : 'tipo-card'; }

    // ------- paso Vehiculos (seleccion multiple, prototipo Gaston) -------
    get vehiclesActuales() {
        return this.esUsado ? this.vehiclesUsados : this.vehiclesNuevos;
    }
    /**
     * Cantidades de inventario (HU-042 RN-03): visibles SOLO con la Custom
     * Permission ViewInventoryQuantities (asesor de piso). La disponibilidad
     * cualitativa (colores, ubicacion, transito) sigue visible para todos.
     */
    get puedeVerCantidades() {
        return !!hasViewInventoryQuantities;
    }
    get marcaOptions() {
        const marcas = [...new Set(this.vehiclesActuales.map(v => v.marca))];
        return [{ label: 'Todas las marcas', value: '' },
            ...marcas.map(m => ({ label: m, value: m }))];
    }
    get anioOptions() {
        const anios = [...new Set(this.vehiclesActuales.map(v => v.anio))].sort();
        return [{ label: 'Todos los años', value: '' },
            ...anios.map(a => ({ label: a, value: a }))];
    }
    isSelected(vehicleId) {
        return this.selectedVehicles.some(v => v.id === vehicleId);
    }
    get vehicleOptions() {
        const term = (this.searchTerm || '').toLowerCase();
        return this.vehiclesActuales
            .filter(v => (!this.filtroMarca || v.marca === this.filtroMarca)
                && (!this.filtroAnio || v.anio === this.filtroAnio)
                && (!term || `${v.modelo} ${v.color || ''} ${v.vin || ''}`.toLowerCase().includes(term)))
            .map((vehicle) => ({
                ...vehicle,
                precioFmt: this.m(vehicle.precioNum),
                rowClass: this.isSelected(vehicle.id)
                    ? 'slds-hint-parent selected-row'
                    : 'slds-hint-parent'
            }));
    }
    get leyendaSeleccion() {
        const base = 'Selecciona una o más filas (clic marca y desmarca).';
        return this.esUsado
            ? base + ' (Real: inventario PROPIO en Vehicle — SOQL directo, sin SAP. Ficha del usado de la historia de inventario de usados.)'
            : base + ' (Real: busqueda sobre el CODIGO ACTIVO — Product2.IsActive — via MaterialSearchService; se cotiza aun sin existencia. Stock 0 con tránsito o sin unidades cambia el botón final.)';
    }
    handleSearchChange(event) {
        // TODO real: GuidedSellingController.getSelectionPageData con debounce
        this.searchTerm = event.target.value;
    }
    handleFiltroMarca(event) { this.filtroMarca = event.detail.value; }
    handleFiltroAnio(event) { this.filtroAnio = event.detail.value; }
    // clic alterna el vehiculo dentro/fuera de la seleccion; quitarlo limpia
    // sus accesorios (el catalogo compatible es por vehiculo)
    handleSelectVehicle(event) {
        const id = event.currentTarget.dataset.id;
        if (this.isSelected(id)) {
            this.selectedVehicles = this.selectedVehicles.filter(v => v.id !== id);
            const sel = { ...this.accesoriosSel };
            delete sel[id];
            this.accesoriosSel = sel;
            if (this.activeVehicleId === id) {
                this.activeVehicleId = this.selectedVehicles[0]?.id;
            }
        } else {
            const vehicle = this.vehiclesActuales.find(v => v.id === id);
            this.selectedVehicles = [...this.selectedVehicles, vehicle];
            if (!this.activeVehicleId) this.activeVehicleId = id;
        }
    }

    // ------- barra de marca (logo + contexto de la seleccion) -------
    get logoUrl() { return GRUPOQ_LOGO; }
    get tieneVehiculo() {
        return this.esRepuestos ? this.repuestosSeleccionados.length > 0 : this.selectedVehicles.length > 0;
    }
    get vehiculoChip() {
        if (this.esRepuestos) {
            const n = this.repuestosSeleccionados.length;
            return n === 0 ? '' : `${n} repuesto${n > 1 ? 's' : ''} — ${this.repuestosTotalFmt}`;
        }
        const n = this.selectedVehicles.length;
        if (n === 0) return '';
        if (n === 1) {
            const v = this.selectedVehicles[0];
            return this.esUsado ? `${v.modelo} ${v.anio} — VIN ${v.vin}` : `${v.modelo} ${v.anio}`;
        }
        return `${n} vehículos seleccionados`;
    }

    // ------- paso Seleccion (Repuestos y PA) -------
    cantidadDe(partId) {
        const n = parseInt(this.repuestosCant[partId], 10);
        return Number.isFinite(n) && n > 0 ? n : 1;
    }
    get repuestosOptions() {
        const term = (this.searchTerm || '').toLowerCase();
        return this.repuestosCatalogo
            .filter(r => !term || `${r.codigo} ${r.nombre} ${r.marca}`.toLowerCase().includes(term))
            .map(r => ({
                ...r,
                sel: !!this.repuestosSel[r.id],
                precioFmt: r.sinPrecio ? 'Consultar SAP' : this.m(r.precio),
                rowClass: this.repuestosSel[r.id] ? 'slds-hint-parent selected-row' : 'slds-hint-parent'
            }));
    }
    get repuestosSeleccionados() {
        return this.repuestosCatalogo
            .filter(r => this.repuestosSel[r.id])
            .map(r => {
                const cantidad = this.cantidadDe(r.id);
                const subtotal = r.sinPrecio ? 0 : r.precio * cantidad;
                return { ...r, cantidad, subtotal,
                    precioFmt: r.sinPrecio ? '—' : this.m(r.precio),
                    subtotalFmt: r.sinPrecio ? 'Pendiente SAP' : this.m(subtotal) };
            });
    }
    get repuestosTotal() {
        return this.repuestosSeleccionados.reduce((sum, r) => sum + r.subtotal, 0);
    }
    get repuestosTotalFmt() { return this.m(this.repuestosTotal); }
    get tieneRepuestoSinPrecio() {
        return this.repuestosSeleccionados.some(r => r.sinPrecio);
    }
    handleToggleRepuesto(event) {
        const id = event.currentTarget.dataset.id;
        this.repuestosSel = { ...this.repuestosSel, [id]: !this.repuestosSel[id] };
    }
    handleCantidadChange(event) {
        const id = event.currentTarget.dataset.id;
        this.repuestosCant = { ...this.repuestosCant, [id]: event.detail.value };
    }

    // ------- paso Accesorios (tab vertical por vehiculo + panel derecho) -------
    accesoriosDeVehiculo(vehicleId) {
        return this.accesoriosCatalogo.filter(a => a.modelos.includes(vehicleId));
    }
    accesoriosSeleccionadosDe(vehicleId) {
        const sel = this.accesoriosSel[vehicleId] || {};
        return this.accesoriosDeVehiculo(vehicleId).filter(a => sel[a.id]);
    }
    totalAccesoriosDe(vehicleId) {
        return this.accesoriosSeleccionadosDe(vehicleId).reduce((sum, a) => sum + a.precio, 0);
    }
    /**
     * Catalogo del vehiculo ACTIVO (variante Davi 31/07: todo en una
     * pantalla — los cards de la izquierda seleccionan, el catalogo de la
     * derecha muestra el compatible del card activo).
     */
    get vehiculoActivo() {
        const id = this.activeVehicleId || this.selectedVehicles[0]?.id;
        const v = this.selectedVehicles.find(x => x.id === id);
        if (!v) return undefined;
        const sel = this.accesoriosSel[v.id] || {};
        const cats = [];
        this.accesoriosDeVehiculo(v.id).forEach(a => {
            const item = { ...a, precioFmt: this.m(a.precio), sel: !!sel[a.id],
                rowClass: sel[a.id] ? 'line-row acc-row acc-row-sel' : 'line-row acc-row' };
            let cat = cats.find(c => c.nombre === a.categoria);
            if (!cat) {
                cat = { nombre: a.categoria, items: [] };
                cats.push(cat);
            }
            cat.items.push(item);
        });
        return {
            ...v,
            titulo: `Catálogo compatible con ${v.modelo}`,
            categorias: cats,
            totalFmt: this.m(this.totalAccesoriosDe(v.id))
        };
    }
    /** Panel derecho del prototipo: resumen de los vehiculos seleccionados. */
    get vehiculosPanel() {
        const ESTADO_CLASE = {
            'Disponible': 'ok', 'En tránsito': 'transito',
            'Recepción futura': 'futura', 'Sin stock': 'sin'
        };
        return this.selectedVehicles.map(v => {
            const stock = (v.stockCentral || 0) + (v.stockDealer || 0);
            let badge = 'Disponible';
            if (this.esNuevo && stock === 0) {
                badge = v.disponibilidad?.cantidad
                    ? (v.disponibilidad.fuente === 'recepcion_futura' ? 'Recepción futura' : 'En tránsito')
                    : 'Sin stock';
            }
            const estado = ESTADO_CLASE[badge];
            const activo = v.id === (this.activeVehicleId || this.selectedVehicles[0]?.id);
            return {
                id: v.id,
                titulo: `${v.anio} - ${v.modelo}`,
                precio: this.m(v.precioNum),
                stock: this.esUsado ? v.ubicacion : String(stock).padStart(2, '0'),
                stockLabel: this.esUsado ? 'Ubicación' : 'Stock',
                color: v.color || '-',
                badge,
                activo,
                badgeClass: 'veh-badge badge-' + estado,
                cardClass: 'veh-card veh-card-' + estado + (activo ? ' veh-card-activa' : ''),
                accesoriosFmt: this.m(this.totalAccesoriosDe(v.id))
            };
        });
    }
    handleCardClick(event) {
        this.activeVehicleId = event.currentTarget.dataset.id;
    }
    get tituloPanelVehiculos() {
        return `Vehículos seleccionados (${this.selectedVehicles.length})`;
    }
    get accesoriosTotal() {
        return this.selectedVehicles.reduce((sum, v) => sum + this.totalAccesoriosDe(v.id), 0);
    }
    get accesoriosTotalFmt() { return this.m(this.accesoriosTotal); }
    get tieneAccesorios() { return this.accesoriosTotal > 0; }
    handleToggleAccesorio(event) {
        const vehicleId = event.currentTarget.dataset.vehicle;
        const id = event.currentTarget.dataset.id;
        const porVehiculo = { ...(this.accesoriosSel[vehicleId] || {}), [id]: event.target.checked };
        this.accesoriosSel = { ...this.accesoriosSel, [vehicleId]: porVehiculo };
    }

    // ------- paso Precio -------
    get priceBreakdown() {
        if (this.esRepuestos) {
            const rows = this.repuestosSeleccionados.map(r => ({
                id: 'rep-' + r.id,
                concepto: `${r.nombre} (${r.codigo}) × ${r.cantidad} — precio en línea SAP`,
                valor: r.subtotalFmt
            }));
            rows.push({ id: 'imp', concepto: 'Impuesto de referencia 13% (Decision Matrix BRE)', valor: this.m(this.repuestosTotal * 0.13) });
            return rows;
        }
        const rows = this.selectedVehicles.map(v => ({
            id: 'veh-' + v.id,
            concepto: this.esUsado
                ? `Precio publicado — ${v.modelo} (gestión propia)`
                : `Precio de lista — ${v.modelo} (PricebookEntry ${this.monedaIso}, sociedad C101)`,
            valor: this.m(v.precioNum)
        }));
        rows.push(...(this.esUsado ? this.gastosExtrasUsado : this.gastosExtrasNuevo)
            .map(g => ({ id: g.id, concepto: g.concepto, valor: this.m(g.valorNum) })));
        if (this.tieneAccesorios) {
            rows.push({
                id: 'acc',
                concepto: 'Accesorios seleccionados (todos los vehículos)',
                valor: this.accesoriosTotalFmt
            });
        }
        return rows;
    }

    // ------- paso Descuentos -------
    get baseTotal() {
        if (this.esRepuestos) {
            return Math.round(this.repuestosTotal * 1.13);
        }
        const vehiculos = this.selectedVehicles.reduce((sum, v) => sum + (v.precioNum || 0), 0);
        return vehiculos + this.accesoriosTotal;
    }
    get totalReferenciaFmt() { return this.m(this.baseTotal); }
    get maxDescuentoDirectoFmt() { return this.m(MAX_DESCUENTO_DIRECTO); }
    get descuentoNum() { return Number(this.descuento) || 0; }
    get totalConDescuento() { return this.baseTotal - this.descuentoNum; }
    get totalConDescuentoFmt() { return this.m(this.totalConDescuento); }
    get descuentoRequiereAprobacion() { return this.descuentoNum > MAX_DESCUENTO_DIRECTO; }
    get descuentoDentroDelMargen() { return this.descuentoNum > 0 && !this.descuentoRequiereAprobacion; }
    get descuentoPendiente() { return this.descuentoRequiereAprobacion && !this.descuentoAprobado; }
    get excesoSobreMinimoFmt() { return this.m(this.descuentoNum - MAX_DESCUENTO_DIRECTO); }
    get leyendaMinimo() {
        if (this.esRepuestos) {
            return 'Repuestos: margen por canal/categoría definido por el negocio (Decision Matrix); el precio base es el de la consulta en línea a SAP y no se persiste.';
        }
        return this.esUsado
            ? 'Precio mínimo del usado: definido por la Gerencia de Usados por unidad; por debajo, Approval Process nativo.'
            : 'Precio mínimo por modelo/versión: Decision Matrix (BRE), mantenida por el negocio — nunca en Apex.';
    }

    handleDescuentoChange(event) {
        this.descuento = event.detail.value;
        this.descuentoAprobado = false;
    }

    async handleEnviarAprobacion() {
        const result = await AprobacionDescuentoModal.open({
            size: 'small',
            label: 'Aprobación de descuento',
            descuentoFmt: this.m(this.descuentoNum),
            maxDirectoFmt: this.m(MAX_DESCUENTO_DIRECTO),
            excesoFmt: this.excesoSobreMinimoFmt
        });
        if (result === 'enviar') {
            this.descuentoAprobado = true;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Aprobación simulada',
                message: 'Real: Approval Process nativo con el Gerente de Sucursal; el registro queda trazado en la cotización.',
                variant: 'success'
            }));
        }
    }

    // ------- paso Pago -------
    get formaPagoOptions() {
        return [
            { label: 'Contado', value: 'contado' },
            { label: 'Financiado (CrediQ)', value: 'financiado' }
        ];
    }
    get plazoOptions() {
        return [
            { label: '36 meses', value: '36' },
            { label: '48 meses', value: '48' },
            { label: '60 meses', value: '60' },
            { label: '72 meses', value: '72' }
        ];
    }
    get isContado() { return this.formaPago === 'contado'; }
    get isFinanciado() { return this.formaPago === 'financiado'; }
    get tasaReferenciaFmt() { return TASA_ANUAL_REFERENCIA.toLocaleString('de-DE') + ' % anual (referencia)'; }
    get primaValue() {
        return this.prima === undefined || this.prima === null || this.prima === ''
            ? Math.round(this.totalConDescuento * 0.3)
            : Number(this.prima);
    }
    get primaFmt() { return this.m(this.primaValue); }
    get montoFinanciado() { return Math.max(this.totalConDescuento - this.primaValue, 0); }
    get montoFinanciadoFmt() { return this.m(this.montoFinanciado); }
    get cuotaMensual() {
        const monto = this.montoFinanciado;
        if (monto <= 0) return 0;
        const i = TASA_ANUAL_REFERENCIA / 100 / 12;
        const n = parseInt(this.plazo, 10);
        return Math.round((monto * i) / (1 - Math.pow(1 + i, -n)));
    }
    get cuotaMensualFmt() { return this.m(this.cuotaMensual); }

    handleFormaPagoChange(event) {
        this.formaPago = event.detail.value;
        this.resetFinanciamiento();
    }
    handlePrimaChange(event) {
        this.prima = event.detail.value;
        this.resetFinanciamiento();
    }
    handlePlazoChange(event) {
        this.plazo = event.detail.value;
        this.resetFinanciamiento();
    }
    resetFinanciamiento() {
        this.financingOptions = [];
        this.selectedFinancingId = '';
        this.financingLoading = false;
    }

    /**
     * Llama a la frente financiera (CrediQ) via el BFF:
     * GuidedSellingController.getFinancingOptions -> FinancingService (el
     * CONTRATO con el equipo financiero vive alli, INTEGRATION MAP). Hoy el
     * servicio responde con productos CrediQ simulados; cuando la frente
     * conecte su servicio real (FSC / CrediQ via MuleSoft) esta llamada NO
     * cambia. ALTERNATIVA si la frente entrega un SCREEN FLOW en lugar de
     * servicio: reemplazar esta llamada por el base component
     * <lightning-flow flow-api-name="..." flow-input-variables={...}
     * onstatuschange={...}> y leer event.detail.outputVariables cuando
     * status === 'FINISHED' (la opcion elegida vuelve como output del flow).
     */
    async handleLlamarFinanciero() {
        this.financingLoading = true;
        this.financingOptions = [];
        this.selectedFinancingId = '';
        try {
            const request = {
                opportunityId: this.recordId,
                montoFinanciar: this.montoFinanciado,
                prima: this.primaValue,
                plazoMeses: parseInt(this.plazo, 10),
                monedaIso: this.monedaIso,
                descripcionVehiculo: this.vehiculoChip
            };
            const options = await getFinancingOptions({ requestJson: JSON.stringify(request) });
            this.financingOptions = options || [];
            if (this.financingOptions.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Sin opciones disponibles',
                    message: 'La frente financiera no devolvió opciones para estas condiciones. Ajusta prima o plazo e intenta de nuevo.',
                    variant: 'warning'
                }));
            }
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error al consultar financiamiento',
                message: error?.body?.message || error?.message || 'Error desconocido',
                variant: 'error'
            }));
        } finally {
            this.financingLoading = false;
        }
    }

    handleSelectFinancing(event) {
        this.selectedFinancingId = event.currentTarget.dataset.id;
    }
    get tieneOpcionesFinanciamiento() { return this.financingOptions.length > 0; }
    get financiamientoSeleccionado() {
        return this.financingOptions.find(o => o.optionId === this.selectedFinancingId);
    }
    /** Cards de opciones con formato de moneda y estado de seleccion. */
    get financingOptionsView() {
        return this.financingOptions.map(o => {
            const sel = o.optionId === this.selectedFinancingId;
            return {
                ...o,
                titulo: `${o.entidad} ${o.producto}`,
                tasaFmt: o.tasaAnual.toLocaleString('de-DE') + ' % anual',
                plazoFmt: o.plazoMeses + ' meses',
                cuotaFmt: this.m(o.cuotaMensual),
                montoFmt: this.m(o.montoFinanciado),
                sel,
                cardClass: sel ? 'veh-card fin-card fin-card-sel' : 'veh-card fin-card'
            };
        });
    }
    get leyendaFinanciamiento() {
        return this.tieneOpcionesFinanciamiento
            ? 'Selecciona la opción elegida por el cliente para continuar; queda registrada en la cotización.'
            : 'Consulta las opciones de financiamiento para que el cliente elija.';
    }

    // ------- paso Cotizacion -------
    get vehiculoResumen() {
        return this.selectedVehicles.map(v => this.esUsado
            ? `${v.modelo} — ${v.anio} — ${v.km} — VIN ${v.vin} (USADO)`
            : `${v.modelo} — ${v.anio} — ${v.color}`
        ).join(' | ') || '-';
    }
    /**
     * Estados de la cotizacion (acuerdo Davi + Meli, HU-044): pedido normal =
     * hay stock en sucursal o central; en transito = sin stock pero con fecha
     * de stock (disponibilidad.cantidad); pedido futuro = sin stock ninguno.
     * Con seleccion multiple se crea UNA COTIZACION POR VEHICULO
     * (QuoteOrderService); el boton refleja el caso mas restrictivo.
     */
    get createQuoteBtn() {
        if (this.esRepuestos) {
            const n = this.repuestosSeleccionados.length;
            return this.tieneRepuestoSinPrecio
                ? { label: 'Crear cotización y solicitar material', variant: 'neutral' }
                : { label: `Crear cotización (${n} línea${n > 1 ? 's' : ''})`, variant: 'brand' };
        }
        const n = this.selectedVehicles.length;
        if (this.esUsado || n === 0) {
            return { label: n > 1 ? `Crear cotizaciones (${n})` : 'Crear cotización', variant: 'brand' };
        }
        const sinStock = this.selectedVehicles.filter(v => !v.stockDealer && !v.stockCentral);
        if (n === 1) {
            if (sinStock.length === 0) return { label: 'Crear cotización', variant: 'brand' };
            return sinStock[0].disponibilidad?.cantidad
                ? { label: 'Crear cotización en tránsito', variant: 'neutral' }
                : { label: 'Crear cotización de pedido futuro', variant: 'brand' };
        }
        const labelBase = `Crear cotizaciones (${n})`;
        if (sinStock.length === 0) return { label: labelBase, variant: 'brand' };
        const pedidoFuturo = sinStock.some(v => !v.disponibilidad?.cantidad);
        return pedidoFuturo
            ? { label: labelBase + ' — incluye pedido futuro', variant: 'brand' }
            : { label: labelBase + ' — incluye en tránsito', variant: 'neutral' };
    }

    get quoteSummary() {
        const rows = [
            { id: 'q1', etiqueta: 'Cliente', valor: 'Vendedor- (Cuenta de prueba)' }
        ];
        if (this.esRepuestos) {
            this.repuestosSeleccionados.forEach((r, i) => {
                rows.push({ id: 'rep' + i, etiqueta: `${r.nombre} (${r.codigo}) × ${r.cantidad}`, valor: r.subtotalFmt });
            });
            if (this.tieneRepuestoSinPrecio) {
                rows.push({ id: 'repSol', etiqueta: 'Material sin código SAP',
                    valor: 'Se genera solicitud de creación de material (HU-039); la línea entra cuando SAP devuelva el MATNR' });
            }
            rows.push({ id: 'q3', etiqueta: 'Total de referencia (con impuesto)', valor: this.totalReferenciaFmt });
            if (this.descuentoNum > 0) {
                rows.push({ id: 'q4', etiqueta: 'Descuento comercial', valor: '- ' + this.m(this.descuentoNum) });
                rows.push({ id: 'q5', etiqueta: 'Total con descuento', valor: this.totalConDescuentoFmt });
            }
            if (this.formaPago) {
                const finRep = this.financiamientoSeleccionado;
                rows.push({ id: 'q6', etiqueta: 'Forma de pago', valor: this.isContado
                    ? 'Contado'
                    : (finRep ? `Financiado ${finRep.entidad} ${finRep.producto} — ${finRep.plazoMeses} meses` : 'Financiado CrediQ — ' + this.plazo + ' meses') });
            }
            rows.push({ id: 'q9', etiqueta: 'Vigencia de la cotización', valor: VIGENCIA_DIAS + ' días' });
            rows.push({ id: 'q10', etiqueta: 'Precio definitivo', valor: 'Precio en línea de SAP al facturar (sin precio persistido en Salesforce)' });
            return rows;
        }
        this.selectedVehicles.forEach((v, i) => {
            rows.push({
                id: 'veh' + i,
                etiqueta: `Vehículo ${this.selectedVehicles.length > 1 ? (i + 1) : ''}`.trim(),
                valor: this.esUsado
                    ? `${v.modelo} — ${v.anio} — ${v.km} — VIN ${v.vin} (USADO)`
                    : `${v.modelo} — ${v.anio} — ${v.color}`
            });
            this.accesoriosSeleccionadosDe(v.id).forEach((a, j) => {
                rows.push({ id: `acc${i}-${j}`, etiqueta: '· Accesorio: ' + a.nombre, valor: this.m(a.precio) });
            });
        });
        rows.push({ id: 'q3', etiqueta: 'Total de referencia', valor: this.totalReferenciaFmt });
        if (this.descuentoNum > 0) {
            const sufijo = this.descuentoRequiereAprobacion ? ' (aprobado por Gerente — simulado)' : ' (dentro del margen)';
            rows.push({ id: 'q4', etiqueta: 'Descuento comercial', valor: '- ' + this.m(this.descuentoNum) + sufijo });
            rows.push({ id: 'q5', etiqueta: 'Total con descuento', valor: this.totalConDescuentoFmt });
        }
        if (this.isFinanciado) {
            const fin = this.financiamientoSeleccionado;
            if (fin) {
                rows.push({ id: 'q6', etiqueta: 'Forma de pago', valor: `Financiado ${fin.entidad} ${fin.producto} — ${fin.plazoMeses} meses` });
                rows.push({ id: 'q7', etiqueta: 'Prima', valor: this.primaFmt });
                rows.push({ id: 'q8', etiqueta: 'Cuota mensual (oferta elegida)', valor: this.m(fin.cuotaMensual) + ` — tasa ${fin.tasaAnual.toLocaleString('de-DE')} %` });
            } else {
                rows.push({ id: 'q6', etiqueta: 'Forma de pago', valor: 'Financiado CrediQ — ' + this.plazo + ' meses' });
                rows.push({ id: 'q7', etiqueta: 'Prima', valor: this.primaFmt });
                rows.push({ id: 'q8', etiqueta: 'Cuota mensual estimada', valor: this.cuotaMensualFmt + ' (referencia)' });
            }
        } else if (this.isContado) {
            rows.push({ id: 'q6', etiqueta: 'Forma de pago', valor: 'Contado' });
        }
        if (this.esNuevo) {
            this.selectedVehicles.filter(v => !v.stockDealer && !v.stockCentral).forEach((v, i) => {
                let dispo;
                if (v.disponibilidad?.cantidad) {
                    dispo = v.disponibilidad.fuente === 'recepcion_futura'
                        ? `${v.modelo}: recepción futura — ${v.disponibilidad.cantidad} unidades el ${v.disponibilidad.eta} (HU-044)`
                        : `${v.modelo}: ${v.disponibilidad.cantidad} unidades en tránsito, ETA ${v.disponibilidad.eta}`;
                } else {
                    dispo = `${v.modelo}: sin stock ni tránsito — la cotización registra la solicitud de la unidad (HU-044)`;
                }
                rows.push({ id: 'q11-' + i, etiqueta: 'Disponibilidad', valor: dispo });
            });
        }
        rows.push({ id: 'q9', etiqueta: 'Vigencia de la cotización', valor: VIGENCIA_DIAS + ' días' });
        rows.push({ id: 'q10', etiqueta: 'Precio definitivo',
            valor: this.esUsado ? 'Facturación del usado: definición pendiente (SAP o local)' : 'Lo certifica SAP al facturar' });
        return rows;
    }
    get leyendaCotizacion() {
        if (this.esRepuestos) {
            return 'Real: contraventa de Repuestos y PA — el precio se consulta en línea a SAP (Get_Price_ZGQREF) al cotizar y al facturar; nada de precio persistido (HU-028, Cenario 1). Material sin código dispara la solicitud de creación (HU-039).';
        }
        const porVehiculo = this.selectedVehicles.length > 1
            ? ' Se crea UNA cotización por vehículo seleccionado.'
            : '';
        return (this.esUsado
            ? 'Real: QuoteOrderService crea la cotización nativa. Al facturar, la assetización CIERRA el asset del dueño anterior y crea el del comprador (misma unidad Vehicle, historial completo).'
            : 'Real: QuoteOrderService crea la cotización nativa; el pedido viaja al SAP en segundo plano y el resultado vuelve por platform event. Accesorios = líneas del pricebook Vehículos y accesorios.') + porVehiculo;
    }

    async handleCreateQuote() {
        const result = await CotizacionConfirmModal.open({
            size: 'small',
            label: 'Confirmar cotización',
            totalFmt: this.totalConDescuentoFmt
        });
        if (result === 'confirmar') {
            if (this.esRepuestos) {
                // TODO real: rama de contraventa en QuoteOrderService (lineas de
                // repuesto por cantidad, precio de la consulta SAP, solicitud de
                // material HU-039 para lineas sin codigo) — mock hasta cerrar el
                // contrato del RFC Get_Price_ZGQREF (Pendencia 13)
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Mock de presentación',
                    message: 'Aquí se crea la cotización de repuestos con precio en línea de SAP; las líneas sin código generan la solicitud de material (HU-039).',
                    variant: 'info'
                }));
                this.close('cotizacion-repuestos-mock');
                return;
            }
            // payload real para QuoteOrderService: accesorios POR VEHICULO,
            // descuento (con su estado de aprobacion), forma de pago y vigencia;
            // los vehiculos viajan aparte en selectedVehicles (contrato existente)
            const payload = {
                ventaTipo: this.ventaTipo,
                descuento: this.descuentoNum,
                descuentoRequiereAprobacion: this.descuentoRequiereAprobacion,
                descuentoAprobado: this.descuentoAprobado,
                formaPago: this.formaPago,
                prima: this.isFinanciado ? this.primaValue : null,
                plazo: this.isFinanciado ? this.plazo : null,
                // opcion de financiamiento ELEGIDA por el cliente (oferta de
                // FinancingService); QuoteOrderService la registra en la quote
                financiamiento: this.isFinanciado ? (this.financiamientoSeleccionado || null) : null,
                vigenciaDias: VIGENCIA_DIAS,
                accesoriosPorVehiculo: this.selectedVehicles.map(v => ({
                    vehicleId: v.id,
                    modelo: v.modelo,
                    items: this.accesoriosSeleccionadosDe(v.id).map(a => ({
                        id: a.id, nombre: a.nombre, precio: a.precio
                    }))
                }))
            };
            try {
                await createQuote({
                    opportunityId: this.recordId,
                    quotePayloadJson: JSON.stringify(payload),
                    selectedVehicles: JSON.stringify(this.selectedVehicles)
                });
                const n = this.selectedVehicles.length;
                this.dispatchEvent(new ShowToastEvent({
                    title: n > 1 ? `${n} cotizaciones creadas` : 'Cotización creada',
                    message: `Vigencia de ${VIGENCIA_DIAS} días registrada en la oportunidad.`,
                    variant: 'success'
                }));
                this.close('cotizacion-creada');
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error al crear la cotización',
                    message: error?.body?.message || error?.message || 'Error desconocido',
                    variant: 'error'
                }));
            }
        }
    }

    handleCancel() {
        this.close('cancelado');
    }
}