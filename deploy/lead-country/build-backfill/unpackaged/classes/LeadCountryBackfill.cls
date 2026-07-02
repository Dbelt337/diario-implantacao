/**
 * Backfill uma-vez de Lead.Country__c para leads nao convertidos, derivando de
 * CompanyCode__c (Sociedad) via Sociedad_Config__mdt.Country_Picklist_Value__c.
 * allOrNone=false: nao para no primeiro erro; loga erro por registro.
 * Executar: Database.executeBatch(new LeadCountryBackfill(), 100);
 * PRE-REQUISITOS: campo Country__c + campo do CMT deployados, CMT populado
 * (Popular_CMT_Country.apex) e ajuste do Lead_SLA_Escalation ativo.
 */
public with sharing class LeadCountryBackfill implements Database.Batchable<SObject>, Database.Stateful {

    private Integer okCount = 0;
    private Integer errCount = 0;
    private Integer semMapa = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CompanyCode__c
            FROM Lead
            WHERE IsConverted = false
              AND CompanyCode__c != null
              AND Country__c = null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // de-para Sociedad -> valor exato do picklist (CMT small; query por batch e barato)
        Map<String, String> soc2pais = new Map<String, String>();
        for (Sociedad_Config__mdt c : [
                SELECT DeveloperName, Country_Picklist_Value__c
                FROM Sociedad_Config__mdt
                WHERE Country_Picklist_Value__c != null]) {
            soc2pais.put(c.DeveloperName, c.Country_Picklist_Value__c);
        }

        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : scope) {
            String val = soc2pais.get(l.CompanyCode__c);
            if (val == null) { semMapa++; continue; }   // Sociedad sem valor no CMT (ex.: P103)
            l.Country__c = val;
            toUpdate.add(l);
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] rs = Database.update(toUpdate, false);
            for (Integer i = 0; i < rs.size(); i++) {
                if (rs[i].isSuccess()) {
                    okCount++;
                } else {
                    errCount++;
                    System.debug(LoggingLevel.ERROR, 'BACKFILL ERRO Lead=' + toUpdate[i].Id
                        + ' code=' + toUpdate[i].CompanyCode__c
                        + ' : ' + rs[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.ERROR, 'BACKFILL FIM | ok=' + okCount
            + ' | erros=' + errCount + ' | semMapaCMT=' + semMapa);
    }
}
