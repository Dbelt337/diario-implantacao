import { LightningElement, api } from 'lwc';

/**
 * All countries. Payment-composition summary shared by the guided-selling
 * business lines (ventaVehiculo / ventaUsados). Renders OPERANDS and their
 * trivial arithmetic only: precio + accesorios + impuestos - retoma
 * - anticipo = neto. It never fetches data and never recalculates prices —
 * price comes from SAP, the trade-in value comes frozen from the quote flow,
 * so the net shown here matches SAP by construction.
 */
export default class ResumenFinanciero extends LightningElement {
    @api precioVehiculo = 0;
    @api accesorios = 0;
    @api impuestos = 0;
    @api retoma = 0;
    @api anticipo = 0;
    @api currencyCode = 'CRC';

    get subtotal() {
        return this.num(this.precioVehiculo) + this.num(this.accesorios)
            + this.num(this.impuestos);
    }

    get neto() {
        return this.subtotal - this.num(this.retoma) - this.num(this.anticipo);
    }

    get hayRetoma() {
        return this.num(this.retoma) > 0;
    }

    get hayAnticipo() {
        return this.num(this.anticipo) > 0;
    }

    get retomaNegativa() {
        return -this.num(this.retoma);
    }

    get anticipoNegativo() {
        return -this.num(this.anticipo);
    }

    num(value) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : 0;
    }
}
