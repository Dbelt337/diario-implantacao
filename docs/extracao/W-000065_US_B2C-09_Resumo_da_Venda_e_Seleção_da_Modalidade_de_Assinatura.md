# W-000065 — US B2C-09 — Resumo da Venda e Seleção da Modalidade de Assinatura

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:24 por Diego Beltrão de Moraes | Alterado: 08/09/2026 16:10 por Diego Beltrão de Moraes

"Como Consultor de Vendas B2C
Quero visualizar a tela de Resumo da Venda com a consolidação de todos os dados do pedido e selecionar a modalidade de aceite do contrato (Digital, Evidência/Anexo ou Biometria Facial).
Para que eu possa conferir as informações junto ao cliente antes do envio e garantir a formalização jurídica adequada da contratação.

SOLUÇÃO TÉCNICA: ESTENDER as etapas EXISTENTES da jornada PF — bTecParPFSummaryPortugueseBrazil
(resumo) e bTecParPFAcceptPortugueseBrazil (aceite) — não criar tela. Order.AttachmentSignature__c
JÁ EXISTE (avaliar no lugar de campo novo). Geração do contrato via DocGen CME (licenciado, 422
usuários, 1M gerações/mês).
CONSTRUIR: Order.SignatureMode__c (Digital/Anexo/Biometria) + IsContractSigned__c; ramo por
modalidade no Accept: Digital → IP dispara link (plataforma de assinatura) via WhatsApp/e-mail;
Anexo → File Upload obrigatório antes de avançar; Biometria → IP para parceiro externo (unico/idwall/
Datavalid — validade jurídica ok; NÃO é nativo). Webhook de aceite → Platform Event ContractSigned__e
→ trava do botão de perda (mecânica W0382).

Dependências: plataforma de assinatura padrão da casa; contratação do serviço de biometria.Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-09."

## Critérios de Aceite (related list)

**1. 2** (New)
Desabilitação do botão de perda pós-assinatura — Dado que o contrato foi assinado pelo cliente; Quando o status do contrato atualizar para Assinado; Então o botão "Perder Venda" deve ficar indisponível na interface.

**2. 1** (New)
Assinatura por Anexo/Evidência com Upload Obrigatório — Dado que o vendedor está na tela de Resumo da Venda; Quando ele selecionar a modalidade de assinatura "Por Anexo"; Então o Salesforce deve abrir a janela de upload de documento e só permitir o avanço do fluxo após a confirmação do anexo.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: parcial (matriz #11) - consumidor existe, produtor nao localizado.
REUSAR: Orchestration Items de assinatura em producao (Envio-da-proposta_Criacao-da-Proposta e Assinatura-do-Contrato_Contrato) que consomem os eventos SignatureSent/Signed.EVIDENCIA: vlocity-backup/OrchestrationItemDefinition/Envio-da-proposta_Criacao-da-Proposta | vlocity-backup/OrchestrationItemDefinition/Assinatura-do-Contrato_Contrato.
CONSTRUIR: o PRODUTOR dos eventos (sera o canal da US TEC-INT-01) e a decisao de modalidades (digital/evidencia/biometria - pendencia da matriz).
DIRETRIZ SYSMAP: integrar o callback QuoteContractReady__e aos Orchestration Items EXISTENTES; nao criar consumidor paralelo.

--- ASSINATURA INTEGRADA AO CANAL DE CONTRATO (04/09) ---
Modalidade Digital: o link de assinatura so e gerado apos QuoteContractReady__e (o contrato passa a existir na cotacao, decisao 04/09). A confirmacao de assinatura chega pelo MuleSoft e alimenta os Orchestration Items SignatureSent/Signed JA EXISTENTES em producao (AS-IS, matriz #11) - o evento ContractSigned__e proposto aqui deve ser o mesmo padrao/canal da US TEC-INT-01 (W-000105), nao um evento paralelo. Plataforma de assinatura "padrao da casa": pendencia de negocio a registrar em ata antes do desenvolvimento.

--- CONTRATO ASSINADO NO SALESFORCE (08/09) ---
Ajuste da pendência registrada: o motor de assinatura é o interno da plataforma (ata 02/09, sem contratação de terceiro); a pendência real é a API da plataforma para receber a minuta e devolver status e PDF assinado (time da plataforma). Regras: (1) em TODAS as modalidades o resultado final é o PDF assinado como ContentVersion "Contrato assinado" no Salesforce, vinculado à Quote, ao Contract e à Account, com hash; (2) modalidade Anexo: o upload feito pelo vendedor vira o mesmo tipo de documento com origem "anexo manual" e exige validação do backoffice; (3) o botão de perda só é desabilitado quando o PDF assinado estiver gravado no Salesforce, não apenas quando o status mudar; (4) o evento de assinatura é o do canal TEC-INT-01 (W-000105), não um ContractSigned__e paralelo. Decisão em aberto, para a reunião com Bismarck: manter cenário A (plataforma), B (DocuSign, se o contrato citado na W-000087 estiver vigente) ou C (aceite eletrônico com OTP no Salesforce para B2C, plataforma para B2B).

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-09 — Resumo do Pedido e Seleção da Modalidade de Assinatura to US B2C-09 — Resumo da Venda e Seleção da Modalidade de Assinatura
