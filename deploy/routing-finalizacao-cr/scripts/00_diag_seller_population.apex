/* =====================================================================
 * 00_diag_seller_population.apex   (READ-ONLY / nenhum DML)
 * ---------------------------------------------------------------------
 * Objetivo: ANTES de provisionar ServiceResource / ServiceResourceSkill,
 * validar com dados reais:
 *   1) os API names EXATOS dos campos do User que vamos usar
 *      (resolvidos via Schema, pra nunca referenciar campo inexistente);
 *   2) a populacao de vendedores candidata;
 *   3) a derivacao de LINHA (TipoAutoQueVende__c -> Autos/Usados/Frotas);
 *   4) a derivacao de MARCAS por vendedor via Brand_Sociedad_Map__mdt
 *      (Country_Code__c = 'CR', invertendo Sociedad -> Brands).
 *
 * Rode em Setup > Developer Console > Debug > Open Execute Anonymous,
 * marque "Open Log", e olhe os USER_DEBUG. Nada e' gravado.
 * ===================================================================== */

final String COUNTRY = 'CR';

/* ---------- 1) Resolver API names dos campos do User via Schema -------- */
Map<String, Schema.SObjectField> uFields = Schema.SObjectType.User.fields.getMap();
System.debug('===== CAMPOS CUSTOM DO USER (label -> apiName) =====');
String flotasApi = null;
for (String f : uFields.keySet()) {
    Schema.DescribeFieldResult d = uFields.get(f).getDescribe();
    if (d.isCustom()) {
        System.debug(d.getLabel() + '  ->  ' + d.getName() + '  (' + d.getType() + ')');
        String lbl = d.getLabel().toLowerCase();
        if (lbl.contains('flota')) { flotasApi = d.getName(); }
    }
}
System.debug('Campo "Pertence a Flotas" resolvido como: ' + flotasApi);

/* ---------- 2) Mapa Sociedade -> Marcas (CR), via MDT ------------------ */
Map<String, Set<String>> sociedadToBrands = new Map<String, Set<String>>();
for (Brand_Sociedad_Map__mdt m : [
        SELECT Brand__c, Sociedad__c, Country_Code__c
        FROM Brand_Sociedad_Map__mdt
        WHERE Country_Code__c = :COUNTRY]) {
    if (m.Brand__c == 'Usados') continue;          // Usados = linha, nao skill de marca
    if (!sociedadToBrands.containsKey(m.Sociedad__c)) {
        sociedadToBrands.put(m.Sociedad__c, new Set<String>());
    }
    sociedadToBrands.get(m.Sociedad__c).add(m.Brand__c);
}
System.debug('===== INVERSAO Sociedade -> Marcas (CR) =====');
for (String soc : sociedadToBrands.keySet()) {
    System.debug(soc + ' -> ' + sociedadToBrands.get(soc));
}

/* ---------- 3) Populacao candidata de vendedores ---------------------- */
/* Candidato = User ativo, com Sociedad__c preenchida e TipoAutoQueVende__c
 * preenchido. Ajustamos o filtro depois de validar os numeros.        */
List<User> sellers = [
    SELECT Id, Name, IsActive, Sociedad__c, TipoAutoQueVende__c,
           VendedorOnline__c, Canal__c
    FROM User
    WHERE IsActive = true
      AND Sociedad__c != null
      AND TipoAutoQueVende__c != null
    ORDER BY Sociedad__c, Name
];
System.debug('===== TOTAL vendedores candidatos: ' + sellers.size() + ' =====');

Integer semMapaSociedade = 0;
for (User u : sellers) {
    /* Linha a partir de TipoAutoQueVende__c */
    Set<String> linhas = new Set<String>();
    String tipo = u.TipoAutoQueVende__c;
    if (tipo == 'Nuevo')      linhas.add('Autos');
    else if (tipo == 'Usado') linhas.add('Usados');
    else if (tipo == 'Ambos') { linhas.add('Autos'); linhas.add('Usados'); }

    /* Marcas a partir da Sociedade (CR) */
    Set<String> brands = sociedadToBrands.get(u.Sociedad__c);
    if (brands == null) { brands = new Set<String>(); semMapaSociedade++; }

    System.debug(
        u.Name + ' | Soc=' + u.Sociedad__c +
        ' | Tipo=' + tipo + ' -> Linhas=' + linhas +
        ' | Online=' + u.VendedorOnline__c +
        ' | Marcas=' + brands
    );
}
System.debug('Vendedores cuja Sociedade NAO esta no mapa CR: ' + semMapaSociedade);

/* ---------- 4) ServiceResource ja existentes (nao recriar) ----------- */
List<ServiceResource> existing = [
    SELECT Id, Name, RelatedRecordId, IsActive
    FROM ServiceResource
    WHERE RelatedRecordId IN :(new Map<Id,User>(sellers)).keySet()
];
System.debug('===== ServiceResource ja existentes para esses users: ' + existing.size() + ' =====');
for (ServiceResource sr : existing) {
    System.debug('SR ' + sr.Name + ' user=' + sr.RelatedRecordId + ' active=' + sr.IsActive);
}
System.debug('===== FIM DO DIAGNOSTICO (nenhum dado gravado) =====');
