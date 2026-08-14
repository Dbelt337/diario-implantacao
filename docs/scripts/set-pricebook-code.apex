/**
 * Rellena PricebookCode__c en los price books existentes.
 *
 * Correr DESPUES de desplegar deploy-pricebookentry-pricekey.zip,
 * y correrlo en CADA org: INT, DEV Sales, QA y produccion, con los MISMOS
 * codigos. Ese es el punto del campo: el codigo es igual en todas partes,
 * el Id no.
 *
 * EDITAR el mapa de abajo antes de ejecutar. La clave es el nombre exacto
 * del price book y el valor es el codigo de negocio que la integracion va a
 * enviar. Confirmar esos codigos con el equipo de MuleSoft y con SAP antes
 * de correr, porque si no coinciden el upsert no encuentra nada.
 *
 * Es idempotente: se puede correr las veces que haga falta.
 */

Map<String, String> codigoPorNombre = new Map<String, String>{
    'Standard Price Book'            => 'STANDARD',
    'C101 - Vehiculos y Motos (CR)'  => 'C101'
    // agregar aqui el resto de las listas por sociedad
};

List<Pricebook2> aActualizar = new List<Pricebook2>();
List<String> sinCodigo = new List<String>();

for (Pricebook2 pb : [SELECT Id, Name, IsStandard, PricebookCode__c FROM Pricebook2]) {
    String codigo = codigoPorNombre.get(pb.Name);
    if (codigo == null) {
        sinCodigo.add(pb.Name);
        continue;
    }
    if (pb.PricebookCode__c == codigo) {
        System.debug('sin cambios : ' + pb.Name + ' ya tiene ' + codigo);
        continue;
    }
    pb.PricebookCode__c = codigo;
    aActualizar.add(pb);
}

if (!sinCodigo.isEmpty()) {
    System.debug('ATENCION, price books sin codigo definido en el mapa: ' + sinCodigo);
    System.debug('Agregarlos al mapa antes de dar por cerrada la configuracion, '
        + 'porque la integracion no va a poder direccionarlos.');
}

if (aActualizar.isEmpty()) {
    System.debug('Nada por actualizar.');
} else {
    List<Database.SaveResult> res = Database.update(aActualizar, false);
    for (Integer i = 0; i < res.size(); i++) {
        if (res[i].isSuccess()) {
            System.debug('OK    : ' + aActualizar[i].Name + ' => ' + aActualizar[i].PricebookCode__c);
        } else {
            System.debug('FALLO : ' + aActualizar[i].Name + ' : ' + res[i].getErrors()[0].getMessage());
        }
    }
}

System.debug('----- ESTADO FINAL -----');
for (Pricebook2 pb : [SELECT Name, IsStandard, IsActive, PricebookCode__c
                      FROM Pricebook2 ORDER BY Name]) {
    System.debug(pb.Name + ' | codigo=' + pb.PricebookCode__c
        + ' | standard=' + pb.IsStandard + ' | activo=' + pb.IsActive);
}
