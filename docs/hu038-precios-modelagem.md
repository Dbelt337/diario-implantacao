# HU-038 — Administración de Precios y Price Books (Autos y Motos): modelagem 100% nativa

**Data:** 12/08/2026 · **v2 — SEM objeto custom** (decisão Diego), fundamentada nos textos oficiais:
Automotive Cloud Standard Objects, PricebookEntry Object Reference, Salesforce Pricing Standard Objects (RLM), Limits and Considerations for Classic Approval Processes.
**Fontes de negócio:** HU038 V3, Refinamiento 13/07, sessão Dominio de Precios v4.1, Impuestos_SAP.xlsx, Accesorios GrupoQ.

---

## O que a documentação oficial estabelece (com as correções que ela impôs)

1. **Automotive Cloud NÃO tem objeto de preço próprio.** A lista completa de Standard Objects do Automotive (Vehicle, VehicleDefinition, Appraisal, Fleet, Claim, Telemetry…) não contém nenhum objeto de pricing — o Automotive usa o Pricebook2/PricebookEntry da plataforma. Nossa venta guiada já está no modelo certo.
2. **PricebookEntry SUPORTA Field History Tracking** (`PricebookEntryHistory` — "History is available for tracked fields of the object") e Change Data Capture (`PricebookEntryChangeEvent`, v57+). CORREÇÃO da análise anterior: o histórico nativo existe.
3. **Restrição estrutural do PBE (Object Reference):** "Create ONE PricebookEntry record for each standard or custom price AND CURRENCY combination for a product in a Pricebook2" — uma entrada por produto+lista+moeda. Preço vigente e preço pendente NÃO podem ser duas linhas na mesma lista. É esta restrição que desenha a solução de staging abaixo.
4. **Existe o modelo Salesforce Pricing (RLM):** CostBook/CostBookEntry (custos), ProductPriceHistoryLog e ProductPriceRange (histórico/faixa de preço), PriceAdjustmentSchedule/Tier, PriceRevisionPolicy (revisão de preços com vigência e fórmula), PricingProcedure. **Depende de licença** — verificar na org (GAPCHECK4 abaixo).
5. **Approvals:** a doc oficial recomenda **Flow Approval Processes** no lugar do clássico — "can trigger on record changes… unlike Classic Approval Processes, which are TIED TO SPECIFIC OBJECTS". O clássico não suporta PBE; o moderno remove a lista fechada.

---

## A modelagem (nativa, zero objetos novos)

### Estrutura: listas oficiais + listas de staging por marca

- **Listas oficiais por sociedad+canal** (12 sociedades × canal com impuesto/exonerado) — as MESMAS que a venta guiada consome hoje e que estão no plano de carga (fila 2). Marca é atributo do Product2 (regra estrutural da própria HU: "la marca no multiplica listas").
- **Listas de STAGING por marca** ("Precios Pendientes — Hyundai", etc.): o preço NOVO entra aqui como PBE, com os campos de controle. Resolve as duas coisas de uma vez, dentro da restrição de plataforma (item 3):
  - *Pendente vs vigente coexistem* (linhas em listas diferentes);
  - *Acesso por marca*: o responsável da marca trabalha só na staging da sua marca (permissão por perfil/permission set nas listas staging); as listas oficiais são de leitura para o comercial — o asesor precisa do preço publicado para cotizar.
- **Publicação = cópia staging → oficial**, feita por Scheduled Flow diário quando `Estado='Aprobado'` e `VigenciaDesde <= HOY` (Esc. 14: o novo preço rege automaticamente ao iniciar a vigência). A PBE staging vira `Publicado`.

### Campos (custom FIELDS em objetos padrão — permitido, mesmo padrão de QLI/Order)

**No PricebookEntry** (staging e oficial):
- Os **11 campos comerciais**: `UnitPrice` = Precio de Lista (nativo) + `PrecioMinimoAsesor__c`, `MontoCashback__c` (+ indicador web + vigência do cashback), `PrecioExonerado__c`, `PrecioExoneradoMinimo__c`, `Gastos__c`, `ImpuestoPrimeraMatricula__c` (%), `PrecioFlotas__c`, `CostoEstimado__c`, `CostoEstimadoExonerado__c` (FLS!), + fórmulas `Margen__c`/`MargenExonerado__c` (FLS).
- Controle (staging): `Estado__c` (Pendiente/Aprobado/Rechazado/Publicado), `VigenciaDesde__c`, `MotivoRechazo__c`.
- **Field History Tracking ligado** nos campos comerciais → `PricebookEntryHistory` = o histórico exigido (quem, quando, valor anterior — Esc. 10 reconstruível por query no history).
- **FLS de custo/margem** via permission set `PS_Precios_Margen` (Gerente Marca/Ventas/Director/VP) — o asesor não vê (RN10/Esc. 13/19). FLS em custom field de PBE é suportado.

**No Product2:** `Marca__c` (se não existir — verificar o que o Automotive já adiciona no Product2), `MonedaPublicacion__c` (RN6/Esc. 17 — prevalece sobre a da sociedad; aplica ao modelo e versões).

**No Pricebook2 (staging):** `MarcaPropietaria__c`, `AprobadorMarca__c` (lookup User) — o aprovador dinâmico por marca SEM objeto novo (RN3: Gerente de Producto/Marca).

### Aprovação assimétrica (RN3)

- Submissão (botão na staging ou no save da carga): Flow compara os **5 campos disparadores** com a PBE oficial vigente do mesmo produto+moeda:
  - algum **BAIXOU** → **Flow Approval Process** (o moderno, recomendado pela doc — dispara em record change e não tem lista fechada de objetos) com aprovador = `AprobadorMarca__c` da lista staging; notificações nativas ao solicitante (aprovado/rechazado, com comentário).
  - **subiu**, ou só mudou `Gastos__c`/`% 1ª matrícula` → `Estado='Aprobado'` direto (Esc. 2).
- Aprovação **em bloque**: list view da staging + ação massiva de aprovação (Esc. 4).
- Trazabilidade "con qué archivo": o CSV da carga anexado (ContentDocumentLink) à PBE staging / à solicitação.
- **Bloqueio comercial**: `PricingService.getPrecioVigente(producto, sociedad, canal, fecha)` — devolve a PBE oficial ativa ou `BLOQUEADO` ("lista pendiente de autorización") quando só existe staging pendente (Esc. 6/6b). O guided selling consome (nossos stubs `searchVehicles`/`getPricePageData`).

### Impostos, fatores e redondeo (RN5/RN9/RN6)

- **Decision Matrix (BRE)** — a HU nomeia a ferramenta, nativa do Automotive/Industries, editável sem deploy:
  1. `TasaImpuestoPais` (País+Característica+CondiciónCliente → tasa; elétrico CR 4%, acessórios 13% — Esc. 15/16). Carga inicial = Impuestos_SAP.xlsx (KSCHL/ALAND/TAXK1/MWSK1).
  2. `PrimeraMatricula` (tipo vehículo → rango personas/carta porte + cilindraje — anexo do Luis).
  3. `FactoresNivelesPrecio` (Esc. 12 — mínimos de Gerente Ventas/Marca/Director por fator; VP sem piso). HU-064/065 consomem.
- **Redondeo por sociedad+moneda** espelhando SAP (pricing 4 decimais, posições 2): `ReglaRedondeo__mdt` (Custom Metadata — configuração, não objeto de dados).
- **Multi-moeda**: org multi-currency + DatedConversionRate; conversão automática na carga quando a moeda do arquivo difere da `MonedaPublicacion__c` (Esc. 18); Guatemala GTQ+USD = duas PBEs por produto (exatamente o que o modelo nativo prevê: uma por moeda).

### Carga masiva (RN4) e reporte (RN8)

- LWC `cargaPrecios`: upload da plantilla → PBEs na staging da marca em `Pendiente` → contagem de corretas + **o mesmo arquivo devolvido com coluna de motivo por fila** (ContentVersion). Padrão já provado na HU-043.
- Reporte gerencial: Report Type PBE com Product2/Pricebook2 (marca, modelo, fecha, aprobador, país, precios; sem número de inventário) + relatório de histórico (PricebookEntryHistory).

### Upgrade opcional se a licença RLM estiver na org (GAPCHECK4)

- `CostBook`/`CostBookEntry` no lugar dos campos de custo no PBE (separação natural + segurança por objeto em vez de FLS);
- `ProductPriceHistoryLog`/`ProductPriceRange` complementando o histórico;
- `PriceRevisionPolicy` para revisões programadas com fórmula.
Nada disso muda a espinha (staging→oficial + BRE); só substitui pedaços por peças ainda mais nativas.

---

## GAPCHECK4 — rodar na org (Execute Anonymous, filtrar "GAPCHECK4")

```apex
List<String> r = new List<String>();
r.add('=============== GAPCHECK4 ===============');
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
// 1. RLM Pricing disponível?
for (String obj : new List<String>{'CostBook','CostBookEntry','PriceAdjustmentSchedule',
        'ProductPriceHistoryLog','ProductPriceRange','PriceRevisionPolicy','ProductSellingModel'}) {
    r.add((gd.get(obj.toLowerCase()) != null ? '[SI]  ' : '[NO]  ') + obj);
}
// 2. Campos que o Automotive já dá no Product2 (marca/moeda podem já existir)
if (gd.get('product2') != null) {
    List<String> custom = new List<String>();
    for (Schema.SObjectField f : gd.get('product2').getDescribe().fields.getMap().values()) {
        String n = f.getDescribe().getName().toLowerCase();
        if (n.contains('brand') || n.contains('marca') || n.contains('make')
                || n.contains('model') || n.contains('trim') || n.contains('series')) {
            custom.add(f.getDescribe().getName());
        }
    }
    r.add('[INFO] Product2 campos de marca/modelo: ' + String.join(custom, ', '));
}
// 3. Decision Matrix / Expression Set (BRE) habilitados?
for (String obj : new List<String>{'CalculationMatrix','CalculationMatrixVersion','ExpressionSet'}) {
    r.add((gd.get(obj.toLowerCase()) != null ? '[SI]  ' : '[NO]  ') + obj);
}
r.add('=========================================');
System.debug(LoggingLevel.ERROR, '\n' + String.join(r, '\n'));
```

## Decisões a validar (negócio, não dev)

1. Acesso por marca = staging por marca + oficiais legíveis pelo comercial (o asesor precisa do preço publicado). Validar que atende "solo administra y visualiza los precios de su marca".
2. Gastos: "se carga para algunas sociedades y para otras se calcula — Definir" (aberto da sessão de domínio).
3. Regra oficial de redondeo por sociedad+moneda (insumo GrupoQ, igual ao SAP).
4. Se RLM estiver licenciado (GAPCHECK4), decidir os upgrades opcionais.
