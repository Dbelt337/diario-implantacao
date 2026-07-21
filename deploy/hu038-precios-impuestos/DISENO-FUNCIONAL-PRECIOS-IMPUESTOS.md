# Diseño funcional integral — Precios, Impuestos y Catálogo (HU-038 y relacionadas)

Material de trabajo para construir en conjunto con Grupo Q. Objetivo de la sesión:
dejar de refinar historia por historia y definir el **flujo completo de precios**
(Pricebook -> Cotización -> SAP), las **responsabilidades Salesforce vs SAP**, y el
**modelo de impuestos, exoneraciones y reglas de negocio** antes de seguir aprobando
las HU aisladas (38, 40, 41...).

Participantes de validación (Grupo Q): Luis Chavarría, Juan Carlos Mora, Norma Rivas
(principalmente el modelo de impuestos). Alineado con las recomendaciones de Felipe Pajón.

---

## 0. La pregunta de fondo que trae dudas al equipo

El equipo de Grupo Q hizo estas preguntas en el refinamiento:

- ¿Qué información se **carga manualmente**?
- ¿Qué calcula **Salesforce**?
- ¿Qué calcula **SAP**?
- ¿Los impuestos **se cargan** o **se calculan**? ¿Vienen de SAP?
- ¿Hay que definir **todos los impuestos por sociedad**?
- ¿Qué corresponde a **Pricebook**, a **Cotización**, a **Descuentos**?

La confusión nace de tratar "impuesto" como una sola cosa. En realidad hay **tres
capas distintas**, y cada pregunta se responde según la capa. Este documento separa
esas capas. Esa separación es el acuerdo principal a validar en la sesión.

---

## 1. El principio: tres capas (DATO / REGLA / CÁLCULO LEGAL)

Todo el modelo se apoya en separar tres cosas que hoy se mezclan:

| Capa | Qué es | Dónde vive | Quién lo mantiene | Se **carga** o se **calcula** |
|---|---|---|---|---|
| **DATO por vehículo** | Precio de lista, gastos, precio mínimo/exonerado, cashback | **PricebookEntry** (por sociedad) | Se **carga** desde SAP/QRM vía MuleSoft | Se **CARGA** (un valor por vehículo) |
| **REGLA por país/cliente** | La **tasa** de impuesto (%), la exoneración aplicable | **Decision Matrix** (Business Rules Engine) | El equipo de negocio (Norma / Juan Carlos) la mantiene | Se **DEFINE una vez**; la tasa se aplica por regla |
| **CÁLCULO LEGAL definitivo** | El impuesto exacto, auditable, con validez fiscal | **SAP** (autoridad fiscal) | SAP (lógica fiscal ya existente) | Se **CALCULA en SAP** al pedido/factura |

**Regla que separa las capas (una frase):**
> Valor por vehículo -> **PricebookEntry** · Regla por país/cliente -> **Decision Matrix** · Cálculo legal definitivo -> **SAP**

Esto responde directamente "¿el impuesto se carga o se calcula?": **ninguna de las
dos por separado**. La **tasa** se define en una matriz (una vez, por país/cliente);
el **monto de referencia** lo calcula Salesforce en la cotización (tasa x base); el
**monto legal definitivo** lo calcula SAP al facturar.

---

## 2. La decisión central: ¿Salesforce calcula todo, o SAP?

En la reunión se discutieron dos posiciones. La recomendación de este diseño es una
**tercera vía híbrida**, que es justamente lo que refleja el diagrama de Melisa.

| | Qué propone | Riesgo |
|---|---|---|
| **Opción 1** — SF calcula todo | Decision Matrices + BRE + Pricebook calculan el impuesto final en Salesforce | Duplicar la lógica fiscal legal en dos sistemas -> riesgo de cumplimiento (dos verdades fiscales) |
| **Opción 2** — SAP calcula todo | SF solo arma la cotización; el pedido va a SAP; SAP aplica toda la lógica y devuelve el precio | El asesor no tiene un precio inmediato para negociar sin ida y vuelta a SAP en cada iteración |
| **HÍBRIDO (recomendado)** | SF calcula un precio de **referencia comercial** para cotizar/negociar; SAP es la **autoridad fiscal** que calcula el impuesto **definitivo** al pedido | Requiere alinear "referencia" vs "definitivo" y un punto de reconciliación |

### Por qué el híbrido (y por qué es lo correcto native-first)

- El **cálculo legal del impuesto** (exacto, auditable, cambia con la legislación)
  **NO debe duplicarse** en Salesforce. SAP ya lo tiene. Mantener lógica fiscal en
  dos sistemas es el mayor riesgo de cumplimiento. -> **SAP sigue siendo la autoridad
  fiscal.** (Coincide con Juan Carlos.)
- Pero la **cotización comercial** necesita un número **inmediato** para negociar,
  aplicar descuentos dentro del precio mínimo, mostrar al cliente. No se puede llamar
  a SAP en cada tecla. -> Salesforce muestra un **precio de referencia** calculado con
  las Decision Matrices que el propio equipo comercial mantiene. (Aprovecha el BRE que
  ya está licenciado.)
- **Punto de reconciliación:** al generar el **Pedido**, el precio viaja a SAP; SAP
  devuelve el impuesto definitivo. Si difiere materialmente de la referencia, Salesforce
  lo marca. La factura siempre usa el número de SAP.

**En una línea:** Salesforce cotiza (referencia, rápido, negociable); SAP factura
(definitivo, legal, autoridad). El IPM se aplica en SAP según el precio enviado por
el CRM — tal como anotó Melisa.

---

## 3. El diagrama de Melisa — validado y afinado

El diagrama de Melisa es **correcto**. Solo se afinan dos cosas:

1. **La tasa de impuesto NO se guarda en el PricebookEntry.** En el diagrama aparece
   `ImpuestoPrimeraMatricula__c %` en el PBE. La recomendación es: en el PBE viven los
   **valores monetarios por vehículo** (precio de lista, `Gastos__c`, precio mínimo,
   exonerado, cashback). La **tasa (%)** es una **regla** y vive en la **Decision
   Matrix** — no se repite por cada PBE. Así, si cambia la tasa de un país, se cambia
   en un solo lugar (la matriz), no en miles de PBE.
2. **Falta la dimensión CLIENTE.** El diagrama tiene "País + Propulsión -> tasa". Pero
   Juan Carlos planteó (con razón) que hay **exoneraciones por cliente** (gobierno,
   diplomático, Ley 7600, etc.). Entonces la Decision Matrix necesita una **dimensión
   más: tipo de cliente**. Ver sección 4.

Con esos dos ajustes, el modelo de Melisa es exactamente el diseño propuesto.

---

## 4. El modelo de impuestos (lo que Grupo Q valida)

Este es el corazón de la sesión con Luis / Juan Carlos / Norma. La idea es que ellos
llenen los valores; nosotros aportamos la **estructura** (dimensiones de entrada y
salidas). Todo se implementa en **una** Decision Matrix por concepto, no en tablas
sueltas por sociedad.

### 4.1 Dimensiones de ENTRADA de la matriz (las columnas que deciden)

| Dimensión | Ejemplos de valor | Por qué |
|---|---|---|
| **País** | Costa Rica, El Salvador, Guatemala, Honduras... | La tasa y los impuestos cambian por país |
| **Sociedad** | C101 (CR)... | Normalmente mapea a país; sirve si dos sociedades del mismo país difieren |
| **Propulsión / tipo de vehículo** | Combustión, Híbrido, **Eléctrico** | CR: eléctrico tiene incentivo/tasa reducida (ver "4% eléctrico" del diagrama) |
| **Tipo de cliente** | Regular, **Gobierno**, Diplomático, Exonerado (Ley 7600), Flota... | Exoneraciones parciales o totales según el cliente (punto de Juan Carlos) |
| **(opcional) Rango de valor del vehículo** | tramos de precio | Si el impuesto es progresivo por valor |

### 4.2 SALIDAS de la matriz (lo que devuelve)

| Salida | Ejemplo | Uso |
|---|---|---|
| **% IVA aplicable** | 13% (CR general) | Cálculo de referencia en la cotización |
| **% Impuesto Primera Matrícula / ISC** | tasa por propulsión/país | Referencia; SAP hace el definitivo |
| **Tipo de exoneración** | Ninguna / Parcial / Total | Según tipo de cliente |
| **% exoneración** | 0% / 50% / 100% | Reduce la base gravable |
| **Regla de base gravable** | sobre qué monto se aplica | Alinea con SAP |

### 4.3 Ejemplo (para ilustrar — Grupo Q confirma los valores reales)

| País | Propulsión | Tipo cliente | % IVA | % IPM/ISC | Exoneración | % exon. |
|---|---|---|---|---|---|---|
| Costa Rica | Combustión | Regular | 13% | (a definir) | Ninguna | 0% |
| Costa Rica | **Eléctrico** | Regular | (incentivo) | **4%** | Parcial (Ley 9518) | (a definir) |
| Costa Rica | Combustión | **Gobierno** | 13% | (a definir) | Total/Parcial | (a definir) |
| Costa Rica | Combustión | **Ley 7600** | (a definir) | (a definir) | según ley | (a definir) |

> Los valores entre paréntesis los define Grupo Q. La plantilla `Matriz-Impuestos-Template.xlsx`
> tiene esta tabla con filas en blanco para llenar en la sesión.

### 4.4 Respuestas directas a las preguntas del equipo

- **¿Los impuestos se cargan o se calculan?** La **tasa** se define una vez en la
  matriz; el **monto de referencia** lo calcula Salesforce; el **monto legal** lo
  calcula SAP. (Sección 1.)
- **¿Vienen de SAP?** El **cálculo legal definitivo** sí (SAP autoridad fiscal). La
  **tasa de referencia** la mantiene negocio en la matriz de Salesforce.
- **¿Hay una historia específica para impuestos?** Recomendación: sí — que la
  **Decision Matrix de impuestos/exoneraciones** sea su propia HU, transversal, y que
  las HU 38/40/41 la **consuman**, no la redefinan cada una. (Ver sección 6.)
- **¿Hay que definir todos los impuestos por sociedad?** No por sociedad, sino **por
  país + tipo de cliente + propulsión** en una sola matriz. La sociedad es una columna
  más, no una tabla aparte.

---

## 5. El flujo completo de precios (extremo a extremo)

```
[SAP / QRM] --MuleSoft (lote + eventos)--> [Salesforce]
   material master + inventario (SAP)
   precio lista, gastos, minimo, exonerado, cashback (QRM)
        |
        v
  Capa DATO: PricebookEntry (por sociedad C101)  +  Product2 / VehicleDefinition
        |
        |     Capa REGLA: Decision Matrix (Pais + Propulsion + Tipo cliente -> tasa/exoneracion)
        |    /
        v   v
     COTIZACION (Salesforce)
       - precio de lista + gastos
       - impuesto de REFERENCIA (tasa de la matriz x base)
       - descuentos dentro del precio minimo del asesor
       - aprobacion si baja del minimo (Approval Process nativo)
        |
        v
     PEDIDO -> viaja a SAP
        |
        v
     SAP (AUTORIDAD FISCAL)
       - calcula el impuesto DEFINITIVO (IPM segun precio enviado por el CRM)
       - factura
       - devuelve precio definitivo a Salesforce (reconciliacion)
```

**Responsabilidades resumidas:**

| Etapa | Responsable | Sistema |
|---|---|---|
| Material + inventario | Carga | SAP -> (MuleSoft) -> SF |
| Precio lista / gastos / mínimo / exonerado / cashback | Carga | QRM -> (MuleSoft) -> PricebookEntry |
| Tasa de impuesto / exoneración (regla) | Define negocio | Decision Matrix (SF/BRE) |
| Precio y **impuesto de referencia** | Calcula | Salesforce (cotización) |
| Descuento y **aprobación** (baja del mínimo) | Controla | Salesforce (Approval Process) |
| **Impuesto definitivo / legal** | Calcula | **SAP** |
| Factura | Emite | **SAP** |

---

## 6. Qué historia resuelve qué (propuesta para destrabar el refinamiento)

La preocupación del equipo es que impuestos/gastos/descuentos/aprobaciones aparecen
mezclados entre las HU 38, 40, 41. Propuesta de asignación (a validar):

| Tema | HU sugerida | Nota |
|---|---|---|
| Estructura de catálogo (Pricebook, Product2, VehicleDefinition, sociedad) | HU-038 | Base de todo |
| **Impuestos y exoneraciones (Decision Matrix transversal)** | HU propia | Consumida por las demás; la valida Norma/Juan Carlos |
| Cotización (precio de referencia, gastos) | HU-040 (a confirmar) | Consume DATO + REGLA |
| Descuentos y aprobaciones | HU-041 (a confirmar) | Approval Process nativo |
| Integración pedido -> SAP y reconciliación | HU de integración | MuleSoft + callout |

La idea: **impuestos vive en UNA historia transversal**, no repartido. Las demás la
consumen. Así se aprueba cada HU entendiendo el panorama completo.

---

## 7. Decisiones abiertas a cerrar en la sesión

1. **Confirmar el modelo híbrido** (SF referencia + SAP autoridad) como acuerdo. Es la
   decisión que destraba todo lo demás.
2. **Dimensiones finales de la Decision Matrix**: ¿País + Sociedad + Propulsión + Tipo
   de cliente + (rango de valor)? Confirmar la lista de **tipos de cliente** con
   exoneración (gobierno, diplomático, Ley 7600, Ley 9518 eléctrico, flota...).
3. **Impuestos aplicables por país**: IVA, IPM/ISC, otros. Tasas y base gravable de cada
   uno. (Grupo Q llena la plantilla.)
4. **¿Salesforce muestra el impuesto de referencia al cliente/asesor, o solo precio
   sin impuesto + "impuesto lo confirma factura"?** Define cuánta lógica de referencia
   construimos.
5. **Reconciliación referencia vs definitivo**: ¿tolerancia? ¿qué pasa si SAP devuelve
   distinto? ¿se marca, se bloquea, se informa?
6. **Precio de lista base**: ¿viene de SAP o de QRM? (Frontera exacta SAP x QRM.)
7. **Cashback y vigencia**: ¿la matriz también resuelve cashback por fecha, o es campo
   del PBE (`AplicaCashback__c` / `MontoCashback__c` / `VigenciaDesde__c`, que ya existen)?
8. **Multimoneda**: CRC / USD y conversión — ¿dónde se hace la conversión?

---

## 8. Base técnica ya confirmada (para no reabrir)

- Catálogo **STANDARD**, sin EPC. Sin Revenue Cloud/CPQ.
- **BRE / Expression Sets / Decision Matrices están licenciados** -> el motor de reglas
  es construible de forma declarativa (sin Apex).
- **Los campos custom de precio del QRM YA EXISTEN en PricebookEntry**: `PrecioExonerado__c`,
  `PrecioExoneradoMinimo__c`, `PrecioMinimoAsesor__c`, `Gastos__c`, `AplicaCashback__c`,
  `MontoCashback__c`, `VigenciaDesde__c`. No se crean de nuevo.
- **Clave de match**: `Product2.ProductCode` = material SAP (MATNR), marcado External Id.
- Pricebook por sociedad (C101 / Costa Rica) ya creado.

---

## 9. Documentos que acompañan este material

- `Matriz-Impuestos-Template.xlsx` — plantilla para que Grupo Q llene el modelo de
  impuestos (dimensiones de entrada, salidas, exoneraciones por cliente, y la hoja de
  responsabilidades SF vs SAP).
- `flujo-precios-capas.svg` — el diagrama de capas (versión afinada del de Melisa, con
  la dimensión cliente).
- `../pricebooks-mulesoft/ANALISE-DOC-FELIPE-PRECOS.md` — análisis del doc de Felipe Pajón.
- `../pricebooks-mulesoft/SCHEMA-CATALOGO-CONFIRMADO.md` — esquema del catálogo (describe).
- `../pricebooks-mulesoft/DePara_Catalogo_Mule.xlsx` — de-para catálogo SAP/QRM -> Salesforce.
