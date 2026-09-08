# W-000070 — EPC-10 — Criação dos catálogos comerciais por família e estrutura B2B/B2C

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 26/08/2026 16:20 por Diego Beltrão de Moraes | Alterado: 26/08/2026 16:20 por Diego Beltrão de Moraes

Descrição
Como Administrador do Catálogo de Produtos,
Eu quero que os catálogos comerciais sejam criados por família de produto, conforme a tabela aprovada, com as ofertas da Onda 1 publicadas nas suas famílias,
Para que a vitrine navegue por família (Internet, Segurança, Wi-Fi, Voz, Streaming, Serviços Digitais) e a mesma estrutura de catálogo atenda produtos B2B e B2C sem duplicação de oferta.
Cenário e Contexto de Negócio
Decisão do time sobre os catálogos comerciais: organização por família de produto, e não por mercado. A separação B2B/B2C não é feita por catálogo: a mesma oferta é publicada uma única vez e o recorte por mercado, segmento e canal é garantido pelos rule sets globais de qualificação da US de Qualificação (contexto Tetra-pé: Mercado/Segmento, Canal de Venda, Tipo de Cliente e Cidade IBGE), com a diferenciação de preço via tabelas de preço separadas para B2C e B2B, mantendo o produto estruturalmente unificado no catálogo. Esta decisão deve ser registrada em ADR, e o texto da work de Qualificação já criada no Agile deve ser atualizado para refletir o modelo por família.
Regras de Negócio Associadas
Catálogos a criar (código, nome e ofertas da aba Joel):
CAT_INTERNET, Internet: Internet Home e MPE Urbana, Smart Internet Basic, Smart Internet PME, Smart Internet Corporativa.
CAT_SEGURANCA, Segurança: Smart Firewall (licença Advanced/Premium, prazo 12 a 60 meses).
CAT_WIFI, Wi-Fi: Smart Wi-Fi (Ubiquiti, Huawei, Ruckus; níveis Lite, Advanced, Premium; prazo de locação).
CAT_VOZ, Voz: Smart PBX.
CAT_STREAMING, Streaming: Streaming Playhub (Avançado, Top, Prime).
CAT_SVA, Serviços Digitais: Pacotes SVA Básico e Prime, Aya Bancah, Aya Books, Audiolivro (B2C/B2S).
CAT_TV, TV: reservado, sem oferta nas planilhas ainda; criar inativo para reservar o código.
Publicação N:N permitida: a mesma oferta pode estar em mais de um catálogo (ex.: combos); nenhuma oferta pode ser duplicada por mercado ou canal.
Os códigos CAT_ de catálogo comercial não se confundem com as Attribute Categories da US EPC-01 (objetos distintos); os dois vocabulários devem constar documentados no artefato de parametrização.
Ofertas B2G de venda assistida não são publicadas em vitrine de autosserviço.
Dependências: US de Qualificação (rule sets de contexto e atualização do texto); tabelas de preço por mercado; domínios de qualificação com o Joel (P-19).

## Critérios de Aceite (related list)

**1. 2** (New)
•	Critério 2: Publicação das ofertas por família
Dado que as ofertas da Onda 1 existem no EPC,
Quando a publicação for concluída,
Então cada oferta deve estar publicada no catálogo da sua família conforme a tabela, e a vitrine deve retornar as ofertas ao consultar o código do catálogo da família.

**2. 3** (New)
•	Critério 3: Estrutura B2B/B2C sem duplicação
Dado o mesmo catálogo de família,
Quando a vitrine for consultada com contexto B2C e em seguida com contexto B2B,
Então cada consulta deve retornar apenas as ofertas elegíveis ao mercado, com o preço da tabela de preço correspondente, sem existir oferta duplicada por mercado no catálogo.


Decisões do cliente — fechamento das pendências P-01 a P-19
Todas as pendências e divergências levantadas no refinamento estão decididas abaixo, com fundamento no manual v2.2, na documentação oficial do EPC/Communications Cloud e na tabela de catálogos comerciais aprovada. Este registro vale como ata das ratificações da Onda 0. Não há itens abertos aguardando decisão do cliente; alterações futuras seguem processo de ADR.
P-01 — Default do NOC_TIER. Decisão: Bronze. Fundamento: o manual v2.2 (seções 35.4 e 39.2) é a fonte normativa e determina Bronze; a aba Joel é extrato AS-IS. Iniciar no menor tier evita custo embarcado, e upgrade de tier é ação comercial simples.
P-02 — Estrutura e significado do WITO. Decisão: ratificada a estrutura de dois serviços da aba B2BB2G. WITO fica definido operacionalmente como serviço de suporte a equipamento de terceiros, modelado como child product opcional e faturável com atributo de fabricante, tanto no Firewall quanto no Wi-Fi. O significado literal do acrônimo é registro documental e não altera a modelagem.
P-03 — Modelagem do equipamento de firewall. Decisão: Plano A — EQUIPMENT_MODEL como atributo Picklist com Attribute-Based Pricing e Mapping Rule para o produto técnico, com o equipamento entregue em regime de serviço/locação e material SAP único da oferta gerenciada. Fundamento: regra de simplicidade operacional da seção 3.3 (dezenas de children individuais são proibidos) e política de atributos da 35.4. Migração para child por família somente se surgir material SAP, faturamento ou lifecycle distinto, mediante ADR.
P-04 — Modelo comercial do Smart Wi-Fi. Decisão: Plano B — marca e classe como atributos ortogonais (WIFI_BRAND: Ubiquiti, Huawei, Ruckus; nível: Lite, Advanced, Premium) com regra de compatibilidade entre eles. Fundamento: a tabela de catálogos comerciais aprovada exibe marca e nível como decisão comercial visível (CAT_WIFI); o atributo composto marca-tier-ambiente da planilha original permanece proibido pela regra de menor entidade (seção 3.1). Pricing por combinação via Attribute-Based Pricing.
P-05 — IPv4 em blocos. Decisão: atributo (IPV4_PROFILE) na Onda 1. Fundamento: seção 35.4 — a promoção a child product fica condicionada à existência de material SAP e lifecycle próprios por bloco; enquanto não houver, o atributo atende. Reavaliação via ADR quando a lista de materiais SAP for cruzada.
P-06 — Fail-Over e Bastidor na estrutura. Decisão: ratificados. Fail-Over com tiers Standard, Professional e Full e Bastidor (5U, 12U, 40U) integram a estrutura da oferta corporativa conforme a aba B2BB2G. Este registro vale como a ratificação em ata prevista na revisão.
P-07 — Sanitização da grade de banda. Decisão: aprovada a regra objetiva da seção 40 — entram ativos somente os valores de velocidade com MRC positivo na grade sanitizada (RULE_EXCLUDE_NULL_PRICE_SPEEDS); os demais permanecem inativos e a lista de exclusões acompanha a carga como evidência. Não há aprovação item a item.
P-08 — Hierarquia normativa de Object Types. Decisão: ratificada a hierarquia da seção 35.3 como normativa, incluindo a extensão de serviços gerenciados da US EPC-04; a seção 6.1 passa a referência histórica. Este registro vale como a ratificação da Onda 0.
P-09 — Smart PBX. Decisão: confirmado fora da Onda 1; destino é a onda seguinte do catálogo, com a estrutura completa da aba B2BB2G (ramais SIP, módulos E1, FXS, FXO e GSM, bastidor) preservada como insumo de refinamento. O catálogo CAT_VOZ é criado desde já (US EPC-10) para receber a oferta.
P-10 — Licenciamento do Smart Firewall. Decisão: Advanced e Premium, com Advanced como default, conforme a tabela de catálogos comerciais aprovada (CAT_SEGURANCA). A dupla Basic/Advanced da aba B2BB2G fica descartada.
P-11 — Variantes VDOM e Prazo de Licenciamento. Decisão: o Prazo está confirmado para Firewall e Wi-Fi, reutilizando PL_CONTRACT_TERM (12 a 60 meses, default 36), conforme a tabela aprovada. As 3 variantes VDOM ficam fora da Onda 1; a lista base de modelos é a da B2BB2G (34 modelos), e a inclusão de variantes ocorre via governança quando houver material SAP correspondente.
P-12 — Curadoria do Meio de Acesso. Decisão: a Onda 1 ativa os 8 meios da aba Joel (corte comercial vigente); os 5 adicionais da B2BB2G são cadastrados inativos na PL_ACCESS_MEDIA, preservando a lista técnica completa para ativação futura sem retrabalho.
P-13 — Anotação NFE#1 no Upload. Decisão: tratada como nota de revisão, sem efeito de default. O default do UPLOAD_PROFILE permanece Padrão.
P-14 — Determinação automática da tecnologia de acesso. Decisão: mantida a deliberação de 14/08 — fora do escopo atual; na Onda 1, ACCESS_TECHNOLOGY tem valor padrão definido no catálogo pela engenharia, com override por produto, pela mecânica nativa do EPC.
P-15 — Porta Secundária obrigatória com Fail-Over. Decisão: regra confirmada e mantida como parametrizada (RULE_FAILOVER_REQUIRES_SECONDARY, manual v2.2 seção 39.2). Fundamento funcional: contingência sem caminho físico secundário não entrega a função contratada.
P-16 — Momento da integração SAP de materiais. Decisão: no Order Management (decomposição/fulfillment), não na venda. Fundamento: padrão Communications Cloud — a venda opera exclusivamente sobre o catálogo comercial; o de-para técnico e os materiais pertencem à decomposição das ordens, evitando acoplamento e latência no carrinho. O mapeamento de materiais segue pré-requisito das USs de decomposição.
P-17 — Group Promotion ID. Decisão: a rastreabilidade do combo usa os registros nativos de promoção aplicada do pacote CMT nos itens de cotação e ordem, expostos como Group Promotion ID no payload de integração. Não se cria campo custom adicional na Onda 1; caso uma integração externa exija persistência própria, a extensão entra via ADR.
P-18 — Domínios de qualificação. Decisão: adotado o domínio inicial — Mercados: B2C, B2S, B2B, B2G e Wholesale; Canais de venda: Unidades/Loja, Inside Sales, PAP Terceiros, Terceiros Digitais, E-commerce/App e Call Center; Tipo de Cliente: CPF e CNPJ; Cidade: código IBGE resolvido pelo objeto do P-17. Os 4 rule sets globais de qualificação permanecem fixos; ampliações de valores ocorrem por governança de catálogo, sem mudança estrutural.

**3. 1** (New)
•	Critério 1: Catálogos criados conforme a tabela
Dado que a tabela de catálogos comerciais foi aprovada,
Quando a parametrização for concluída,
Então os 7 catálogos devem existir com código e nome conforme a tabela, seis ativos e o CAT_TV reservado inativo.
