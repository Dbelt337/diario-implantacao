/**
 * All countries. Tests for the SapMuleClient facade: every RFC method in
 * deterministic mock mode (the suite must run without SAP/Mule) plus the real
 * transport with HttpCalloutMock — success per HTTP verb, HTTP error raising
 * SapMuleClientException. DTO names are the Mule contract: the asserts here
 * freeze them.
 */
@isTest
private class SapMuleClientTest {

    // ---------- mock mode (default: contrato Mule pendiente) ----------

    @isTest
    static void asigClienteMockAcksWithContext() {
        SapMuleClient.Ack ack = SapMuleClient.asigCliente('SAP-1', 'C101');
        Assert.isTrue(ack.ok, 'Mock siempre asigna.');
        Assert.isTrue(ack.message.contains('SAP-1') && ack.message.contains('C101'),
            'El mensaje trae cliente y sociedad para trazabilidad.');
    }

    @isTest
    static void monedaClienteMockReturnsCurrency() {
        SapMuleClient.CurrencyResult r = SapMuleClient.monedaCliente('SAP-1', 'C101');
        Assert.isTrue(r.ok, 'Mock responde ok.');
        Assert.areEqual('CRC', r.currencyIsoCode, 'Moneda determinista del mock.');
    }

    @isTest
    static void crearOrdenVehiculoMockUsesReference() {
        SapMuleClient.OrderDocRequest req = new SapMuleClient.OrderDocRequest();
        req.reference = '00000042';
        SapMuleClient.OrderDocResult conReferencia = SapMuleClient.crearOrdenVehiculo(req);
        Assert.areEqual('Z301', conReferencia.docType, 'La creación siempre nace Z301.');
        Assert.areEqual('Z301-00000042', conReferencia.sapDocNumber, 'Correlación por referencia.');

        SapMuleClient.OrderDocResult sinReferencia =
            SapMuleClient.crearOrdenVehiculo(new SapMuleClient.OrderDocRequest());
        Assert.areEqual('Z301-MOCK', sinReferencia.sapDocNumber, 'Sin referencia usa MOCK.');
    }

    @isTest
    static void modificarYCopiarOrdenVehiculoMock() {
        SapMuleClient.OrderDocResult mod =
            SapMuleClient.modificarOrdenVehiculo('Z301-9', new SapMuleClient.OrderDocRequest());
        Assert.isTrue(mod.ok, 'Modificación mock ok.');
        Assert.areEqual('Z301-9', mod.sapDocNumber, 'Conserva el documento.');

        SapMuleClient.OrderDocResult copia = SapMuleClient.copiarOrdenVehiculo('Z301-9');
        Assert.areEqual('Z300', copia.docType, 'La copia produce el pedido de venta Z300.');
        Assert.areEqual('Z300-9', copia.sapDocNumber, 'Z301 -> Z300 en el número.');

        SapMuleClient.OrderDocResult copiaNula = SapMuleClient.copiarOrdenVehiculo(null);
        Assert.areEqual('Z300-MOCK', copiaNula.sapDocNumber, 'Copia sin origen usa MOCK.');
    }

    @isTest
    static void paramClienteMockReturnsChannel() {
        SapMuleClient.ClientParams p = SapMuleClient.paramCliente('SAP-1', 'C101');
        Assert.isTrue(p.ok && p.channel == 'PA' && p.paymentTerms == 'CONTADO',
            'Parámetros deterministas del mock.');
    }

    @isTest
    static void simulateSalesOrderMockComputesTax() {
        SapMuleClient.SimulationRequest req = new SapMuleClient.SimulationRequest();
        req.currencyIsoCode = 'CRC';
        SapMuleClient.SimulationLine linea = new SapMuleClient.SimulationLine();
        linea.productCode = 'REP-1'; linea.quantity = 2; linea.unitPrice = 100;
        SapMuleClient.SimulationLine lineaSinDatos = new SapMuleClient.SimulationLine();
        req.lines = new List<SapMuleClient.SimulationLine>{ linea, lineaSinDatos };

        SapMuleClient.SimulationResult r = SapMuleClient.simulateSalesOrder(req);

        Assert.areEqual(200, r.netAmount, 'Neto = suma de líneas (nulos cuentan 0/1).');
        Assert.areEqual(26.00, r.taxAmount, 'IVA 13% CR en el mock.');
        Assert.areEqual(226.00, r.totalAmount, 'Total = neto + impuesto.');

        SapMuleClient.SimulationResult vacio =
            SapMuleClient.simulateSalesOrder(new SapMuleClient.SimulationRequest());
        Assert.areEqual(0, vacio.netAmount, 'Sin líneas el neto es cero.');
    }

    @isTest
    static void consultaMaterialesMockSaldoPuedeSerNegativo() {
        List<SapMuleClient.MaterialSaldo> saldos = SapMuleClient.consultaMateriales(
            new List<String>{ 'M1', 'M2', 'M3', 'M4', 'M5' }, 'C101', 'URUCA');

        Assert.areEqual(5, saldos.size(), 'Un saldo por material (modo masivo RN-18).');
        Assert.areEqual(10, saldos[0].saldoDisponible, 'Primer material con saldo pleno.');
        Assert.isTrue(saldos[4].saldoDisponible < 0,
            'TDET_SALDOS = PISO - RESERVA puede ser NEGATIVO y se devuelve tal cual.');
        Assert.isTrue(saldos[4].textoExistencia.contains('sin saldo'),
            'Texto de existencia coherente con el saldo.');
        Assert.isTrue(saldos[0].textoExistencia.contains('URUCA'),
            'El centro consultado aparece en el texto.');

        Assert.areEqual(0, SapMuleClient.consultaMateriales(null, 'C101', null).size(),
            'Lista nula de códigos devuelve vacío, nunca excepción.');
    }

    @isTest
    static void cotizarRepuestosMockTotalizesLines() {
        SapMuleClient.RepQuoteRequest req = new SapMuleClient.RepQuoteRequest();
        req.reference = 'OPP-9';
        SapMuleClient.SimulationLine linea = new SapMuleClient.SimulationLine();
        linea.unitPrice = 50; linea.quantity = 3;
        req.lines = new List<SapMuleClient.SimulationLine>{ linea };

        SapMuleClient.RepQuoteResult r = SapMuleClient.cotizarRepuestos(req);
        Assert.areEqual('DBMCOT-OPP-9', r.sapQuoteNumber, 'Correlación por referencia.');
        Assert.areEqual(150, r.totalAmount, 'Total = suma de líneas.');
    }

    @isTest
    static void modificarPosicionesYDescuentoVendedorMock() {
        SapMuleClient.Ack ack = SapMuleClient.modificarPosicionesOrden('DBM-1', null);
        Assert.isTrue(ack.ok && ack.message.contains('DBM-1'), 'Posiciones mock ok.');

        SapMuleClient.DiscountResult d = SapMuleClient.descuentoVendedor('V001');
        Assert.areEqual(5, d.maxDiscountPercent, 'Tope determinista del mock.');
    }

    @isTest
    static void creacionMaterialesMockValidaObligatoriosYCrea() {
        SapMuleClient.MaterialCreateRequest req = new SapMuleClient.MaterialCreateRequest();
        req.material = '0014-17-411'; req.sociedad = 'C101'; req.canal = 'Q1';
        req.serie = 'D22'; req.verDefault = true;

        SapMuleClient.MaterialCreateResult r = SapMuleClient.creacionMateriales(req);
        Assert.isTrue(r.ok, 'Con los cuatro obligatorios el mock crea.');
        Assert.isTrue(r.mensaje.contains('0014-17-411') && r.mensaje.contains('versión por defecto'),
            'El mensaje traza material y VER_DEFAULT: ' + r.mensaje);

        SapMuleClient.MaterialCreateRequest sinSerie = new SapMuleClient.MaterialCreateRequest();
        sinSerie.material = '0014-17-411'; sinSerie.sociedad = 'C101'; sinSerie.canal = 'Q1';
        SapMuleClient.MaterialCreateResult rechazo = SapMuleClient.creacionMateriales(sinSerie);
        Assert.isFalse(rechazo.ok,
            'Sin SERIE el mock rechaza — regla SAP: los ZREP exigen serie.');
        Assert.isTrue(rechazo.mensaje.contains('SERIE'), 'Mensaje claro: ' + rechazo.mensaje);
    }

    @isTest
    static void creacionMaterialesRealModeDeserializesResponse() {
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class, new SapCalloutMockFactory(200,
            '{"ok":true,"mensaje":"Material 0014-17-411 creado (mensaje SAP normalizado por Mule)"}'));

        SapMuleClient.MaterialCreateRequest req = new SapMuleClient.MaterialCreateRequest();
        req.material = '0014-17-411'; req.sociedad = 'C101'; req.canal = 'Q1'; req.serie = 'D22';

        Test.startTest();
        SapMuleClient.MaterialCreateResult r = SapMuleClient.creacionMateriales(req);
        Test.stopTest();

        Assert.isTrue(r.ok, 'Respuesta 2xx normalizada por el gateway.');
        Assert.isTrue(r.mensaje.contains('creado'), 'MENSAJE de SAP preservado: ' + r.mensaje);
    }

    // ---------- transporte real (HttpCalloutMock) ----------

    @isTest
    static void realModePostDeserializesResponse() {
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class,
            new SapCalloutMockFactory(200, '{"ok":true,"message":"asignado"}'));

        Test.startTest();
        SapMuleClient.Ack ack = SapMuleClient.asigCliente('SAP-1', 'C101');
        Test.stopTest();

        Assert.isTrue(ack.ok, 'Respuesta 2xx se deserializa al DTO.');
        Assert.areEqual('asignado', ack.message, 'Payload del gateway respetado.');
    }

    @isTest
    static void realModeGetHandlesNullSellerCode() {
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class,
            new SapCalloutMockFactory(200, '{"ok":true,"maxDiscountPercent":7}'));

        SapMuleClient.DiscountResult d = SapMuleClient.descuentoVendedor(null);
        Assert.areEqual(7, d.maxDiscountPercent, 'GET con sellerCode nulo no explota (urlEncode).');
    }

    @isTest
    static void realModeConsultaMaterialesParsesArray() {
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class, new SapCalloutMockFactory(200,
            '[{"productCode":"M1","saldoDisponible":-3,"textoExistencia":"sin saldo"}]'));

        List<SapMuleClient.MaterialSaldo> saldos =
            SapMuleClient.consultaMateriales(new List<String>{ 'M1' }, 'C101', 'URUCA');
        Assert.areEqual(1, saldos.size(), 'Array del gateway deserializado.');
        Assert.areEqual(-3, saldos[0].saldoDisponible, 'Saldo negativo respetado tal cual.');
    }

    @isTest
    static void realModeHttpErrorThrows() {
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class,
            new SapCalloutMockFactory(404, '{"error":"ruta desconocida"}'));

        try {
            SapMuleClient.modificarPosicionesOrden('DBM-1', new List<SapMuleClient.SimulationLine>());
            Assert.fail('HTTP fuera de 2xx debe lanzar SapMuleClientException.');
        } catch (SapMuleClient.SapMuleClientException e) {
            Assert.isTrue(e.getMessage().contains('HTTP 404'),
                'El mensaje trae el status para triage: ' + e.getMessage());
        }
    }
}
