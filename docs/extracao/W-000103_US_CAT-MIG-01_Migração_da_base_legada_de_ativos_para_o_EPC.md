# W-000103 — US CAT-MIG-01 — Migração da base legada de ativos para o EPC

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 04/09/2026 15:07 por Diego Beltrão de Moraes | Alterado: 08/09/2026 17:38 por Diego Beltrão de Moraes

US de arquitetura (ata 03/09). Importacao da base legada para o modelo EPC/CPQ do Salesforce.

NARRATIVA
Como time de implantacao, quero mapear e importar a base legada de clientes e ativos (~450 mil ativos atuais, estimativa de ~1 milhao com adicoes futuras; ~500 mil contratos) amarrando cada ativo aos produtos, bundles e especificacoes do EPC, para que MACD, retencao e faturamento funcionem sobre a base convertida.

ESCOPO
- De-para produto legado -> Product Spec/Oferta do EPC (amarracao firme de especificacoes);
- Carga dos Assets com dados contratuais no ativo: data de inicio, fidelidade, renovacao, reajuste (regras de cancelamento e multa preservadas - ata 02/09);
- Tabelas temporarias de banco para tratamento de erros de carga (padrao definido em reuniao);
- Chave externa (external id) por ativo para reprocessamento idempotente;
- Ondas por cluster: migra apenas quando o cluster passa a usar o sistema oficial (decisao de escopo 03/09 - Avare/B2C primeiro);
- Extrato inteligente das integracoes existentes por tipo de oferta antes do corte (mapeamento de codigos e registros para nao perder dado funcional).

DEPENDENCIAS: catalogo da Onda 1 carregado (EPC-01..09, CAT-TPL-01); decisao de arquitetura de endereco (Premises/ServicePoint - ja registrada em W-000094/W-000097); janela de corte com operacao.

CRITERIOS DE ACEITE
1. Dado um ativo legado mapeado, quando importado, entao ele referencia a spec/oferta correta do EPC e carrega fidelidade, renovacao e reajuste no Asset.
2. Dado um erro de carga, quando o batch conclui, entao o registro esta na tabela temporaria com causa, e o reprocesso pela chave externa nao duplica ativos.
3. Dado um cliente migrado, quando um MACD de teste (upgrade e cancelamento) e executado em sandbox, entao o fluxo asset-based funciona sobre o ativo convertido.
4. Dado o piloto de conciliacao, quando amostra estatistica for comparada com o legado, entao contagem e valores batem (relatorio de conciliacao publicado).

## Notas de Refinamento e Decisões Registradas

--- CONTAS ANTES DOS ATIVOS - DADOS DA ORG (08/09) ---
Produção em 08/09 tem 1 Asset e cerca de 110 mil contas (54.485 B2B - Pessoa jurídica, 53.039 Pessoa Física, 2.088 Pessoa Jurídica, 1.938 Billing, 4 sem record type), sem Person Accounts. A migração precisa carregar, nesta ordem: (1) contas cliente deduplicadas por CPF/CNPJ (unificar os dois record types de PJ conforme decisão da US CAT-ACC-01); (2) Billing Accounts, reconciliando as 1.938 existentes com o Customer Core por ID externo; (3) Service Accounts e Premises/ServicePoint por endereço de instalação; (4) Assets com Service Tag (US CAT-TAG-01) já vinculados a Billing e Service Account (RN-08 da CAT-ACC-01); (5) contratos. Nenhum Asset é carregado sem as contas dos passos 1 a 3. Volumetria de ativos a obter do legado antes do plano de carga.

--- CORRECAO DO PASSO 2 DA CARGA (08/09) ---
Auditoria de 08/09 (ver nota "CORRECAO APOS AUDITORIA DAS CONTAS BILLING" na W-000117): as 1.938 contas "Billing" existentes são clientes pessoa física com CPF e Código SAP, não contas de cobrança. O passo (2) da ordem de carga passa a ser: reclassificar essas contas como "Pessoa Física" e, se a decisão da CAT-ACC-01 mantiver a conta do cliente como Billing/Service padrão na Onda 1, não há Billing Accounts a carregar além dos casos de pagador diferente. Chaves de reconciliação: com o ERP, o Código SAP do Cliente (ExternalId__c), preenchido em 99,9% das contas PF e PJ de 2026 e em apenas 87 das 54.485 "B2B - Pessoa jurídica"; com o Customer Core (plataforma legada), NÃO há campo hoje: criar External ID "ID Customer Core" em Account antes da carga. A base B2B precisa receber o código SAP e o ID Customer Core antes da carga de ativos (novo pré-requisito do passo 1). Limpeza prévia ao passo 1: 112 contas do "Usuario Teste", 4 contas sem record type, usuário de integração "Ordem Manual" em duplicidade. Volumetria confirmada em 08/09: 111.590 contas, 1 Asset, 549 pedidos com Billing/Service preenchidos.
