# W-000082 — US B2C-25 — Geração Dinâmica da Minuta do Contrato

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 08/09/2026 16:10 por Diego Beltrão de Moraes

Referência: US-NEW-02 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

[US-NEW-02] Geração Dinâmica da Minuta do Contrato
1. NARRATIVA DE NEGÓCIO
Como Consultor de Vendas B2C,
Quero que o sistema gere dinamicamente a minuta do contrato baseada nos produtos, dados do cliente e regras de faturamento preenchidas,
Para que o documento reflita exatamente a cotação negociada e possa ser apresentado/enviado para assinatura do cliente.
2. CONTEXTO E REGRAS DE NEGÓCIO
Antes do aceite/assinatura, o documento físico/digital precisa existir. O sistema deve acionar um motor de Documentação (DocGen) que faça o merge das variáveis em um modelo Word/PDF aprovado pelo jurídico. Não é permitido edição manual de texto do contrato pelo vendedor.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: DocumentTemplate, Quote, ContentDocumentLink.
Automação: OmniStudio Document Generation. Configuração de DataRaptor Extract para mapear dados da Cotação/Oportunidade no Template.
- Geração e Pré-visualização do PDF: Dado que o carrinho e faturamento foram concluídos, / Quando o vendedor aciona a "Criação do Contrato", / Então o motor compila o PDF bloqueado com os dados mesclados e exibe um preview na tela.

## Critérios de Aceite (related list)

**1. Geração e Pré-visualização do PDF** (New)
Dado que o carrinho e faturamento foram concluídos
Quando o vendedor aciona a "Criação do Contrato"
Então o motor compila o PDF bloqueado com os dados mesclados e exibe um preview na tela.

## Notas de Refinamento e Decisões Registradas

--- DECISAO 04/09 - CONTRATO NA COTACAO, SERVER-SIDE ---
A geracao da minuta ocorre na COTACAO (nao na ordem), de forma assincrona e server-side: o clique em Gerar Proposta responde imediatamente (estado "em geracao") e publica o Platform Event QuoteContractRequested__e (Publish Behavior = Publish After Commit, para o evento so existir com a cotacao commitada); o MuleSoft consome, executa a geracao e devolve o callback QuoteContractReady__e, que atualiza a Quote (status + link do documento). A tela reflete via assinatura pub/sub do OmniScript, sem refresh manual. Nenhuma geracao sincrona na transacao de tela. Especificacao completa do canal na work US TEC-INT-01 (canal de eventos de contrato).

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #10 + cadeias confirmadas).
REUSAR: contrato Salesforce - BTecParPF_Summary > IP_CreateContractSF > BTecParPF_CreateContractSF > DMCreateContract (DML Contract); contrato Customer Core - SendCreateContractPlataforma > BTecPar_CreateContract > HTTPCreateContract (POST /create-contract, IntegrationConfig__mdt.createContractMulesoft).
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecParPF_CreateContractSF | vlocity-backup/IntegrationProcedure/BTecPar_CreateContract.
CONSTRUIR: o disparo assincrono por evento (gatilho na cotacao, conforme nota anterior) e a idempotencia do POST (pendencia da matriz: revisar campos adicionais e idempotencia).
DIRETRIZ SYSMAP: reusar as duas cadeias como executoras; a mudanca e o ORQUESTRADOR (evento + Mule), nao a criacao do contrato em si.

--- ESCLARECIMENTO 08/09 - QUEM GERA O CONTRATO ---
A geração do contrato é do Document Generation do Salesforce (TEC-B2C-06), assíncrona e server-side; o MuleSoft NÃO gera documento: transporta o PDF e o payload para a plataforma e devolve status. Sequência: (1) gate na cotação publica QuoteContractRequested__e; (2) job assíncrono do DocGen produz a minuta e grava como ContentVersion vinculada à Quote (tipo "Minuta"); (3) o evento leva o ContentVersionId e o payload da ata 02/09 (ID da oferta, status, valor, componentes em JSON, código SAP, descrição fiscal); (4) o Mule baixa a minuta pela API com credencial de serviço e entrega à plataforma; (5) a plataforma assina e devolve status e o PDF assinado (ver W-000105). Onde a nota anterior diz "o MuleSoft executa a geração", leia-se "o MuleSoft executa o envio".
