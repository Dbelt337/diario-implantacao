/* Executar o backfill (apos deployar a classe LeadCountryBackfill).
   Batch size 100. Acompanhar em Setup > Apex Jobs; log final tem prefixo 'BACKFILL FIM'. */
Id jobId = Database.executeBatch(new LeadCountryBackfill(), 100);
System.debug(LoggingLevel.ERROR, 'BACKFILL enfileirado. JobId=' + jobId);
