import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CotizacionConfirmModal from 'c/cotizacionConfirmModal';

/**
 * All countries. Large modal with the guided-selling step-by-step. CURRENT
 * STATE: presentation mock (simulated data) showing the target experience;
 * each step gets wired to its Apex service (MaterialSearchService,
 * SapInventoryService + PricingService, QuoteOrderService). Secondary
 * decisions open stacked modals (see the quote confirmation).
 */
export default class VentaGuiadaModal extends LightningModal {
    @api recordId;

    currentStep = 'seleccion';
    selectedVehicleId;
    searchTerm = '';

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

    quoteSummary = [
        { id: 'q1', etiqueta: 'Cliente', valor: 'Vendedor- (Cuenta de prueba)' },
        { id: 'q2', etiqueta: 'Vehículo', valor: 'Hyundai Tucson GLS 2.0 — 2026 — Blanco Polar' },
        { id: 'q3', etiqueta: 'Total de referencia', valor: 'CRC 24.631.000' },
        { id: 'q4', etiqueta: 'Vigencia de la cotización', valor: '15 días' },
        { id: 'q5', etiqueta: 'Precio definitivo', valor: 'Lo certifica SAP al facturar' }
    ];
    // -------------------------------------------------------------------

    get isStepSeleccion() {
        return this.currentStep === 'seleccion';
    }
    get isStepPrecio() {
        return this.currentStep === 'precio';
    }
    get isStepCotizacion() {
        return this.currentStep === 'cotizacion';
    }
    get isFirstStep() {
        return this.currentStep === 'seleccion';
    }
    get nextDisabled() {
        return (this.isStepSeleccion && !this.selectedVehicleId) || this.isStepCotizacion;
    }
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

    handleNext() {
        if (this.currentStep === 'seleccion') {
            this.currentStep = 'precio';
        } else if (this.currentStep === 'precio') {
            this.currentStep = 'cotizacion';
        }
    }

    handleBack() {
        if (this.currentStep === 'cotizacion') {
            this.currentStep = 'precio';
        } else if (this.currentStep === 'precio') {
            this.currentStep = 'seleccion';
        }
    }

    async handleCreateQuote() {
        // sub-modal apilado: decision secundaria sin salir del flujo
        const result = await CotizacionConfirmModal.open({ size: 'small', label: 'Confirmar cotización' });
        if (result === 'confirmar') {
            // TODO real: QuoteOrderService.createQuote
            this.dispatchEvent(new ShowToastEvent({
                title: 'Mock de presentación',
                message: 'Aquí QuoteOrderService crea la cotización nativa con las líneas y el trade-in.',
                variant: 'info'
            }));
            this.close('cotizacion-creada');
        }
    }

    handleCancel() {
        this.close('cancelado');
    }
}
