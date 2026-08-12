# HU-038 — Administración de Precios y Price Books (Autos y Motos): como cobrimos

**Data:** 12/08/2026 · **Fontes:** HU038 V3, Refinamiento 13/07, sessão Dominio de Precios v4.1, Impuestos_SAP.xlsx (Luis Chavarría), Accesorios GrupoQ, gravações 22-23/07.

---

## A decisão central de arquitetura

**O maestro do preço NÃO pode ser o PricebookEntry puro.** A plataforma não suporta no PBE o que a HU exige:

| Exigência da HU | Suporte no PricebookEntry nativo |
|---|---|
| Aprovação (RN3, assimétrica) | ❌ PBE não suporta Approval Process |
| Histórico consultável / reconstruir preço numa data (Esc. 10) | ❌ sem Field History Tracking, sem versionamento |
| Vigência programada sem data fim (RN2, Esc. 14) | ❌ sem effective dating |
| Acesso restrito por marca (RN2/RN3) | ❌ Pricebook2 não tem sharing rules |
| Custo/margem com FLS só para gerência (RN10) | parcial (FLS existe, mas sem o resto não basta) |
| Trazabilidade: quem pediu, quem aprovou, com qué archivo (RN3) | ❌ |

**Modelagem: maestro custom + projeção nativa.**

- **`VehiclePriceEntry__c` ("Precio de Vehículo")** — objeto custom, UMA LINHA POR VERSÃO DE PREÇO, nunca deletada. Campos: lookup Product2 (versión), Marca, Sociedad (12: C101…P105), País, Canal (con impuesto/exonerado), Moneda, os **11 campos comerciais** (7 originais + Flotas, 2 custos, moneda de publicación), `VigenciaDesde__c`, `Estado__c` (Pendiente/Aprobado/Rechazado/Sustituido), solicitante, aprovador, data, arquivo de carga (ContentDocumentLink). Field History Tracking ligado.
- **PricebookEntry nativo = projeção publicada.** Job agendado diário (Scheduled Flow/Batch) publica no PBE da lista certa (sociedad+canal) o preço **Aprobado cuja vigência começou**, marca o anterior como `Sustituido` (Esc. 14) e espelha os pisos/gastos em custom fields do PBE para a cotização consumir. O fluxo comercial (venta guiada) continua 100% nativo — nada muda no que já construímos.
- É o mesmo padrão SF↔SAP da própria HU: um maestro governado + um consumidor que recebe o valor pronto.

## Mapa RN → solução

| RN | Solução |
|---|---|
| **RN1** 11 campos comerciais | Custom fields no maestro; espelho no PBE (pisos, gastos, % 1ª matrícula) para HU de cotização. Accesorios: lista independente (JÁ EXISTE no nosso fluxo — pricebook da sociedad, Esc. 20 coberto) |
| **RN2** segmentação + vigência + histórico | Pricebook2 por **Sociedad+Canal**; marca = atributo do produto (regra estrutural da própria HU). Vigência: `VigenciaDesde` sem data fim + job de publicação. Histórico = linhas versionadas do maestro (Esc. 10 = query por data) |
| **RN2/RN3** acesso por marca | **No maestro**, via sharing rules por Marca + permission sets (nativo Pricebook2 não suporta sharing — ver "decisões a validar") |
| **RN3** aprovação assimétrica | Record-Triggered Flow compara com o vigente: algum dos **5 campos baixou** → Approval Process com aprovador dinâmico por marca (objeto `Marca__c` com lookup ao Gerente de Producto/Marca); subiu ou só gastos/% → ativa direto. Em bloque: list view + aprovação massiva via Flow. Notificações nativas do approval |
| **RN3** bloqueio comercial | Esta HU **provê o estado**: `PricingService.getPrecioVigente(producto, sociedad, canal, fecha)` devolve o preço Aprobado+vigente ou `BLOQUEADO` com motivo — `searchVehicles`/`getPricePageData` (nossos stubs do guided selling) consomem e mostram a alerta. Esc. 6/6b/6-novo cobertos: existe vigente → cotiza com ele; não existe → bloqueia |
| **RN4** carga masiva | LWC `cargaPrecios` (upload da plantilla CSV) + Apex: valida fila a fila, cria maestros `Pendiente`, devolve **o mesmo arquivo + coluna Motivo** (ContentVersion para download). Mesmo padrão do grid HU-043. Arquivo fica anexado à solicitação (trazabilidade RN3) |
| **RN5** impostos | **Decision Matrix (BRE)** — a própria HU nomeia: (1) `TasaImpuestoPais` (País+Característica+CondiciónCliente → tasa; ex.: elétrico CR 4%, accesorios 13% — Esc. 15/16), editável e versionada pelo admin SEM deploy; (2) `PrimeraMatricula` (tipo vehículo → rango personas/carta porte + cilindraje — anexo do Luis). A planilha **Impuestos_SAP (KSCHL/ALAND/TAXK1/MWSK1)** é o de-para de códigos SAP: carga inicial das matrizes. PricingService já contempla BRE |
| **RN6** multi-moeda + redondeo | Org multi-currency + DatedConversionRate; `MonedaPublicacion__c` no Product2 (modelo — prevalece sobre a da sociedad, Esc. 17); conversão automática na carga (Esc. 18). Guatemala GTQ+USD = duas PBEs por produto (nativo). Redondeo: Custom Metadata `ReglaRedondeo__mdt` por sociedad+moneda espelhando SAP (pricing 4 decimais, posições 2) — usada por PricingService e pela carga |
| **RN7** consumo | HUs de Guided Selling/Cotización (nossa arquitetura atual já é o consumidor) |
| **RN8** reporte | Report Type sobre o maestro: marca, modelo, fecha, aprobador, país, precios — Reports padrão, sem número de inventário |
| **RN9** níveis por fator | Decision Matrix `FactoresNivelesPrecio` (versão+vigência editável): calcula Mín. Gerente Ventas/Marca/Director ao salvar (Esc. 12); VP sem piso. HU-064/065 consomem |
| **RN10** custo e margem | `CostoEstimado__c` + `CostoEstimadoExonerado__c` + fórmulas `Margen__c`/`MargenExonerado__c` no maestro; **FLS via PS_Precios_Margen** (Gerente Marca/Ventas/Director/VP); visíveis no layout da aprovação, nunca na lista comercial (Esc. 13/19) |

## O que já construímos que encaixa direto

- Pricebook nativo consumido pela venta guiada (QLI→PBE) — a projeção publicada cai em cima do que existe.
- `PricingService` com BRE de referência — recebe as Decision Matrices.
- `CountryCurrency__mdt` (moedas por país) + validation rule — RN6.
- Padrão de carga com feedback fila a fila (grid HU-043) — RN4 reusa o desenho.
- Cadeia Product2→VehicleDefinition (catálogo HU-041) — o preço pendura na versión.
- Plan de carga (docs/carga): as listas por sociedad/canal da fila 2 são exatamente os PBEs desta HU.

## Ordem de construção sugerida (sprints)

1. **Fundação:** `Marca__c` + `VehiclePriceEntry__c` + FLS/permission sets + Field History (FO-09/FO-10).
2. **Aprovação:** flow de disparo assimétrico + Approval Process por marca + aprovação em bloque + notificações.
3. **Publicação:** job de vigência (maestro→PBE) + estado para o guided selling (`getPrecioVigente`).
4. **Matrizes:** Decision Matrices (tasas, 1ª matrícula, factores) + carga inicial do Impuestos_SAP.xlsx + `ReglaRedondeo__mdt`.
5. **Carga masiva:** LWC plantilla + arquivo de retorno com motivos.
6. **Reporte** gerencial + testes (aprovação assimétrica, vigência, histórico por data, conversão de moeda, margem FLS).

## Decisões a validar (não são dev)

1. **Acesso por marca nas listas NATIVAS é impossível** (Pricebook2 sem sharing) — a restrição vive no maestro; as listas publicadas ficam legíveis para o comercial. Validar com GrupoQ que isso atende o "solo administra y visualiza los precios de su marca" (administrar sim; *visualizar* o preço publicado é aberto por natureza — o asesor precisa dele para cotizar).
2. A HU tem uma tensão interna: "marca no multiplica listas" (RN2) vs "Pricebooks separados por marca" (RN2/criterios). A modelagem resolve com listas por sociedad+canal e governo por marca no maestro — confirmar com a Melisa/Hugo.
3. "Gastos: se carga para algunas sociedades y para otras se calcula — **Definir**" (aberto da sessão de domínio).
4. Regra de redondeo oficial por sociedad+moneda (insumo GrupoQ, igual à do SAP).
5. Se a plataforma exigir data fim: default 3 meses (a HU já prevê o fallback — só se aplica se usarmos feature com data fim obrigatória; no maestro custom não é o caso).
