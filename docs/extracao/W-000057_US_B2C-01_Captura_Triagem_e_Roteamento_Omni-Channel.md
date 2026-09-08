# W-000057 — US B2C-01 — Captura, Triagem e Roteamento Omni-Channel

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:11 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:38 por Diego Beltrão de Moraes

"Como Consultor de Vendas, Atendente (AR/Central) ou Agente de Backoffice
Quero realizar a captura de leads com restrição de input manual a perfis autorizados, validação cadastral obrigatória e atribuição automatizada da Unidade Operacional
Para que a triagem de duplicidades e o roteamento Omni-Channel ocorram de forma assertiva por skill/região, eliminando entradas inconsistentes no funil comercial.

SOLUÇÃO TÉCNICA (inventário do org 19-20/08, native-first): captura na página padrão de Lead
com Dynamic Forms + validation rules — sem LWC. REUSO: Lead já tem AddressNumber__c,
AddressComplement__c, Neighborhood__c, DocumentNumber__c (CPF/CNPJ), LegalEntityType__c, CNAE__c e
RT B2C; flows LeadGetAddress/Address_Get_Infos (CEP — estender para gravar IBGE, o ViaCEP já devolve)
e Get_CNPJ_Details; VRs de qualidade já construídas e INATIVAS (ValidaCPFeCNPJ, DocumentValidation,
PhoneValidationFormat) — reativar/ajustar antes de criar novas.
CONSTRUIR: Lead.IsCondominium__c, Block__c, ApartmentUnit__c, IBGECode__c, OperationUnit__c/Regional__c
(espelhando Opportunity.OperationUnit__c existente); objeto CEPOperationUnit__c (de-para CEP→unidade,
mantido pelo Backoffice); Matching Rule custom Lead×Account por DocumentNumber__c (hoje só standard);
filas de Lead + Omni-Channel com skills (Lead.assignmentRules hoje VAZIO — roteamento é greenfield).

Dependências: eleger fonte única de Canal de Entrada (hoje 3 casas: Account.EntryChannel__c,
objeto EntryChannel__c, vlocity_cmt__OriginatingChannel__c); Person Account [CONFIRMAR];
de-para CEP×Unidade (negócio); licenças Omni por perfil de venda.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-01."

## Critérios de Aceite (related list)

**1. 2** (New)
Inclusão de Lead PJ com Representante Legal — Dado que o operador seleciona o tipo de documento CNPJ no formulário "Nova Venda"; Quando avança no cadastro sem preencher a Razão Social ou o CPF do Representante Legal; Então o sistema deve bloquear o salvamento e indicar os campos pendentes de preenchimento obrigatório.

**2. 1** (New)
Cadastro de Lead Residencial em Condomínio — Dado que o operador de vendas insere os dados de um cliente em um endereço sinalizado como condomínio; Quando ele informa o CEP e o Número do imóvel; Então o Salesforce deve exigir o preenchimento obrigatório dos campos "Bloco" e "Apartamento" e derivar automaticamente a "Unidade Operacional" com base no CEP do local.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #2) + gap confirmado (matriz #22).
REUSAR: conversao de lead/conta/contato/oportunidade em producao - cadeia OmniScript PF > IP_CreateOrUpdateLead/IPCheckFeasibility > SalesJourney_CheckFeasibility > DMCreateUpdateLead / LeadConvertServiceB2C.convertLead.
EVIDENCIA: vlocity-backup/IntegrationProcedure/SalesJourney_CheckFeasibility | force-app/main/default/classes/LeadConvertServiceB2C.cls.
CONSTRUIR: campos de condominio/bloco/apartamento, IBGECode, CEPOperationUnit__c, matching rule custom e roteamento Omni (assignmentRules do Lead esta VAZIO). Condominio/bloco/reserva de porta NAO tem evidencia no ZIP (gap #22) - construcao plena, como a work ja especifica.
DIRETRIZ SYSMAP: nao criar novo servico de conversao - estender SalesJourney_CheckFeasibility e LeadConvertServiceB2C com os campos e status novos; validar taxonomia de perda com o comercial.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-01 — Captura, Triagem, Roteamento Omni-Channel e Regras de Condomínio to US B2C-01 — Captura, Triagem e Roteamento Omni-Channel
