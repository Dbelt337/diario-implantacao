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
 * Discounts: minimum price comes from BRE (Decision Matrix); below-minimum
 * requests go through the native Approval Process (simulated here).
 * Payment: the financing step only CALLS the financing front flow (CrediQ);
 * the installment shown is a commercial reference, not the credit engine.
 */

const STEPS = ['seleccion', 'precio', 'descuento', 'pago', 'cotizacion'];

// ------- parametros SIMULADOS (los reemplazan BRE / frente financiera) -------
const TOTAL_REFERENCIA = 24631000;      // total del paso Precio (mock)
const MAX_DESCUENTO_DIRECTO = 700000;   // margen hasta el precio minimo (real: Decision Matrix BRE)
const TASA_ANUAL_REFERENCIA = 9.5;      // % anual solo de referencia (real: motor CrediQ)

function crc(value) {
    const n = Math.round(value || 0);
    const sign = n < 0 ? '- ' : '';
    return sign + 'CRC ' + Math.abs(n).toLocaleString('de-DE');
}

export default class VentaGuiadaModal extends LightningModal {
    @api recordId;

    currentStep = 'seleccion';
    selectedVehicleId;
    searchTerm = '';

    // paso Descuentos
    descuento = 0;
    descuentoAprobado = false;

    // paso Pago
    formaPago = '';
    prima;                 // null = usar la sugerencia del 30%
    plazo = '60';
    solicitudFinancieroEnviada = false;

    // ------- datos SIMULADOS (los reemplazan los servicios Apex) -------
    vehicles = [
        { id: 'V1', modelo: 'Hyundai Tucson GLS 2.0', anio: '2026', color: 'Blanco Polar',
          precio: 'CRC 21.500.000', stockCentral: 3, stockLindora: 1 },
        { id: 'V2', modelo: 'Hyundai Tucson Limited', anio: '2026', color: 'Gris Titanio',
          precio: 'CRC 24.900.000', stockCentral: 1, stockLindora: 0 },
        { id: 'V3', modelo: 'Hyundai Creta GL 1.5', anio: '2026', color: 'Rojo Fuego',
          precio: 'CRC 16.800.000', stockCentral: 5, stockLindora: 2 }
    ];

    priceBreakdown = [
        { id: 'p1', concepto: 'Precio de lista (PricebookEntry, sociedad C101)', valor: 'CRC 21.500.000' },
        { id: 'p2', concepto: 'Gastos (matrícula + entrega)', valor: 'CRC 850.000' },
        { id: 'p3', concepto: 'Impuesto de referencia 13% (Decision Matrix BRE)', valor: 'CRC 2.795.000' },
        { id: 'p4', concepto: 'Cashback vigente', valor: '- CRC 500.000' },
        { id: 'p5', concepto: 'Valor de trade-in (avalúo aceptado)', valor: '- CRC 14.000' }
    ];
    // -------------------------------------------------------------------

    // ------- navegacion -------
    get isStepSeleccion() { return this.currentStep === 'seleccion'; }
    get isStepPrecio() { return this.currentStep === 'precio'; }
    get isStepDescuento() { return this.currentStep === 'descuento'; }
    get isStepPago() { return this.currentStep === 'pago'; }
    get isStepCotizacion() { return this.currentStep === 'cotizacion'; }
    get isFirstStep() { return this.currentStep === STEPS[0]; }

    get nextDisabled() {
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

    // ------- paso Vehiculo -------
    get vehicleOptions() {
        return this.vehicles.map((vehicle) => ({
            ...vehicle,
            rowClass: vehicle.id === this.selectedVehicleId
                ? 'slds-hint-parent selected-row'
                : 'slds-hint-parent'
        }));
    }
    handleSearchChange(event) {
        // TODO real: MaterialSearchService.search con debounce
        this.searchTerm = event.target.value;
    }
    handleSelectVehicle(event) {
        this.selectedVehicleId = event.currentTarget.dataset.id;
    }

    // ------- paso Descuentos -------
    get totalReferenciaFmt() { return crc(TOTAL_REFERENCIA); }
    get maxDescuentoDirectoFmt() { return crc(MAX_DESCUENTO_DIRECTO); }
    get descuentoNum() { return Number(this.descuento) || 0; }
    get totalConDescuento() { return TOTAL_REFERENCIA - this.descuentoNum; }
    get totalConDescuentoFmt() { return crc(this.totalConDescuento); }
    get descuentoRequiereAprobacion() { return this.descuentoNum > MAX_DESCUENTO_DIRECTO; }
    get descuentoDentroDelMargen() { return this.descuentoNum > 0 && !this.descuentoRequiereAprobacion; }
    get descuentoPendiente() { return this.descuentoRequiereAprobacion && !this.descuentoAprobado; }
    get excesoSobreMinimoFmt() { return crc(this.descuentoNum - MAX_DESCUENTO_DIRECTO); }

    handleDescuentoChange(event) {
        this.descuento = event.detail.value;
        this.descuentoAprobado = false; // cambiar el monto invalida la aprobacion anterior
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
            this.descuentoAprobado = true; // demo: aprobacion inmediata simulada
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
        // TODO real: lanzar el flow/subflujo de la frente financiera (CrediQ)
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
            { id: 'q2', etiqueta: 'Vehículo', valor: 'Hyundai Tucson GLS 2.0 — 2026 — Blanco Polar' },
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
        rows.push({ id: 'q10', etiqueta: 'Precio definitivo', valor: 'Lo certifica SAP al facturar' });
        return rows;
    }

    async handleCreateQuote() {
        // sub-modal apilado: decision secundaria sin salir del flujo
        const result = await CotizacionConfirmModal.open({
            size: 'small',
            label: 'Confirmar cotización',
            totalFmt: this.totalConDescuentoFmt
        });
        if (result === 'confirmar') {
            // TODO real: QuoteOrderService.createQuote
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
