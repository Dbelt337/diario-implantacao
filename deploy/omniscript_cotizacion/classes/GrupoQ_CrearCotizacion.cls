/**
 * HU-014 v1 - Remote Action del OmniScript "GrupoQ/CrearCotizacion".
 * Es el "hijo" headless que hace el DML: crea una Quote nativa a partir del
 * registro de contexto. Cubre en un solo punto:
 *   - Cuenta (prefijo 001): Persona Natural Y Business -> Quote.AccountId directo.
 *   - Oportunidad (prefijo 006): Quote.OpportunityId (AccountId lo deriva Salesforce).
 * OmniStudio Standard Runtime -> implementa System.Callable.
 */
global with sharing class GrupoQ_CrearCotizacion implements System.Callable {

    // Punto de entrada que invoca la Remote Action del OmniScript.
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>) args.get('input');
        Map<String, Object> output  = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }

    public Boolean invokeMethod(String methodName,
                                Map<String, Object> input,
                                Map<String, Object> output,
                                Map<String, Object> options) {
        if (methodName == 'crearCotizacion') {
            return crearCotizacion(input, output);
        }
        output.put('error', 'Metodo no soportado: ' + methodName);
        return false;
    }

    private Boolean crearCotizacion(Map<String, Object> input, Map<String, Object> output) {
        String contextId = firstNonBlank(new List<String>{
            (String) input.get('ContextId'),
            (String) input.get('contextId'),
            (String) input.get('recordId')
        });
        if (String.isBlank(contextId)) {
            output.put('error', 'Falta ContextId (Id de Cuenta u Oportunidad).');
            return false;
        }

        String prefix = contextId.length() >= 3 ? contextId.substring(0, 3) : '';
        Date hoy = Date.today();
        String qName = 'Cotizacion ' + hoy.format();

        Quote q = new Quote(
            Name = qName,
            Status = 'Draft',
            ExpirationDate = hoy.addDays(30)
        );

        try {
            if (prefix == '006') {
                q.OpportunityId = Id.valueOf(contextId);
            } else if (prefix == '001') {
                q.AccountId = Id.valueOf(contextId); // Person Account y Business comparten 001
            } else {
                output.put('error', 'Contexto no soportado (prefijo ' + prefix +
                    '). Se espera Cuenta (001) u Oportunidad (006).');
                return false;
            }
            insert q;
        } catch (Exception e) {
            output.put('error', e.getMessage());
            return false;
        }

        output.put('quoteId', q.Id);
        output.put('quoteName', qName);
        return true;
    }

    private String firstNonBlank(List<String> values) {
        for (String v : values) {
            if (String.isNotBlank(v)) return v;
        }
        return null;
    }
}
