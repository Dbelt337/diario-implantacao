# W-000058 — US B2C-02 — Trilha Alternativa: Oferta Móvel Obrigatória em caso de Inviabilidade

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:12 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

"Como Consultor de Vendas B2C
Quero executar a análise de viabilidade técnica e ser direcionado obrigatoriamente para a Oferta Móvel em caso de inviabilidade
Para que eu identifique precocemente a disponibilidade de rede fixa e converta o cliente para serviços móveis antes de registrar a perda do contato.

SOLUÇÃO TÉCNICA: Integration Procedure de viabilidade no padrão TMF679 (certificado no
Communications Cloud) contra o GIS/Ozimap. REUSO: gravar o Premises no campo EXISTENTE
Lead.vlocity_cmt__PremisesId__c; Premises__c/ServicePoint__c zerados com hook PremisesInterface ativo
(adoção limpa); inviabilidade converte para o RT EXISTENTE vlocity_cmt__MobilePhoneOpportunity.
CONSTRUIR: Lead.ViabilityStatus__c (Viável/Inviável/Exceção), CTO__c, PortReservationToken__c,
MobileOfferRejected__c; criação on-demand de Premises (chave CEP+número+IBGE) e ServicePoint
(tecnologia, CTO, token); VR que bloqueia perda por inviabilidade sem MobileOfferRejected__c = TRUE.

Dependências: API GIS/inventário; dono do SLA de expiração do token (rede, não Salesforce);
tratamento de exceção regional >200 m (Engenharia).

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-02."

## Critérios de Aceite (related list)

**1. 2** (New)
Inviabilidade Técnica de Fibra com Oferta Móvel Obrigatória — Dado que a consulta de viabilidade técnica de fibra retornou "Inviável"; Quando o sistema processa o resultado negativo; Então o Salesforce deve apresentar obrigatoriamente a tela de Oferta do Serviço Móvel e bloquear a marcação de perda direta até a decisão do cliente.

**2. 1** (New)
Viabilidade Positiva dentro dos 200m com Reserva de Porta — Dado que o Lead possui CEP e número de imóvel residencial cadastrados; Quando o vendedor aciona a consulta de viabilidade técnica; Então o sistema deve confirmar a viabilidade dentro do limite de 200 metros , efetuar a reserva da porta na CTO e liberar o avanço do Lead.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #4) + novo escopo confirmado (matriz #21/#22).
REUSAR: viabilidade tecnica em producao - SalesJourney_CheckFeasibility > IPTechnicalViabilityIntegration > BTecPar_TechnicalViabilityCheck > HTTPSendTechnicalViabilityCheck; GET /get-technical-viability via Named Credential MuleCallout (config em IntegrationConfig__mdt.technicalViabilityMulesoft).
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecPar_TechnicalViabilityCheck | customMetadata/IntegrationConfig.technicalViabilityMulesoft.md-meta.xml.
CONSTRUIR: reserva de porta/CTO/token (sem evidencia no ZIP), gravacao do Premises, trilha movel obrigatoria (servico movel = novo escopo, gap #21), unificacao rede propria/neutra e contingencia manual.
DIRETRIZ SYSMAP: manter o padrao TMF679/TMF645 apenas como CONTRATO ALVO; a chamada da Onda 1 reusa o endpoint proprietario existente (ver decisao registrada na W-000087).

--- OFERTA MOVEL DA TRILHA ALTERNATIVA (decisao 03/09) ---
A oferta movel apresentada na inviabilidade e restrita a pacotes fixos de dados (6/10/15/25/50/75 GB) x prazo de contrato, sem aparelho. MVNO: a BTP nao emite NF (Anatel) - sem campos fiscais por linha para o movel. Object Type Oferta Movel (Franquia de Dados + Prazo de Contrato) conforme revisao da planilha de atributos de 04/09. A conversao para vlocity_cmt__MobilePhoneOpportunity permanece.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-02 — Análise de Viabilidade Técnica no Lead e Oferta Móvel Obrigatória to US B2C-02 — Trilha Alternativa: Oferta Móvel Obrigatória em caso de Inviabilidade
