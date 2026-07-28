# HU-042 — Guion de pruebas (seleccion de vehiculo a cotizar, esqueleto v16)

Prerrequisitos: paquete v16 desplegado; Flow "Inventory Exhausted
Notification" ACTIVADO; PS "Ver cantidades de inventario" asignado al
usuario de PISO de prueba (y NO asignado al usuario online de prueba);
logout/login despues de asignar el PS (el permiso se evalua al cargar).

## P1 — Filtros y busqueda (RN-02)
1. Opportunity > accion Venta guiada > Vehiculo nuevo > paso Vehiculo.
2. Filtrar Marca = Chevrolet: la tabla muestra solo el Groove LT.
3. Filtrar Año = 2027: solo Santa Fe e Ioniq 6 (con Marca en Todas).
4. Buscar "Tucson": quedan las tres Tucson. Buscar por color ("Rojo")
   tambien filtra. Limpiar filtros restaura la lista completa (7 modelos).

## P2 — Colores exterior e interior (RN-03)
1. La tabla de nuevos muestra las columnas Color exterior y Color interior.
2. Esperado: cada modelo con sus dos colores (ej. Tucson Limited: Gris
   Titanio / Beige).

## P3 — Cantidades tras el permiso (T04, RN-03)
1. Con el usuario de PISO (PS asignado + relogin): la tabla muestra las
   columnas Stock Central y Stock Sucursal; el panel del paso Precio
   muestra las unidades por ubicacion.
2. Con el usuario ONLINE (sin PS): las columnas NO aparecen; el panel
   muestra "Disponible en: ..." con la nota de permiso, y los colores y
   transito siguen visibles (disponibilidad cualitativa para todos).

## P4 — Estados del boton final segun disponibilidad (HU-044)
Con cada vehiculo, avanzar hasta Cotizacion y verificar el boton:
1. Tucson GLS 2.0 (stock) = "Crear cotizacion" (azul).
2. Tucson Hibrida (0 stock, 2 en transito) = "Crear cotizacion con unidad
   en transito"; el resumen muestra ETA 15/09/2026.
3. Santa Fe (0 stock, recepcion futura) = "Crear cotizacion futura"; el
   resumen muestra "recepcion futura: 2 unidades el 29/08/2026".
4. Ioniq 6 (sin nada) = "Crear cotizacion y solicitar unidad"; el resumen
   indica que la cotizacion registra la solicitud (HU-044).
5. En todos los casos la cotizacion PROCEDE (sin bloqueo — RN-04/A2/A3).

## P5 — Catalogo de accesorios asociado al vehiculo
1. Seleccionar Tucson GLS > paso Accesorios: catalogo compatible con el
   modelo (con rack y estribos), agrupado por categoria.
2. Volver y seleccionar Creta: el catalogo recarga (camara y sensor,
   sin rack) y la seleccion anterior se limpia.
3. Marcar accesorios: total en vivo; suman al desglose de precio y al
   resumen de la cotizacion como lineas.

## P6 — Cambio de version antes de emitir (RN-06, Escenario 5)
1. Avanzar con una version hasta Descuento; volver al paso Vehiculo y
   seleccionar otra version.
2. Esperado: precios recalculan sobre la nueva version; accesorios se
   limpian (catalogo distinto); el chip del tope refleja el nuevo modelo.
   (Real: cada emision = nueva Quote en la MISMA Opportunity; historial
   por Field History.)

## P7 — Flow de inventario agotado (T06)
1. Setup > Flows > Inventory Exhausted Notification > Debug.
2. Inputs: RecipientId = Id de tu usuario; ProductCode = OCN-TEST;
   ProductName = Tucson GLS 2.0; TargetRecordId = Id de un Product2.
3. Esperado: notificacion (campana) "Inventario agotado: Tucson GLS 2.0"
   con el texto de evaluar la desactivacion. La decision es humana: el
   flujo NO desactiva ningun codigo.

## P8 — Record Types de Quote (T02)
1. Tras configurar el trio (perfiles + layout assignment): crear una Quote
   manual en una Opportunity y verificar que ofrece los RT "Vehiculo
   Nuevo" y "Vehiculo Usado".
