# Pacote final (parte que eu produzo) - GrupoQ Lead Capture

Conteudo (tudo validado em Check-Only / formatos corretos):
- omniDataTransforms (EXTRACTS): DRProductSearch, DRProductIntegrityCheck,
  DRBusinessProfileGetByCode, DRLeadGetByExternalRequestId.
- omniIntegrationProcedures: Lead_SearchActiveProducts (consulta) e Lead_Upsert (criacao).
- objects/Lead.object: campos custom (ExternalRequestId__c, ChannelCode__c, NationalId__c).

## IMPORTANTE - o Load NAO esta aqui (de proposito)
O Data Mapper de **Load** (DRLeadInsert = arvore Lead + LeadLineItem +
LeadPreferredSeller) **so funciona montado no Data Mapper Designer** - o .rpt de
Load montado a mao sai vazio (Objects/Mapping). Voce ja montou o DRLeadInsert no
Designer e ele cria o Lead. Este pacote **NAO inclui nenhum Load**, entao **nao
sobrescreve** o seu DRLeadInsert do Designer.

A IP Lead_Upsert aqui e enxuta: chama o seu DRLeadInsert (CreateTree) e responde.
Quando voce adicionar LeadLineItem + LeadPreferredSeller como filhos no DRLeadInsert
(no Designer), a IP passa a criar a arvore inteira com o LeadId auto-vinculado.

## Deploy
Check-Only (Single Package + Rollback On Error) -> deploy. Depois Activate as IPs
no Designer.

## Para fechar 100% (ultimo passo)
Retrieve do seu DRLeadInsert (arvore) -> me envia -> eu versiono e confirmo a
ligacao da IP com o seu Load.
