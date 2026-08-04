# Instruções para o Claude neste repositório

## Comunicação
- Não usar emojis nas respostas.
- Dar apenas a informação correta e verificada; quando algo for suposição ou não confirmado, dizer explicitamente que é suposição.
- Fazer somente o que foi pedido, sem tarefas extras não solicitadas. Oferecer sugestões apenas se perguntado.
- Respostas breves e diretas, em português.

## Processo de trabalho (regra permanente, Diego 05/08/2026)
- AVALIAR ANTES DE FAZER: antes de propor/criar qualquer metadata, verificar o que existe — describe dos objetos (FieldDefinition), valores de picklist (PicklistValueInfo), object reference oficial e customs já criados pelo time. Só criar campo/componente quando comprovadamente não houver nativo ou existente que sirva.
- SEGUIR SEMPRE o GRPQM Naming Conventions: API names em inglês Pascal/camel sem underscores (exceto sufixos padrão da org como _EC), labels em espanhol, flows em natural text ("Screen Flow: ...", "Scheduled: ..."), validation rules em natural text, record types iniciando pelo processo de negócio, descriptions estruturadas e com no máximo 255 caracteres (validar o tamanho antes de gerar pacote).
- Permission sets seguem o padrão de fato da org: label "PS <Nome>".

## Contexto do projeto
- Implantação Salesforce do GrupoQ (Automotive Cloud, multi-país). Sandbox de trabalho: DevSales.
- Todo metadata segue o GRPQM Naming Conventions: metadata em inglês, textos user-facing em espanhol, descriptions estruturadas.
- Deploys via Workbench com zips gerados a partir de `deploy/` (package.xml + flows/).
- Restrição de arquitetura: NÃO criar objetos custom. Usar catálogo standard (Product2/Pricebook2/PricebookEntry), campos custom em objetos standard, Decision Matrix/Expression Set (OmniStudio/BRE, licenciado) e Custom Metadata — nenhum desses conta como objeto custom.
- Business Rules Engine: HABILITADO na DevSales (confirmado por Diego, 04/08/2026). Motor do cálculo de preços/impostos/floors da HU-038: Decision Matrices (GQ_TaxMatrix, GQ_PriceFloorMatrix, GQ_ChannelPolicyMatrix) + Expression Set GQ_VehiclePricing, chamadas com effective date = data da cotización; permissões Rule Engine Designer (admins/analistas) e Rule Engine Runtime (perfis de venda).

## Arquitetura do domínio de preços (decidida em 30/07/2026, enviada à Melisa/OSF)
- Híbrida, definida por quem é mestre do preço:
  - Veículos novos, motos e flotas (HU-038): Salesforce é o mestre do preço comercial. MuleSoft sincroniza catálogo/materiais SAP→SF; preço calculado no SF (PricebookEntry + Decision Matrices + Expression Sets); SAP recebe o preço com o pedido e reaplica o cálculo fiscal — resultados devem coincidir (paridade de arredondamento: SAP calcula com 4 decimais, posiciona com 2).
  - Repuestos & PA (HU-028): SAP é o mestre; consulta on-line via MuleSoft (RFC custom Get_Price_ZGQREF, contrato em definição — Pendência 13); sem preço persistido no SF (Cenário 1); combos = SKU próprio no SAP; simulação fora de R1·S8.
  - Usados: precificação por unidade (por VIN/Asset), fora do modelo de pricebook — frente separada.
- Limitações confirmadas do PricebookEntry (com fontes, 30/07/2026): NÃO suporta Apex trigger, record-triggered flow, Process Builder nem Approval Process clássico (Ideas abertas). SUPORTA Field History Tracking e Field Audit Trail (release note Winter '20).
- Aprovação de preços (HU-038) sem objeto custom: entrada controlada por screen flows, IsActive como estado de aprovação (entrada inativa não é usável comercialmente — nativo), validation rules com ISNEW/PRIORVALUE/$Permission, notificação disparada pelos flows de entrada, Field History como trilha.
- Multimoeda: HABILITADA na DevSales (confirmado 04/08/2026 em Manage Currencies): CRC = corporate (ativada 26/03 por OSF), USD ativa (23/07). Demais moedas (GTQ etc.) entram conforme onboarding dos países. Dependência país↔moeda: CurrencyIsoCode não participa de field dependencies; controle por validation rule (mapeamento país→moedas permitidas, idealmente via $CustomMetadata) + moeda default do usuário por país.
