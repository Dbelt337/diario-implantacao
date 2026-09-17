# Inventário EPC/CPQ da org (somente leitura)

Uma consulta por arquivo: `sf data query -o btp-prod --json --file tools/catalogo/consultas/NN_*.soql > tools/catalogo/saida/NN.json`.
Antes das consultas, gerar os describes (os nomes de campo do pacote variam por versão; CMT 900.650.3 em produção):

```
sf sobject list -o btp-prod --sobject custom --json | findstr /i "vlocity_cmt__" > tools/catalogo/saida/objetos_vlocity.txt
for %o in (Product2 vlocity_cmt__ProductChildItem__c vlocity_cmt__ObjectClass__c vlocity_cmt__AttributeCategory__c vlocity_cmt__Attribute__c vlocity_cmt__AttributeAssignment__c vlocity_cmt__Picklist__c vlocity_cmt__PicklistValue__c vlocity_cmt__Catalog__c vlocity_cmt__CatalogProductRelationship__c vlocity_cmt__PriceList__c vlocity_cmt__PricingVariable__c vlocity_cmt__PricingElement__c vlocity_cmt__PriceListEntry__c vlocity_cmt__Promotion__c vlocity_cmt__PromotionItem__c vlocity_cmt__TimePlan__c vlocity_cmt__TimePolicy__c vlocity_cmt__CalculationMatrix__c vlocity_cmt__ContextDimension__c vlocity_cmt__ProductRelationship__c vlocity_cmt__DecompositionRelationship__c vlocity_cmt__OrchestrationPlanDefinition__c) do sf sobject describe -o btp-prod -s %o --json > tools/catalogo/saida/describe_%o.json
```

Se um campo de uma consulta não existir na org, remover o campo, anotar no relatório e seguir. Nenhum DML.
