# W-000087 — US TEC-B2C-04 — Fundação de Integrações (Named Credentials, IPs base e mapa TMF)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-04: Fundação de Integrações (Named Credentials, IPs base e mapa TMF)
Narrativa: Como time de implantação, quero a camada base de integrações padronizada, para as US funcionais consumirem serviços externos sem retrabalho.
Escopo técnico:
- Named Credentials + External Credentials por sistema (Customer Core, motor de crédito, GIS/viabilidade, billing, Zendesk, plataforma de assinatura).
- Integration Procedures base com padrão de log, retry e tratamento de erro (reaproveitáveis).
- Mapa de APIs por capacidade: TMF632 Party (busca/cadastro cliente), TMF645 Service Qualification (viabilidade), TMF678 Customer Bill (emissão de cobrança), TMF622/TMF641 Ordering (ativação), webhooks inbound (baixa bancária, aceite de assinatura).
- Usuário de integração API-only com OAuth 2.0 JWT (atende também a US-15).
Critérios de aceite: chamada de exemplo por credencial funcionando em sandbox; padrão de erro/log validado; documento de contrato de cada API publicado.
Dependências: disponibilidade dos endpoints dos sistemas externos; definição com o time de integração (MuleSoft ou ponto a ponto).

## Critérios de Aceite (related list)

**1. Critério 3** (New)
documento de contrato de cada API publicado.

**2. Critério 2** (New)
padrão de erro/log validado.

**3. Critério 1** (New)
chamada de exemplo por credencial funcionando em sandbox.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO COM B2B ---
Acrescentar ao mapa de integrações os sistemas da jornada B2B: Econodata (enriquecimento cadastral, sincronização batch), Serasa (crédito), Ozmap/motor de viabilidade (TMF645 consumida, com geocodificação lat/long para multi-site) e Billing Stop no Customer Core. Atenção: Econodata, Serasa, Ozmap e DocuSign são contratos de terceiros da BTP, confirmar vigência antes do desenvolvimento.

--- CANAL DE EVENTOS DE CONTRATO (04/09) ---
Incluir no mapa de integracoes o canal de eventos do contrato (especificacao completa na work US TEC-INT-01): eventos QuoteContractRequested__e / QuoteContractReady__e, Publish After Commit, assinatura recomendada via Salesforce Pub/Sub Connector do MuleSoft (gRPC; alternativa: Replay Channel Listener com ObjectStore v2 e Resume from Last Replay ID). Payload de integracao das demais interfaces: sera definido sobre as TMFs ja mapeadas nesta work (TMF622/632/637/641/645/678) - registrar os contratos de payload por API quando formalizados.

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
DECISAO REGISTRADA (04/09) - ENDPOINT PROPRIETARIO x TMF:
A Onda 1 REUSA os contratos proprietarios existentes no MuleSoft: GET /customer/{documento}, POST /customer, POST /create-contract, GET /get-credit-analysis/{documento}, GET /get-technical-viability - todos configurados em IntegrationConfig__mdt e autenticados pela Named Credential MuleCallout (paths base /btp-salesforce-eapi-prod/api/...). A aderencia TMF evolui por ADAPTER no barramento, API a API, sem reescrever o que opera.
FUNDAMENTO: analise TMF da consultoria - nenhuma das 21 TMFs e API nativa no AS-IS (13 implementadas no processo, 7 parciais/estruturais, TMF678 nao localizada fim a fim); capacidades funcionais comprovadas com confianca alta.
EVIDENCIA: aba Analise TMF e aba Inventario Integracoes do consolidado da consultoria; customMetadata/IntegrationConfig.*.md-meta.xml; namedCredentials/MuleCallout.namedCredential-meta.xml.
DIRETRIZ SYSMAP: nos documentos tecnicos, TMFs citadas sao CONTRATO ALVO do adapter; a chamada implementada na Onda 1 usa o endpoint proprietario correspondente. Revalidar no forum executivo se a meta passar a ser conformidade/certificacao TM Forum.
