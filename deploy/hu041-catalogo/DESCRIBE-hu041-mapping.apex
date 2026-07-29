// HU-041 — Validacion del Field Mapping Preliminar (MuleSoft) contra la ORG.
// Ejecutar como Execute Anonymous (Developer Console / Workbench Apex Execute)
// con log APEX_CODE=DEBUG. Imprime OK (con tipo) o FALTA por cada campo
// propuesto en la planilla GrupoQ_Vehicle_Field_Mapping.xlsx, y la
// existencia de los objetos de soporte (BusinessBrand, ProductAttribute*,
// ProductMedia, VehDefSearchableField, GeoCountry).

Map<String, List<String>> expected = new Map<String, List<String>>{
    'Product2' => new List<String>{
        'MakeName','ModelName','VersionName','VehicleTrimLevel','ModelYear',
        'ModelYearVersion','Family','ProductLineCode','ProductCategoryCode',
        'ManufacturerName','IsActive','AvailabilityDate','DiscontinuedDate',
        'HarmonizedSystemCode','HarmonizedTariffSchedCode','ProductCode',
        'StockKeepingUnit','BusinessBrandId'
    },
    'VehicleDefinition' => new List<String>{
        'Name','ModelCode','ExternalReferenceNumber','VariantName','EngineName',
        'EngineCubicCapacity','TotalPower','MaximumTorque','FuelSource',
        'FuelType','TransmissionSystem','TransmissionType','DrivetrainSystem',
        'DrivetrainType','BodyType','DoorCount','DoorStyle','DoorStyleType',
        'EmissionStandard','UrbanFuelEconomy','ExtraUrbanFuelEconomy',
        'CombinedFuelEconomy','FuelTankCapacity','MainBatteryType',
        'AuxiliaryBatteryType','BatteryCapacity','MaximumBatteryRange',
        'MinimumBatteryRange','Length','Width','Height','Wheelbase',
        'CurbWeight','MaximumGrossWeight','AccelerationTime','TopSpeed',
        'VehicleClass','GeoCountryId','ProductId'
    },
    'Vehicle' => new List<String>{
        'ExteriorColor','InteriorColor','UpholsteryColor','UpholsteryType',
        'VehicleIdentificationNumber','VehicleDefinitionId','AssetId'
    }
};

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

for (String objName : expected.keySet()) {
    Schema.SObjectType t = gd.get(objName.toLowerCase());
    if (t == null) {
        System.debug('### ' + objName + ': OBJETO NO EXISTE EN LA ORG');
        continue;
    }
    Map<String, Schema.SObjectField> fm = t.getDescribe().fields.getMap();
    System.debug('### ' + objName + ' (' + fm.size() + ' campos visibles)');
    for (String f : expected.get(objName)) {
        Schema.SObjectField sf = fm.get(f.toLowerCase());
        if (sf == null) {
            System.debug('FALTA  ' + objName + '.' + f);
        } else {
            Schema.DescribeFieldResult d = sf.getDescribe();
            String extra = d.getType() == Schema.DisplayType.PICKLIST
                ? ' [picklist ' + d.getPicklistValues().size() + ' valores]' : '';
            System.debug('OK     ' + objName + '.' + f + ' (' + d.getType()
                + (d.isExternalId() ? ', EXTERNAL ID' : '')
                + (d.isIdLookup() ? ', idLookup' : '') + ')' + extra);
        }
    }
}

// Objetos de soporte citados en la planilla (solo existencia + accesibilidad)
for (String objName : new List<String>{
        'BusinessBrand','ProductAttribute','ProductAttributeSet',
        'ProductAttributeSetItem','ProductAttributeSetProduct','ProductMedia',
        'VehDefSearchableField','GeoCountry','GeoCountrySpecification'}) {
    Schema.SObjectType t = gd.get(objName.toLowerCase());
    System.debug('OBJETO ' + objName + ': '
        + (t == null ? 'NO EXISTE' : 'OK (createable='
            + t.getDescribe().isCreateable() + ')'));
}
