/**
 * All countries. Bridge between OmniStudio (Integration Procedure Remote
 * Action) and the org's standard document generation invocable action
 * (Salesforce Contracts / Industries Document Generation - server-side PDF
 * enabled in Document Generation Settings). The invocable action NAME is a
 * parameter on purpose: the exact developer name varies by release, so the
 * value observed in Flow Builder is configured in the IP without touching
 * code. Used by HU-037 (test drive authorization); template and tokens are
 * inputs, so any future document reuses this same bridge.
 */
public with sharing class DocumentGenerationUtil implements Callable {

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');

        if (action == 'generateDocument') {
            output.putAll(generateDocument(input));
            return true;
        }
        output.put('error', 'Unknown action: ' + action);
        return false;
    }

    /**
     * Invokes the standard generation action by name with the template,
     * anchor record and token payload assembled by the DataRaptor.
     * Expected input keys: actionName, templateApiName, recordId,
     * tokenDataJson, convertToPdf.
     * Output: success, contentDocumentId (when the action returns it) or
     * errorMessage.
     */
    private Map<String, Object> generateDocument(Map<String, Object> input) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false
        };
        try {
            String actionName = (String) input.get('actionName');
            if (String.isBlank(actionName)) {
                result.put('errorMessage', 'actionName is required (see Flow Builder action list).');
                return result;
            }

            Invocable.Action gen = Invocable.Action.createStandardAction(actionName);
            // Common parameter names across docgen invocable versions; the
            // action ignores unknown parameters, so both spellings travel.
            gen.setInvocationParameter('recordId', (String) input.get('recordId'));
            gen.setInvocationParameter('documentTemplateApiName', (String) input.get('templateApiName'));
            gen.setInvocationParameter('documentTemplateName', (String) input.get('templateApiName'));
            if (input.get('tokenDataJson') != null) {
                gen.setInvocationParameter('tokenData', (String) input.get('tokenDataJson'));
            }
            Object convertToPdf = input.get('convertToPdf');
            gen.setInvocationParameter('generatePdf',
                convertToPdf == null ? true : Boolean.valueOf(String.valueOf(convertToPdf)));

            List<Invocable.Action.Result> results = gen.invoke();
            if (results.isEmpty()) {
                result.put('errorMessage', 'Generation action returned no result.');
                return result;
            }

            Invocable.Action.Result r = results[0];
            if (!r.isSuccess()) {
                String msg = '';
                for (Invocable.Action.Error e : r.getErrors()) {
                    msg += e.getMessage() + ' ';
                }
                result.put('errorMessage', msg.trim());
                return result;
            }

            result.put('success', true);
            // Output parameter names also vary by version; expose them all
            // so the Integration Procedure maps whichever comes populated.
            Map<String, Object> outs = r.getOutputParameters();
            if (outs != null) {
                for (String key : outs.keySet()) {
                    result.put(key, outs.get(key));
                }
            }
            return result;
        } catch (Exception e) {
            result.put('errorMessage', e.getMessage());
            return result;
        }
    }
}
