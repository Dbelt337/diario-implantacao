import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CotizacionConfirmModal from 'c/cotizacionConfirmModal';
import AprobacionDescuentoModal from 'c/aprobacionDescuentoModal';

/**
 * All countries. Large modal with the guided-selling step-by-step. CURRENT
 * STATE: presentation mock (simulated data) showing the target experience;
 * each step gets wired to its Apex service (MaterialSearchService,
 * SapInventoryService + PricingService, QuoteOrderService). Secondary
 * decisions open stacked modals (quote confirmation, discount approval).
 * NEW vs USED split: new-vehicle price/stock come from SAP via MuleSoft
 * (live query); used-vehicle inventory and price are OWNED by Salesforce
 * (Vehicle records, SOQL, no SAP call) per the used-inventory user story.
 * Discounts: minimum price from BRE (new) or used-inventory management
 * (used); below-minimum goes through the native Approval Process.
 * Payment: the financing step only CALLS the financing front flow (CrediQ).
 */

const STEPS = ['tipo', 'seleccion', 'precio', 'descuento', 'pago', 'cotizacion'];

// ------- parametros SIMULADOS (los reemplazan BRE / frente financiera) -------
const TOTAL_NUEVO = 24631000;           // total de referencia del nuevo (mock)
const TOTAL_USADO = 14927000;           // total de referencia del usado (mock)
const MAX_DESCUENTO_DIRECTO = 700000;   // margen hasta el precio minimo
const TASA_ANUAL_REFERENCIA = 9.5;      // % anual solo de referencia (real: CrediQ)

function crc(value) {
    const n = Math.round(value || 0);
    const sign = n < 0 ? '- ' : '';
    return sign + 'CRC ' + Math.abs(n).toLocaleString('de-DE');
}

export default class VentaGuiadaModal extends LightningModal {
    @api recordId;

    currentStep = 'tipo';
    ventaTipo = '';
    selectedVehicleId;
    searchTerm = '';

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
        { id: 'V1', modelo: 'Hyundai Tucson GLS 2.0', anio: '2026', color: 'Blanco Polar',
          precio: 'CRC 21.500.000', stockCentral: 3, stockLindora: 1 },
        { id: 'V2', modelo: 'Hyundai Tucson Limited', anio: '2026', color: 'Gris Titanio',
          precio: 'CRC 24.900.000', stockCentral: 1, stockLindora: 0 },
        { id: 'V3', modelo: 'Hyundai Creta GL 1.5', anio: '2026', color: 'Rojo Fuego',
          precio: 'CRC 16.800.000', stockCentral: 5, stockLindora: 2 }
    ];

    vehiclesUsados = [
        { id: 'U1', modelo: 'Hyundai Accent 1.6', anio: '2022', km: '45.000 km',
          vin: '3KPC24...4885', precio: 'CRC 12.900.000', ubicacion: 'La Uruca' },
        { id: 'U2', modelo: 'Hyundai Tucson GLS', anio: '2021', km: '62.000 km',
          vin: 'KM8J33...1207', precio: 'CRC 16.500.000', ubicacion: 'Lindora' },
        { id: 'U3', modelo: 'Chevrolet Onix LT', anio: '2023', km: '28.000 km',
          vin: '9BGKS48...3341', precio: 'CRC 11.800.000', ubicacion: 'La Uruca' }
    ];

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
        if (this.isStepSeleccion) return !this.selectedVehicleId;
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
    handleTipoNuevo() {
        this.setTipo('nuevo');
    }
    handleTipoUsado() {
        this.setTipo('usado');
    }
    setTipo(tipo) {
        if (this.ventaTipo !== tipo) {
            this.ventaTipo = tipo;
            this.selectedVehicleId = undefined;
            this.descuento = 0;
            this.descuentoAprobado = false;
            this.formaPago = '';
            this.prima = undefined;
            this.solicitudFinancieroEnviada = false;
        }
    }
    get tipoNuevoClass() {
        return this.esNuevo ? 'tipo-card tipo-card-selected' : 'tipo-card';
    }
    get tipoUsadoClass() {
        return this.esUsado ? 'tipo-card tipo-card-selected' : 'tipo-card';
    }

    // ------- paso Vehiculo -------
    get vehicleOptions() {
        const source = this.esUsado ? this.vehiclesUsados : this.vehiclesNuevos;
        return source.map((vehicle) => ({
            ...vehicle,
            rowClass: vehicle.id === this.selectedVehicleId
                ? 'slds-hint-parent selected-row'
                : 'slds-hint-parent'
        }));
    }
    get leyendaSeleccion() {
        return this.esUsado
            ? 'Selecciona una fila para continuar. (Real: inventario PROPIO en Vehicle — SOQL directo, sin SAP. Ficha del usado de la historia de inventario de usados.)'
            : 'Selecciona una fila para continuar. (Real: MaterialSearchService — local, SAP y extensión automática.)';
    }
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }
    handleSelectVehicle(event) {
        this.selectedVehicleId = event.currentTarget.dataset.id;
    }

    // ------- paso Precio -------
    get priceBreakdown() {
        return this.esUsado ? this.priceBreakdownUsado : this.priceBreakdownNuevo;
    }

    // ------- paso Descuentos -------
    get baseTotal() { return this.esUsado ? TOTAL_USADO : TOTAL_NUEVO; }
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

    handleFormaPagoChange(event) {
        this.formaPago = event.detail.value;
    }
    handlePrimaChange(event) {
        this.prima = event.detail.value;
    }
    handlePlazoChange(event) {
        this.plazo = event.detail.value;
    }
    handleLlamarFinanciero() {
        this.solicitudFinancieroEnviada = true;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Mock de presentación',
            message: 'Aquí se lanza el flujo del financiero (CrediQ) con vehículo, prima y plazo; tasas y aprobación crediticia se resuelven en esa frente.',
            variant: 'info'
        }));
    }

    // ------- paso Cotizacion -------
    get quoteSummary() {
        const rows = [
            { id: 'q1', etiqueta: 'Cliente', valor: 'Vendedor- (Cuenta de prueba)' },
            { id: 'q2', etiqueta: 'Vehículo',
              valor: this.esUsado
                ? 'Hyundai Accent 1.6 — 2022 — 45.000 km — VIN 3KPC24...4885 (USADO)'
                : 'Hyundai Tucson GLS 2.0 — 2026 — Blanco Polar' },
            { id: 'q3', etiqueta: 'Total de referencia', valor: this.totalReferenciaFmt }
        ];
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
        rows.push({ id: 'q9', etiqueta: 'Vigencia de la cotización', valor: '15 días' });
        rows.push({ id: 'q10', etiqueta: 'Precio definitivo',
            valor: this.esUsado ? 'Facturación del usado: definición pendiente (SAP o local)' : 'Lo certifica SAP al facturar' });
        return rows;
    }
    get leyendaCotizacion() {
        return this.esUsado
            ? 'Real: QuoteOrderService crea la cotización nativa. Al facturar, la assetización CIERRA el asset del dueño anterior y crea el del comprador (misma unidad Vehicle, historial completo).'
            : 'Real: QuoteOrderService crea la cotización nativa; el pedido viaja al SAP en segundo plano y el resultado vuelve por platform event.';
    }

    async handleCreateQuote() {
        const result = await CotizacionConfirmModal.open({
            size: 'small',
            label: 'Confirmar cotización',
            totalFmt: this.totalConDescuentoFmt
        });
        if (result === 'confirmar') {
            // TODO real: GuidedSellingController.createQuote(this.recordId, payload) -> QuoteOrderService
            this.dispatchEvent(new ShowToastEvent({
                title: 'Mock de presentación',
                message: 'Aquí QuoteOrderService crea la cotización nativa con las líneas, el descuento trazado y el trade-in.',
                variant: 'info'
            }));
            this.close('cotizacion-creada');
        }
    }

    handleCancel() {
        this.close('cancelado');
    }
}
