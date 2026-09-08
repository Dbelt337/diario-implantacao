# W-000071 — US B2C-14 — Ingestão Omnichannel de Leads (Carga Massiva Restrita, QR Code e Form)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 31/08/2026 19:23 por Diego Beltrão de Moraes

Referência: US-01 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-01: Ingestão Omnichannel de Leads (Carga Massiva Restrita, QR Code e Form)
1. NARRATIVA DE NEGÓCIO
Como Coordenador de Vendas, Equipe de Marketing e Sistema de Captação
Quero centralizar a entrada de leads no Salesforce através de múltiplas fontes (Carga Massiva restrita, QR Code via App, Marketing Cloud, Zendesk e Formulários web)
Para que a operação garanta rastreabilidade ponta a ponta, evite vazamento de funil (Leads perdidos em planilhas) e direcione o roteamento adequado por canal de origem.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: A entrada de leads não pode ser apenas manual. É necessário suportar campanhas locais e nacionais e digitalizar a captação física.
Regras:
* Carga Massiva Restrita: A importação de planilhas com listagem de leads é estritamente contingencial e bloqueada para vendedores padrão. Liberada apenas para os perfis: Coordenação da cidade (ações locais) e Marketing (ações nacionais).
* Leitura de QR Code: Vendedores de rua (PAP) ou ações em condomínios usarão o App Salesforce para escanear QR Codes que preencherão automaticamente os dados básicos do Lead no sistema.
* Integração Omnichannel: Leads capturados via formulários do site, fluxos de nutrição do Marketing Cloud e tickets de prospecção do Zendesk devem ser injetados automaticamente no objeto Lead do Salesforce.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Lead, Campaign, CampaignMember.
Automação / Lógica:
* Data Import Wizard / Data Loader: Acesso restrito via System Permissions no Profile/Permission Set.
* LWC (Mobile/App): Componente para acionar a câmera do dispositivo e fazer o parsing do QR Code no App Salesforce, instanciando o registro de Lead.
* Salesforce Flow (Record-Triggered): Atribuição de LeadSource e RecordType dependendo do usuário de integração (MKT Cloud, Zendesk, Web).
Integração / APIs:
* Inbound REST API para Zendesk e Site (Formulários).
* Marketing Cloud Connect (Sincronismo de Data Extensions para Leads).
* Mapeamento eTOM: Market/Sales Lead Management.
Segurança e Acessos: Permissão Import Leads desmarcada no perfil B2C_Sales_User e atribuída via Permission Set B2C_Lead_Importer apenas aos Coordenadores e MKT.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Bloqueio e Liberação de Carga Massiva de Planilhas
Dado que um usuário tenta importar uma lista de Leads via planilha CSV
Quando o usuário possuir o perfil de "Vendedor Padrão"
Então o sistema deve bloquear o acesso à ferramenta de importação; permitindo apenas caso o usuário tenha o Permission Set de Coordenação ou Marketing.
Cenário 2: Captura via QR Code no App Mobile
Dado que o vendedor está em uma ação local utilizando o App Salesforce
Quando ele escaneia o QR Code do prospect
Então o LWC converte os dados do código (Nome, Telefone, Condomínio) em um registro de Lead associado à campanha local, sem necessidade de digitação manual.
5. DEPENDÊNCIAS E RISCOS
Dependências: Padrão de string gerada no QR Code deve ser homologado com a TI para o correto parsing (ex: vCard ou JSON).
Riscos/Premissas: [Governor Limits Check] Injeções massivas do MKT Cloud devem operar via Bulk API para não estourar o limite de Concurrent API Requests.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: CSV com 5.000 leads (para teste de MKT/Coordenação); Mock de JSON/vCard para leitura do scanner do LWC Mobile; Payload via Postman simulando injeção do Zendesk.
Estimativa de Esforço: 5 Story Points.

## Critérios de Aceite (related list)

**1. Cenário 2: Captura via QR Code no App Mobile** (New)
Dado que o vendedor está em uma ação local utilizando o App Salesforce
Quando ele escaneia o QR Code do prospect
Então o LWC converte os dados do código (Nome, Telefone, Condomínio) em um registro de Lead associado à campanha local, sem necessidade de digitação manual.

**2. Cenário 1: Bloqueio e Liberação de Carga Massiva de Planilhas** (New)
Dado que um usuário tenta importar uma lista de Leads via planilha CSV
Quando o usuário possuir o perfil de "Vendedor Padrão"
Então o sistema deve bloquear o acesso à ferramenta de importação; permitindo apenas caso o usuário tenha o Permission Set de Coordenação ou Marketing.
