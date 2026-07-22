# Preferências do projeto

## Comunicação
- NUNCA usar emoji em nada: respostas de chat, mensagens de commit, arquivos,
  documentos, PRs — nenhum artefato. (Preferência do usuário, 2026-07-21.)

## Processo de validação de HUs (compromisso com a Melisa, 2026-07-22)
- Diego SEMPRE valida as histórias ANTES de subirem para o Jira/refinamento,
  cruzando contra a arquitetura travada (deploy/arquitetura-ventas/
  GUIA-LWC-APEX-VENTAS.xlsx). Uma versão única e alinhada — sem solução
  diferente nem Excel complementar depois no refinamento.

## Guardas de licenciamento e arquitetura (não esquecer em NENHUMA HU)
- GrupoQ NÃO tem CPQ, Revenue Cloud nem EPC. HU que assumir esses produtos
  deve ser corrigida (ex.: HU-028 mencionava CPQ/Revenue Cloud — removido).
- BRE (Expression Sets / Decision Matrices) ESTÁ licenciado — regras de
  preço/imposto/exoneração vivem lá, mantidas pelo negócio, nunca em Apex.
- Repuestos e PA: SAP é a fonte da verdade do preço (preço dinâmico
  FOB x fator x mark-up; listas de PA geral/canal/cliente/volume com
  vigência). Salesforce consulta e exibe — não calcula nem converte moeda.
  PricebookEntry de PA é só referência de exibição.
- Combos: SKU próprio (Product2 com ProductCode=material SAP), preço
  resolvido pelo SAP. NÃO requer CPQ. Disponibilidade do kit na HU-043.
- Carga massiva de preços/parâmetros de pricing: é do SAP, não construir no SF.
- Evidência de licença (org GrupoQ, 22/07/2026): Salesforce Pricing Design/Run
  Time = 1+1 assentos (token do bundle — NÃO usar o app Price Management);
  BRE Designer/Runtime = 27.131 assentos cada (motor de regras confirmado);
  OmniStudio 27.131; Automotive Foundation 2.130; Inventory Search and
  Transfer 2.130. Rebate Management e Price Protection licenciados (2.130) —
  munição para HUs de descontos, sem mudar o travado.
- Case EXCLUÍDO das HUs de Repuestos por decisão do cliente (HU-039):
  solicitudes em objeto custom + Record Types + Queues + Duplicate Rules
  nativas. Nenhuma HU futura propõe Case sem validar.
- HU-039: criação/extensão de material = serviço NOVO no contrato MuleSoft
  (escrita de dado mestre no SAP; SF solicita, SAP executa e devolve MATNR).
- Arquitetura de vendas travada (híbrido): LWC+Apex SÓ em UI e integração;
  consulta síncrona SAP via Continuation (MuleSoft POST /api/v1/
  prices-and-inventory); assetização nativa (Asset + Vehicle +
  AssetContactParticipant via Flow); Record Types separam Venta Vehículo
  x Contraventa Repuestos. Decisão LWC vs OmniStudio em validação com a
  Salesforce (e-mail chefe -> Felipe Pajón) — não cravar antes do aval.
