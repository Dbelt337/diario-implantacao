# W-000105 — US TEC-INT-01 — Canal de eventos de contrato (Salesforce para MuleSoft)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 04/09/2026 15:07 por Diego Beltrão de Moraes | Alterado: 08/09/2026 16:10 por Diego Beltrão de Moraes

US tecnica (decisao 04/09: geracao de contrato na cotacao, server-side, sem bloquear a tela; integracao por Platform Event consumido pelo MuleSoft).

NARRATIVA
Como time de implantacao, quero um canal de eventos confiavel entre Salesforce e MuleSoft para o ciclo de geracao de contrato da cotacao, para que a jornada de venda permaneca responsiva e o processamento pesado rode assincrono com recuperacao garantida.

ESPECIFICACAO
1. Eventos: QuoteContractRequested__e (saida) com QuoteId, AccountId, OfferCode, TotalValue, ComponentsJSON (componentes/opcoes - decisao de payload da ata 02/09), SAPMaterialCode, FiscalDescription, EventUUID (chave de idempotencia); QuoteContractReady__e (retorno) com QuoteId, ContractId/DocumentLink, Status, EventUUID. Mensagem de evento limitada a 1 MB - se o JSON crescer, enviar IDs e o Mule busca o restante.
2. Publicacao: Publish Behavior = PUBLISH AFTER COMMIT (o assinante depende dos dados commitados da cotacao; evento nao sai se a transacao falhar). Publicar via Record-Triggered Flow na Quote (gate de geracao) ou EventBus.publish() na orquestracao. Nota de limites: no modo After Commit cada publicacao conta como statement DML do Apex.
3. Assinatura MuleSoft: RECOMENDADO o Salesforce Pub/Sub Connector (gRPC, recomendacao oficial para integracoes novas de platform events). Alternativa: Salesforce Connector com Replay Channel Listener + ObjectStore v2 e "Resume from Last Replay ID" (retencao de 72h no event bus). Operacao em cluster: a source roda APENAS no primary node (multiplos workers duplicam eventos). Atencao documentada: migracao Hyperforce ou sandbox refresh invalida Replay ID armazenado (tratar conforme KB da MuleSoft).
4. Semantica: entrega at-least-once e sem garantia absoluta -> consumidor idempotente (dedup por EventUUID antes de chamar o Customer Core) + reconciliacao (relatorio de cotacoes no gate sem callback em X horas). Callback atualiza a Quote e destrava a jornada.
5. Tela (com a TEC-B2C-03): clique responde imediato com estado "em geracao"; step assina o retorno via pub/sub do OmniScript so durante a janela de espera; fallback de polling leve.
6. Limites e monitoramento (doc oficial de Allocations): publicacao 250 mil eventos/hora; ENTREGA default 25 mil/24h (Enterprise) compartilhada por todos os assinantes de API - cada usuario logado com empApi conta como cliente CometD (limite de 1.000 concorrentes) e consome cota de entrega; triggers e flows internos nao consomem. Mitigacoes: assinar/desassinar por janela, canal customizado com filtro por usuario/cotacao, monitorar DailyDeliveredPlatformEvents (REST limits) e PlatformEventUsageMetric (SOQL) com alerta antes do teto.

DEPENDENCIAS: TEC-B2C-04 (Named Credentials/usuario de integracao), TEC-B2C-06 (motor de geracao), time de integracao MuleSoft.

CRITERIOS DE ACEITE
1. Dado o clique em Gerar Proposta, quando a acao executa, entao a tela responde em menos de 1 segundo com estado visivel e nenhuma chamada sincrona de geracao ocorre na transacao.
2. Dado que a transacao da cotacao falhou, quando o rollback ocorre, entao nenhum evento e publicado.
3. Dado o Mule indisponivel por ate 72 horas, quando reconectar, entao recupera todos os eventos do ponto onde parou sem duplicar geracao no destino (dedup por EventUUID validado).
4. Dado o callback recebido, quando a Quote e atualizada, entao a tela do vendedor reflete o novo estado sem refresh manual.
5. Dado o consumo diario de entregas, quando atingir o limiar de alerta, entao o monitoramento notifica antes do limite da org.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
ENCAIXE COM O AS-IS (matriz #11): o CONSUMIDOR dos eventos de assinatura ja existe em producao - Orchestration Items SignatureSent/Signed do plano de OM (vlocity-backup/OrchestrationItemDefinition/Envio-da-proposta_Criacao-da-Proposta e Assinatura-do-Contrato_Contrato). O PRODUTOR nao foi localizado pela consultoria: o canal desta work e exatamente o produtor que falta.
DIRETRIZ SYSMAP: ao publicar QuoteContractReady__e, integrar com os Orchestration Items EXISTENTES (mesmo padrao de evento de status) em vez de criar consumidor paralelo; validar o payload esperado pelos items de producao antes de fechar o contrato do evento.

--- RETORNO DO CONTRATO ASSINADO PARA O SALESFORCE (08/09) ---
Complemento obrigatório do contrato do canal. (a) SAÍDA: QuoteContractRequested__e carrega ContentVersionId da minuta; o Mule baixa pela API com credencial de serviço; nenhum link público em nenhuma etapa. (b) RETORNO: QuoteContractReady__e com Status em {Recebido, Enviado, Assinado, Recusado, Expirado, Erro}, ExternalDocumentId, SignedAt, SignatureMethod (digital plataforma | anexo | biometria), Sha256 e SignedDocumentRef (URL temporária de minutos para o Mule buscar o binário). (c) NO STATUS ASSINADO o Mule grava o PDF assinado como ContentVersion (tipo "Contrato assinado") e cria ContentDocumentLink para Quote, Contract e Account; o Salesforce recalcula o SHA-256 do arquivo recebido e só aceita se conferir com o informado; grava ExternalDocumentId, hash e SignedAt no Contract; conclui o Orchestration Item Signed. (d) IDEMPOTÊNCIA: EventUUID repetido não cria segundo arquivo. (e) EVIDÊNCIA: a plataforma permanece cofre da trilha de assinatura (IP, carimbo de tempo, Anatel); botão "Validar na plataforma" obtém, via Named Credential, URL de curta duração para auditoria, com quem pediu registrado. (f) FALLOUT: hash divergente, binário indisponível ou timeout marcam Erro e abrem tarefa de fallout com retentativa; a jornada não avança para pedido sem o PDF assinado no Salesforce. (g) ATENDIMENTO EXTERNO (Zendesk): acesso ao PDF assinado somente por API via Mule, com identificação do agente; fora do escopo desta work, registrado para a fronteira Zendesk x Salesforce.
CRITÉRIOS DE ACEITE ADICIONAIS: Cenário A: Dado a assinatura concluída na plataforma, quando o evento Assinado chegar, então em até 5 minutos o PDF assinado está vinculado à cotação, ao contrato e à conta, o hash confere e o Item Signed está concluído. Cenário B: Dado hash divergente, quando o Mule gravar o arquivo, então o Salesforce rejeita, marca Erro e abre fallout. Cenário C: Dado um usuário com acesso ao contrato, quando abrir o registro, então visualiza o PDF assinado no visualizador nativo sem autenticar na plataforma. Cenário D: Dado o mesmo evento reenviado, quando processado, então não há arquivo duplicado.
