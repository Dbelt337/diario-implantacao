# Como verificar na org: versão do CME/CPQ, carrinho em uso, CLM e Order Management

Objetivo: fechar as três perguntas abertas nas works B2B-13 a B2B-16 (carrinho CPQ, CLM ativo, OM licenciado) com evidência da própria org, não com suposição. Fontes: case Salesforce #473919801 (PDF colado em 15/09) e páginas do Salesforce Help identificadas por busca (as marcadas "a colar" ainda não foram lidas na íntegra).

## 1. O que o case #473919801 já provou (23/06 a 02/07/2026)

- Título: "Order Decomposition issue in Salesforce Industries / Vlocity org". Aberto por João Pedro Galvão e Albuquerque Lima, atendido por Sridhar Khandavilli (Signature Support). Fechado em 02/07 pelo João como resolvido.
- **O pacote CME está instalado com namespace `vlocity_cmt`**: o suporte abriu a página `vlocity_cmt` `XOMViewOrderDecomposition` na sandbox (`preprod-brasiltecpar--staging--vlocity-cmt.sandbox.vf.force.com/apex/XOMViewOrderDecomposition?id=801HZ00000j1zfV`). Logo, EPC, CPQ, CLM e OM (XOM) vêm do mesmo pacote gerenciado.
- **Sandbox preprod (Org Id 00DHZ000006zyyM) tem as licenças de Industries OM provisionadas**, segundo o suporte: Add-On `IndustriesOMB2BOrders1000AddOn`, `IndustriesOMB2COrders5000AddOn`, `OrderManagementAddon`; Platform License `OrderManagement`. A decomposição funciona lá.
- **Produção não tem essas licenças**: o João procurou em Company Information e não achou; o suporte pediu para acionar o AE. Em 02/07 o João explicou que as licenças provisionadas em produção eram **trial**, que "alguém da empresa" compraria as licenças e que estavam decidindo **quantas ordens por mês** precisam orquestrar para dimensionar a quantidade. O suporte registrou que **o último orchestration plan em produção foi criado em 28/05/2026**.
- Consequência para o projeto: toda work que submete pedido ao OM em produção (W-000088, W-000093, W-000118 TEC-OM-01, W-000101 Imputar Venda, B2B-14 corte automático, W-000125, W-000100) depende de a compra ter sido concluída. **Pendência nova: confirmar com o João/AE se as licenças de OM foram compradas depois de 02/07 e em que quantidade (ordens B2B e B2C por mês).** Os nomes dos add-ons ("B2BOrders1000", "B2COrders5000") indicam blocos de ordens por período, o que casa com a pergunta de "quantas ordens por mês".

## 2. Versão do pacote CME (base de tudo)

Onde ver (plataforma padrão):
- Setup > Installed Packages: linha do pacote com namespace `vlocity_cmt` (nome comercial "Salesforce Industries Communications, Media, and Energy" ou "Vlocity Communications"); anotar Version Number e data de instalação/upgrade.
- Tooling API (Developer Console ou sfdx, "Use Tooling API"):
  ```
  SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix,
         SubscriberPackageVersion.Name, SubscriberPackageVersion.MajorVersion,
         SubscriberPackageVersion.MinorVersion, SubscriberPackageVersion.PatchVersion
  FROM InstalledSubscriberPackage
  ```
  (objeto InstalledSubscriberPackage, Tooling API 41.0+; a página oficial diz que InstalledSubscriberPackageVersion está deprecado, usar InstalledSubscriberPackage.)
- Vlocity CMT Administration (App Launcher > Vlocity CMT Administration): é onde ficam os jobs de manutenção, os jobs de EPC e os Custom Settings do CPQ; serve também para confirmar que os post-install steps da release instalada foram executados (as páginas de post-install são por release: Winter '22, Spring '22, Summer '22, Spring '23...).
- Fazer a verificação **nas duas orgs** (preprod 00DHZ000006zyyM e produção) e comparar versões: sandbox e produção podem estar em releases diferentes.

## 3. Qual carrinho do Industries CPQ está em uso

A documentação lida define três interfaces: Angular (Hybrid), LWC CPQ (Flexcards, desde Winter '22) e Enhanced LWC CPQ (componentes nativos, desde Spring '24). Como descobrir:

1. **Teste funcional**: numa Quote B2B de sandbox, acionar "Add Products"/"Configure". Pela documentação, o carrinho em LWC abre dentro do app **Industries CPQ** (App Launcher), a partir de Order/Quote ou da aba Assets da conta, num layout LWC; o carrinho Angular é a página Visualforce do pacote (URL `/apex/vlocity_cmt__...`). Se a URL for Visualforce, é Angular; se for página Lightning do app Industries CPQ, é LWC.
2. **LWC Flexcards ou Enhanced**: a diferença é um ajuste de habilitação ("Enable the Enhanced CPQ Cart with LWC"). Os passos exatos e o nome da configuração estão na página a colar (item 6). Pela documentação já lida, o Enhanced só existe em pacotes Spring '24 ou posteriores, então a versão do item 2 já elimina a hipótese se o pacote for anterior.
3. **Custom Settings**: Vlocity CMT Administration > Custom Settings > **CPQ Configuration Setup** lista Configuration Name / Setup Value; exportar a lista inteira (print ou query em `vlocity_cmt__CPQConfigurationSetup__c`) e conferir contra a "CPQ Configuration Settings Reference" (a colar).
4. Registrar também o que a W-000084 (botão Criar Cotação / Create Cart) e a W-000086 (OmniScript Nova Venda) assumem, para as works B2B usarem o mesmo carrinho.

## 4. CLM (Vlocity Contracts) instalado e ativo

O CLM faz parte do pacote CME (a página de Communications Cloud lista "Contract Lifecycle Management" entre os módulos), mas só funciona depois dos post-install steps. Evidências a coletar:

1. Setup > Object Manager: objetos de contrato do pacote (`vlocity_cmt__` com "Contract" no nome: Contract Type, Contract State Model, Contract Version/Document, Clause, Document Template). Existir objeto prova só a instalação.
2. **Registros de configuração** (prova de ativação, conforme "Contract Administration Example"): existe ao menos um **Contract Type** cadastrado? Há **Record Types** de Contract habilitados por perfil? Há **Vlocity Actions** ativas para Contract com To State preenchido (Contract State Model)? Há **Document Templates** e **Clauses** de contrato? Os **Vlocity CLM Custom Settings** estão preenchidos (página a colar)?
3. Tabs/app: existe app ou aba de "Contract Lifecycle Management"/"Contracts" do pacote disponível aos perfis?
4. Uso real: `SELECT COUNT() FROM Contract WHERE RecordType.DeveloperName != null` e contratos com documento gerado; TEC-CLM-01 (W-000126) e B2B-09 (W-000122) assumem CLM, então confirmar com o Davi o que já foi configurado na Onda 1.
5. DocuSign: a integração para lembretes e eSignature é recurso do CLM; conferir se o conector está instalado (Installed Packages) e ligado ao CLM, porque a W-000105 (canal de assinatura) e a B2B-16 dependem disso.

## 5. Industries Order Management: licença, versão e configuração

### 5.1 Licença (o ponto crítico do case)
- Setup > Company Information: seções **Permission Set Licenses** (procurar "Order Management"/"Industries Order Management") e **Usage-Based Entitlements** (procurar os add-ons `IndustriesOMB2BOrders1000AddOn`, `IndustriesOMB2COrders5000AddOn`, `OrderManagementAddon`). A documentação de Usage-Based Entitlements diz que esses medidores ficam em Setup > Company Information > Usage-Based Entitlements e que a contagem pode levar 24 h para atualizar.
- SOQL (Developer Console, qualquer org):
  ```
  SELECT DeveloperName, MasterLabel, TotalLicenses, UsedLicenses, Status, ExpirationDate
  FROM PermissionSetLicense ORDER BY MasterLabel

  SELECT MasterLabel, Setting, ResourceGroupKey, CurrentAmountAllowed, AmountUsed,
         StartDate, EndDate, UsageDate
  FROM TenantUsageEntitlement ORDER BY MasterLabel
  ```
  Rodar nas duas orgs e comparar: a preprod deve mostrar os quatro itens que o suporte listou; a produção mostra se a compra aconteceu e o volume contratado (CurrentAmountAllowed) e consumido (AmountUsed).
- Se produção continuar sem as licenças, registrar como bloqueio de go-live de qualquer jornada com submissão ao OM e levar ao AE (Account Executive), como o suporte orientou.

### 5.2 OM Standard ou OM Plus
- A documentação separa "Order Management Plus" (com patch releases próprias e "OM Plus: Security and Encryption") de OM Standard. Qual está contratado define orquestração e limites; página "Order Management Plus" e "Configuring OM and OM Plus Interfaces" a colar. Pista prática: os nomes das licenças do case não contêm "Plus".

### 5.3 Configuração e uso
- Orchestration plans: o suporte viu que o último plano em produção foi de 28/05/2026. Consultar os objetos de orquestração do pacote (nomes a confirmar no Object Manager: Orchestration Plan, Orchestration Item, Orchestration Plan Definition, Decomposition Relationship) ordenados por CreatedDate desc, nas duas orgs, para saber quais planos e relações de decomposição existem e se são de teste ou de produção.
- Decomposição: abrir `/apex/vlocity_cmt__XOMViewOrderDecomposition?id=<OrderId>` numa ordem submetida (o mesmo caminho que o suporte usou) e verificar se gera a visão; em produção, sem licença, falha.
- Permission sets: página "Settings for Order Management Permission Sets and Permission Set Groups" (a colar) lista os PSGs esperados; conferir se os usuários de BKO têm.
- Troubleshooting oficial: "Troubleshooting Industries Order Management" e "Orchestration Plan Is Not Visible" (a colar) descrevem as causas de plano não gerado; usar para diferenciar falta de licença de erro de configuração.

## 6. Páginas a colar para fechar este roteiro (prioridade)

| Pri | Página | Fecha o quê |
|---|---|---|
| A | https://help.salesforce.com/s/articleView?id=ind.comms_enable_the_enhanced_cpq_cart_with_lightning_web_components_lwc.htm&type=5 | Como se habilita o Enhanced LWC (e, por consequência, como saber se está habilitado) |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_comparing_key_features_of_industries_cpq_versions.htm&type=5 | Matriz Angular x LWC x Enhanced: o que cada work B2B pode assumir |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_order_management_plus.htm&type=5 | OM Plus x Standard |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_t_troubleshooting_industries_order_management_242806.htm&type=5 | Causas de decomposição/orquestração não gerada |
| A | https://help.salesforce.com/s/articleView?id=ind.v_contracts_vlocity_clm_custom_settings_368284.htm&type=5 | Custom settings que provam CLM ativo |
| A | https://help.salesforce.com/s/articleView?id=sf.users_usagebased_entitlements_viewing.htm&type=5 | Onde os add-ons de OM aparecem em Company Information |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_cpq_configuration_settings_reference_148927.htm&type=5 | Referência dos CPQ Configuration Setup (longa) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_open_the_industries_cpq_cart_in_lwc_176857.htm&type=5 | Como o carrinho LWC é aberto (identificação pela navegação) |
| B | https://help.salesforce.com/s/articleView?id=ind.v_contracts_post_install_clm_cme_winter23.htm&type=5 | Post-install do CLM (checklist do que deve existir) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_configuring_om_and_om_plus_interfaces_240345.htm&type=5 | Interfaces OM/OM Plus |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_settings_for_order_management_permission_sets_and_permission_set_groups_240769.htm&type=5 | PSGs de OM |
| B | https://help.salesforce.com/s/articleView?id=ind.iom_orchestration_plan_is_not_visible.htm&type=5 | Plano de orquestração não visível |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_accessing_the_vlocity_cmt_administration_tab.htm&type=5 | Aba CMT Administration |
| C | https://help.salesforce.com/s/articleView?id=platform.users_permissionset_licenses_view.htm&type=5 | Ver PSLs |

## 7. Evidências que só a org dá (pedir ao Davi/João ou coletar em sandbox)

1. Print de Setup > Installed Packages (preprod e produção).
2. Print de Company Information > Permission Set Licenses e Usage-Based Entitlements (preprod e produção), ou resultado das duas SOQL do item 5.1.
3. Print de Vlocity CMT Administration > Custom Settings > CPQ Configuration Setup (lista completa).
4. URL da tela do carrinho ao clicar em Add Products numa Quote de sandbox.
5. Lista de Contract Types, Vlocity Actions de Contract e Document Templates existentes.
6. Resposta do João/AE: as licenças de OM foram compradas? Quantas ordens B2B e B2C por mês?
