/**
 * All countries. Financing step of the guided-selling flow (CrediQ).
 *
 * ============================ INTEGRATION MAP ============================
 * CONTRACT with the FINANCIAL workstream (Roberto): the guided-selling UI
 * calls GuidedSellingController.getFinancingOptions(requestJson) with a
 * FinancingRequest and renders the returned FinancingOption list as cards;
 * the customer picks ONE and the selection travels inside the createQuote
 * payload (block "financiamiento") — it is recorded on the Quote, never on
 * the Opportunity. The formal credit application / loan record (Financial
 * Services data model) is created by the FINANCIAL front after the quote,
 * from the recorded selection — not here.
 *
 * Implementation paths for the financial team (pick one, keep this contract):
 *  A) SERVICE (recommended, best UX — options render inside our modal):
 *     replace buildMockOptions with a delegation to the financial service
 *     class, e.g. return CrediQFinancingService.getOptions(req);
 *     If that service needs an EXTERNAL callout (CrediQ core / bureau via
 *     MuleSoft), route it through the single SAP/Mule gateway already
 *     deployed: callout:MuleGateway/api/v1/financing/quotes — and convert
 *     the controller entry to a Continuation, exactly like
 *     SapInventoryService.getPricesAndInventory (pattern in this repo).
 *  B) SCREEN FLOW: if the financial front delivers a screen flow instead,
 *     the modal embeds it with the lightning-flow base component
 *     (flow-api-name + flow-input-variables; onstatuschange returns the
 *     outputVariables when status === 'FINISHED'). Wiring point documented
 *     in ventaGuiadaModal.js (handleLlamarFinanciero).
 *
 * MOCK: until the financial front wires its service, this class returns
 * deterministic CrediQ products computed from the request (French annuity),
 * so the UI, the selection and the quote payload are final — only the data
 * source swaps.
 * ========================================================================
 */
public with sharing class FinancingService {

    /** Real service pending the financial front; true = deterministic mock. */
    @TestVisible private static Boolean mockMode = true;

    /** Input built by the guided-selling UI (payment step). */
    public class FinancingRequest {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Decimal montoFinanciar;
        @AuraEnabled public Decimal prima;
        @AuraEnabled public Integer plazoMeses;
        @AuraEnabled public String monedaIso;
        @AuraEnabled public String descripcionVehiculo;
    }

    /** One financing offer the customer can pick in the UI. */
    public class FinancingOption {
        @AuraEnabled public String optionId;
        @AuraEnabled public String entidad;
        @AuraEnabled public String producto;
        @AuraEnabled public Decimal tasaAnual;
        @AuraEnabled public Integer plazoMeses;
        @AuraEnabled public Decimal montoFinanciado;
        @AuraEnabled public Decimal cuotaMensual;
        @AuraEnabled public String detalle;
    }

    /**
     * Returns the financing options for the request. Validates the input
     * here (UI-agnostic) so flows/tests reuse the same rules.
     * @param req FinancingRequest from the guided-selling payment step
     * @return options ordered as the financial front wants them displayed
     */
    public static List<FinancingOption> getOptions(FinancingRequest req) {
        if (req == null || req.montoFinanciar == null || req.montoFinanciar <= 0) {
            throw new IllegalArgumentException(
                'Monto a financiar requerido para consultar opciones de financiamiento.');
        }
        Integer plazo = (req.plazoMeses == null || req.plazoMeses <= 0) ? 60 : req.plazoMeses;
        if (mockMode) {
            return buildMockOptions(req.montoFinanciar, plazo);
        }
        // REAL (financial front): return CrediQFinancingService.getOptions(req);
        throw new IllegalArgumentException(
            'Servicio de financiamiento no disponible: frente financiera pendiente de conexion.');
    }

    /** Deterministic CrediQ products (French annuity, amounts rounded). */
    private static List<FinancingOption> buildMockOptions(Decimal monto, Integer plazo) {
        List<FinancingOption> options = new List<FinancingOption>();
        options.add(buildOption('OP-TRAD', 'CrediQ', 'Tradicional', 9.5, plazo, monto,
            'Tasa fija durante todo el plazo; sin penalidad por pago anticipado.'));
        options.add(buildOption('OP-PREM', 'CrediQ', 'Premium', 8.9, plazo, monto,
            'Tasa preferencial para prima igual o mayor al 30%; incluye seguro de vida sobre saldo.'));
        options.add(buildOption('OP-FLEX', 'CrediQ', 'Cuota Flex 72', 10.25, 72, monto,
            'Plazo extendido a 72 meses para la cuota mensual mas baja.'));
        return options;
    }

    private static FinancingOption buildOption(String optionId, String entidad,
            String producto, Decimal tasaAnual, Integer plazo, Decimal monto, String detalle) {
        FinancingOption op = new FinancingOption();
        op.optionId = optionId;
        op.entidad = entidad;
        op.producto = producto;
        op.tasaAnual = tasaAnual;
        op.plazoMeses = plazo;
        op.montoFinanciado = monto.setScale(0, RoundingMode.HALF_UP);
        op.cuotaMensual = cuotaFrancesa(monto, tasaAnual, plazo);
        op.detalle = detalle;
        return op;
    }

    /** cuota = monto * i / (1 - (1+i)^-n), i = tasa anual / 12. */
    @TestVisible
    private static Decimal cuotaFrancesa(Decimal monto, Decimal tasaAnual, Integer plazoMeses) {
        Double i = tasaAnual.doubleValue() / 100 / 12;
        Double factor = i / (1 - Math.pow(1 + i, -plazoMeses));
        return Decimal.valueOf(monto.doubleValue() * factor).setScale(0, RoundingMode.HALF_UP);
    }
}