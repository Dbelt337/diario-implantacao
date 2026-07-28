import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GRUPOQ_LOGO from '@salesforce/resourceUrl/GrupoQLogo';
import hasViewInventoryQuantities from '@salesforce/customPermission/ViewInventoryQuantities';
import CotizacionConfirmModal from 'c/cotizacionConfirmModal';
import AprobacionDescuentoModal from 'c/aprobacionDescuentoModal';

import createQuote from '@salesforce/apex/GuidedSellingController.createQuote';

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
 */

const STEPS = ['tipo', 'seleccion', 'accesorios', 'precio', 'descuento', 'pago', 'cotizacion'];

// ------- parametros SIMULADOS (los reemplazan BRE / frente financiera) -------
const TOTAL_NUEVO = 24631000;
const TOTAL_USADO = 14927000;
const MAX_DESCUENTO_DIRECTO = 700000;
const TASA_ANUAL_REFERENCIA = 9.5;

function crc(value) {
    const n = Math.round(value || 0);
    const sign = n < 0 ? '- ' : '';
    return sign + 'CRC ' + Math.abs(n).toLocaleString('de-DE');
}

export default class VentaGuiadaModal extends LightningModal {
    @api recordId;

    currentStep = 'tipo';
    ventaTipo = '';
    selectedVehicle;
    searchTerm = '';
    filtroMarca = '';
    filtroAnio = '';

    // paso Descuentos
    descuento = 0;
    descuentoAprobado = false;

    // paso Pago
    formaPago = '';
    prima;
    plazo = '60';
    solicitudFinancieroEnviada = false;

    // ------- datos SIMULADOS (los reemplazan los servicios Apex) -------
    vehiclesNuevos = [
        { id: 'V1', marca: 'Hyundai', modelo: 'Hyundai Tucson GLS 2.0', anio: '2026',
          color: 'Blanco Polar', colorInt: 'Negro',
          precio: 'CRC 21.500.000', stockCentral: 3, stockDealer: 1 },
        { id: 'V2', marca: 'Hyundai', modelo: 'Hyundai Tucson Limited', anio: '2026',
          color: 'Gris Titanio', colorInt: 'Beige',
          precio: 'CRC 24.900.000', stockCentral: 1, stockDealer: 0 },
        { id: 'V3', marca: 'Hyundai', modelo: 'Hyundai Creta GL 1.5', anio: '2026',
          color: 'Rojo Fuego', colorInt: 'Negro',
          precio: 'CRC 16.800.000', stockCentral: 5, stockDealer: 2 },
        { id: 'V4', marca: 'Hyundai', modelo: 'Hyundai Tucson Híbrida', anio: '2026',
          color: 'Azul Océano', colorInt: 'Gris',
          precio: 'CRC 27.900.000', stockCentral: 0, stockDealer: 0,
          disponibilidad: { cantidad: 2, eta: '15/09/2026', fuente: 'pedido_importacion' } },
        { id: 'V5', marca: 'Hyundai', modelo: 'Hyundai Santa Fe', anio: '2027',
          color: 'Negro Fantasma', colorInt: 'Marrón',
          precio: 'CRC 32.500.000', stockCentral: 0, stockDealer: 0,
          disponibilidad: { cantidad: 2, eta: '29/08/2026', fuente: 'recepcion_futura' } },
        { id: 'V6', marca: 'Chevrolet', modelo: 'Chevrolet Groove LT', anio: '2026',
          color: 'Plata Estelar', colorInt: 'Negro',
          precio: 'CRC 15.900.000', stockCentral: 4, stockDealer: 1 },
        { id: 'V7', marca: 'Hyundai', modelo: 'Hyundai Ioniq 6', anio: '2027',
          color: 'Blanco Lunar', colorInt: 'Negro',
          precio: 'CRC 38.900.000', stockCentral: 0, stockDealer: 0 }
    ];

    vehiclesUsados = [
        { id: 'U1', marca: 'Hyundai', modelo: 'Hyundai Accent 1.6', anio: '2022', km: '45.000 km',
          vin: '3KPC24...4885', precio: 'CRC 12.900.000', ubicacion: 'La Uruca' },
        { id: 'U2', marca: 'Hyundai', modelo: 'Hyundai Tucson GLS', anio: '2021', km: '62.000 km',
          vin: 'KM8J33...1207', precio: 'CRC 16.500.000', ubicacion: 'Lindora' },
        { id: 'U3', marca: 'Chevrolet', modelo: 'Chevrolet Onix LT', anio: '2023', km: '28.000 km',
          vin: '9BGKS48...3341', precio: 'CRC 11.800.000', ubicacion: 'La Uruca' }
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
    accesoriosSel = {};

    priceBreakdownNuevo = [
        { id: 'p1', concepto: 'Precio de lista (PricebookEntry, sociedad C101)', valor: 'CRC 21.500.000' },
        { id: 'p2', concepto: 'Gastos (matrícula + entrega)', valor: 'CRC 850.000' },
        { id: 'p3', concepto: 'Impuesto de referencia 13% (Decision Matrix BRE)', valor: 'CRC 2.795.000' },
        { id: 'p4', concepto: 'Cashback vigente', valor: '- CRC 500.000' },
        { id: 'p5', concepto: 'Valor de trade-in (avalúo aceptado)', valor: '- CRC 14.000' }
    ];

    priceBreakdownUsado = [
        { id: 'u1', concepto: 'Precio publicado del usado (gestión propia)', valor: 'CRC 12.900.000' },
        { id: 'u2', concepto: 'Gastos de traspaso', valor: 'CRC 350.000' },
        { id: 'u3', concepto: 'Impuesto de referencia 13% (Decision Matrix BRE)', valor: 'CRC 1.677.000' }
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
    get tituloModal() {
        return this.esUsado ? 'Venta guiada — Vehículo usado' : 'Venta guiada — Vehículo nuevo';
    }

    get nextDisabled() {
        if (this.isStepTipo) return !this.ventaTipo;
        if (this.isStepSeleccion) return !this.selectedVehicle;
        if (this.isStepDescuento) return this.descuentoRequiereAprobacion && !this.descuentoAprobado;
        if (this.isStepPago) return !this.formaPago;
        return this.isStepCotizacion;
    }

    handleNext() {
        const i = STEPS.indexOf(this.currentStep);
        if (i < STEPS.length - 1) this.currentStep = STEPS[i + 1];
    }
    handleBack() {
        const i = STEPS.indexOf(this.currentStep);
        if (i > 0) this.currentStep = STEPS[i - 1];
    }

    // ------- paso Tipo -------
    handleTipoNuevo() { this.setTipo('nuevo'); }
    handleTipoUsado() { this.setTipo('usado'); }
    setTipo(tipo) {
        if (this.ventaTipo !== tipo) {
            this.ventaTipo = tipo;
            this.selectedVehicle = undefined;
            this.descuento = 0;
            this.descuentoAprobado = false;
            this.formaPago = '';
            this.prima = undefined;
            this.solicitudFinancieroEnviada = false;
            this.accesoriosSel = {};
            this.searchTerm = '';
            this.filtroMarca = '';
            this.filtroAnio = '';
        }
    }
    get tipoNuevoClass() { return this.esNuevo ? 'tipo-card tipo-card-selected' : 'tipo-card'; }
    get tipoUsadoClass() { return this.esUsado ? 'tipo-card tipo-card-selected' : 'tipo-card'; }

    // ------- paso Vehiculo -------
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
    get vehicleOptions() {
        const term = (this.searchTerm || '').toLowerCase();
        return this.vehiclesActuales
            .filter(v => (!this.filtroMarca || v.marca === this.filtroMarca)
                && (!this.filtroAnio || v.anio === this.filtroAnio)
                && (!term || `${v.modelo} ${v.color || ''} ${v.vin || ''}`.toLowerCase().includes(term)))
            .map((vehicle) => ({
                ...vehicle,
                rowClass: vehicle.id === this.selectedVehicle?.id
                    ? 'slds-hint-parent selected-row'
                    : 'slds-hint-parent'
            }));
    }
    get leyendaSeleccion() {
        return this.esUsado
            ? 'Selecciona una fila para continuar. (Real: inventario PROPIO en Vehicle — SOQL directo, sin SAP. Ficha del usado de la historia de inventario de usados.)'
            : 'Selecciona una fila para continuar. (Real: busqueda sobre el CODIGO ACTIVO — Product2.IsActive — via MaterialSearchService; se cotiza aun sin existencia. Stock 0 con tránsito o sin unidades cambia el botón final.)';
    }
    handleSearchChange(event) {
        // TODO real: GuidedSellingController.getSelectionPageData con debounce
        this.searchTerm = event.target.value;
    }
    handleFiltroMarca(event) { this.filtroMarca = event.detail.value; }
    handleFiltroAnio(event) { this.filtroAnio = event.detail.value; }
    handleSelectVehicle(event) {
        const previo = this.selectedVehicle?.id;
        this.selectedVehicle = this.vehiclesActuales.find(
            (el) => el.id === event.currentTarget.dataset.id
        );
        // cambiar de vehiculo cambia el catalogo compatible: se limpia la seleccion
        if (previo !== this.selectedVehicle?.id) this.accesoriosSel = {};
    }

    // ------- barra de marca (logo + contexto del vehiculo) -------
    get logoUrl() { return GRUPOQ_LOGO; }
    get tieneVehiculo() { return !!this.selectedVehicle; }
    get vehiculoChip() {
        const v = this.selectedVehicle;
        if (!v) return '';
        return this.esUsado ? `${v.modelo} ${v.anio} — VIN ${v.vin}` : `${v.modelo} ${v.anio}`;
    }

    // ------- paso Accesorios (catalogo asociado al vehiculo) -------
    get accesoriosDisponibles() {
        const v = this.selectedVehicle;
        if (!v) return [];
        return this.accesoriosCatalogo.filter(a => a.modelos.includes(v.id));
    }
    get accesorioCategorias() {
        const cats = [];
        this.accesoriosDisponibles.forEach(a => {
            const item = { ...a, precioFmt: crc(a.precio), sel: !!this.accesoriosSel[a.id] };
            let cat = cats.find(c => c.nombre === a.categoria);
            if (!cat) {
                cat = { nombre: a.categoria, items: [] };
                cats.push(cat);
            }
            cat.items.push(item);
        });
        return cats;
    }
    get tituloAccesorios() {
        const v = this.selectedVehicle;
        const n = this.accesoriosDisponibles.length;
        return v ? `Catálogo compatible con ${v.modelo} (${n} piezas)` : 'Catálogo de accesorios';
    }
    get accesoriosSeleccionados() {
        return this.accesoriosDisponibles.filter(a => this.accesoriosSel[a.id]);
    }
    get accesoriosTotal() {
        return this.accesoriosSeleccionados.reduce((sum, a) => sum + a.precio, 0);
    }
    get accesoriosTotalFmt() { return crc(this.accesoriosTotal); }
    get tieneAccesorios() { return this.accesoriosTotal > 0; }
    handleToggleAccesorio(event) {
        const id = event.currentTarget.dataset.id;
        this.accesoriosSel = { ...this.accesoriosSel, [id]: event.target.checked };
    }

    // ------- paso Precio -------
    get priceBreakdown() {
        const base = this.esUsado ? this.priceBreakdownUsado : this.priceBreakdownNuevo;
        if (!this.tieneAccesorios) return base;
        return [...base, {
            id: 'acc',
            concepto: `Accesorios seleccionados (${this.accesoriosSeleccionados.length})`,
            valor: this.accesoriosTotalFmt
        }];
    }

    // ------- paso Descuentos -------
    get baseTotal() {
        return (this.esUsado ? TOTAL_USADO : TOTAL_NUEVO) + this.accesoriosTotal;
    }
    get totalReferenciaFmt() { return crc(this.baseTotal); }
    get maxDescuentoDirectoFmt() { return crc(MAX_DESCUENTO_DIRECTO); }
    get descuentoNum() { return Number(this.descuento) || 0; }
    get totalConDescuento() { return this.baseTotal - this.descuentoNum; }
    get totalConDescuentoFmt() { return crc(this.totalConDescuento); }
    get descuentoRequiereAprobacion() { return this.descuentoNum > MAX_DESCUENTO_DIRECTO; }
    get descuentoDentroDelMargen() { return this.descuentoNum > 0 && !this.descuentoRequiereAprobacion; }
    get descuentoPendiente() { return this.descuentoRequiereAprobacion && !this.descuentoAprobado; }
    get excesoSobreMinimoFmt() { return crc(this.descuentoNum - MAX_DESCUENTO_DIRECTO); }
    get leyendaMinimo() {
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
            descuentoFmt: crc(this.descuentoNum),
            maxDirectoFmt: crc(MAX_DESCUENTO_DIRECTO),
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
    get primaFmt() { return crc(this.primaValue); }
    get montoFinanciado() { return Math.max(this.totalConDescuento - this.primaValue, 0); }
    get montoFinanciadoFmt() { return crc(this.montoFinanciado); }
    get cuotaMensual() {
        const monto = this.montoFinanciado;
        if (monto <= 0) return 0;
        const i = TASA_ANUAL_REFERENCIA / 100 / 12;
        const n = parseInt(this.plazo, 10);
        return Math.round((monto * i) / (1 - Math.pow(1 + i, -n)));
    }
    get cuotaMensualFmt() { return crc(this.cuotaMensual); }

    handleFormaPagoChange(event) { this.formaPago = event.detail.value; }
    handlePrimaChange(event) { this.prima = event.detail.value; }
    handlePlazoChange(event) { this.plazo = event.detail.value; }
    handleLlamarFinanciero() {
        // TODO real: lanzar el flow/subflujo de la frente financiera (CrediQ)
        this.solicitudFinancieroEnviada = true;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Mock de presentación',
            message: 'Aquí se lanza el flujo del financiero (CrediQ) con vehículo, prima y plazo; tasas y aprobación crediticia se resuelven en esa frente.',
            variant: 'info'
        }));
    }

    // ------- paso Cotizacion -------
    get vehiculoResumen() {
        const v = this.selectedVehicle;
        if (!v) return '-';
        return this.esUsado
            ? `${v.modelo} — ${v.anio} — ${v.km} — VIN ${v.vin} (USADO)`
            : `${v.modelo} — ${v.anio} — ${v.color}`;
    }
    /**
     * Estados de la cotizacion segun disponibilidad (aporte Davi, HU-044):
     * UNA estructura unica "disponibilidad" { cantidad, eta, fuente } — la
     * fuente distingue transito de recepcion futura (unificacion acordada
     * con Davi 28/07, reemplaza disponibilidadFutura). Estados: con stock =
     * cotizacion normal; en transito = cotizacion contra ETA; recepcion
     * futura = cotizacion futura contra la fecha; sin nada = la cotizacion
     * SOLICITA la unidad (HU-044: si no lo encuentra, lo solicita).
     * Usados siempre cotizan la unidad disponible.
     */
    get createQuoteBtn() {
        if (this.esUsado) return { label: 'Crear cotización', variant: 'brand' };
        const v = this.selectedVehicle;
        if (!v) return { label: 'Crear cotización', variant: 'brand' };
        if (v.stockDealer || v.stockCentral) {
            return { label: 'Crear cotización', variant: 'brand' };
        }
        // verificar si vamos utilizar este flujo separado de 'Crear cotizacion' default
        if (v.disponibilidad?.cantidad) {
            return v.disponibilidad.fuente === 'recepcion_futura'
                ? { label: 'Crear cotización futura', variant: 'neutral' }
                : { label: 'Crear cotización con unidad en tránsito', variant: 'brand' };
        }
        return { label: 'Crear cotización y solicitar unidad', variant: 'neutral' };
    }

    get quoteSummary() {
        const rows = [
            { id: 'q1', etiqueta: 'Cliente', valor: 'Vendedor- (Cuenta de prueba)' },
            { id: 'q2', etiqueta: 'Vehículo', valor: this.vehiculoResumen },
            { id: 'q3', etiqueta: 'Total de referencia', valor: this.totalReferenciaFmt }
        ];
        this.accesoriosSeleccionados.forEach((a, idx) => {
            rows.push({ id: 'acc' + idx, etiqueta: 'Accesorio: ' + a.nombre, valor: crc(a.precio) });
        });
        if (this.descuentoNum > 0) {
            const sufijo = this.descuentoRequiereAprobacion ? ' (aprobado por Gerente — simulado)' : ' (dentro del margen)';
            rows.push({ id: 'q4', etiqueta: 'Descuento comercial', valor: '- ' + crc(this.descuentoNum) + sufijo });
            rows.push({ id: 'q5', etiqueta: 'Total con descuento', valor: this.totalConDescuentoFmt });
        }
        if (this.isFinanciado) {
            rows.push({ id: 'q6', etiqueta: 'Forma de pago', valor: 'Financiado CrediQ — ' + this.plazo + ' meses' });
            rows.push({ id: 'q7', etiqueta: 'Prima', valor: this.primaFmt });
            rows.push({ id: 'q8', etiqueta: 'Cuota mensual estimada', valor: this.cuotaMensualFmt + ' (referencia)' });
        } else if (this.isContado) {
            rows.push({ id: 'q6', etiqueta: 'Forma de pago', valor: 'Contado' });
        }
        const v = this.selectedVehicle;
        if (this.esNuevo && v && !v.stockDealer && !v.stockCentral) {
            let dispo;
            if (v.disponibilidad?.cantidad) {
                dispo = v.disponibilidad.fuente === 'recepcion_futura'
                    ? `Sin stock — recepción futura: ${v.disponibilidad.cantidad} unidades el ${v.disponibilidad.eta} (HU-044)`
                    : `Sin stock — ${v.disponibilidad.cantidad} unidades en tránsito, ETA ${v.disponibilidad.eta}`;
            } else {
                dispo = 'Sin stock ni tránsito — la cotización registra la solicitud de la unidad (HU-044)';
            }
            rows.push({ id: 'q11', etiqueta: 'Disponibilidad', valor: dispo });
        }
        rows.push({ id: 'q9', etiqueta: 'Vigencia de la cotización', valor: '15 días' });
        rows.push({ id: 'q10', etiqueta: 'Precio definitivo',
            valor: this.esUsado ? 'Facturación del usado: definición pendiente (SAP o local)' : 'Lo certifica SAP al facturar' });
        return rows;
    }
    get leyendaCotizacion() {
        return this.esUsado
            ? 'Real: QuoteOrderService crea la cotización nativa. Al facturar, la assetización CIERRA el asset del dueño anterior y crea el del comprador (misma unidad Vehicle, historial completo).'
            : 'Real: QuoteOrderService crea la cotización nativa; el pedido viaja al SAP en segundo plano y el resultado vuelve por platform event. Accesorios = líneas del pricebook Vehículos y accesorios.';
    }

    async handleCreateQuote() {
        const result = await CotizacionConfirmModal.open({
            size: 'small',
            label: 'Confirmar cotización',
            totalFmt: this.totalConDescuentoFmt
        });
        if (result === 'confirmar') {
            // TODO real: GuidedSellingController.createQuote(this.recordId) (capa LWC)
            // -> QuoteOrderService.createQuote(): retrieve de las infos (vehiculo,
            // line items de accesorios, datos de descuento) por recordId; crea la
            // Quote + QuoteLineItems y el approval de descuento cuando necesario.
            // this.dispatchEvent(new ShowToastEvent({
            //     title: 'Mock de presentación',
            //     message: 'Aquí QuoteOrderService crea la cotización nativa con las líneas, los accesorios, el descuento trazado y el trade-in.',
            //     variant: 'info'
            // }));
            // this.close('cotizacion-creada');

            //call QuoteOrderService mocked for now
            try {
                console.log('this.recordId,', this.recordId)
                await createQuote({ opportunityId: this.recordId, quotePayloadJson: '{}', selectedVehicles: '['+JSON.stringify(this.selectedVehicle)+']' });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Cotización creada',
                message: '',
                variant: 'info'
            }));
            this.close('cotizacion-creada');
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error al crear la cotización',
                    message: error.body.message,
                    variant: 'error'
                }));
            }



        }
    }

    handleCancel() {
        this.close('cancelado');
    }
}