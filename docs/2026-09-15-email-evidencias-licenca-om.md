# E-mail de formalização — evidências da licença de Industries Order Management (rascunho de 15/09/2026)

Para: Bismarck. Cc: Gerson. Anexos: (1) PDF do case #473919801; (2) 3 prints de Setup > Company Information > Usage-Based Entitlements de produção; (3) export de PermissionSetLicense de produção (CSV); (4) print de Installed Packages de produção; (5) log do Execute Anonymous com a licença do pacote Vlocity CMT.

---

Assunto: Evidências — licença de Industries Order Management em produção (cortesia vencida em 16/06/2026)

Bismarck, boa tarde. Gerson em cópia.

Conforme combinado com o Gerson, seguem as evidências do estado da licença de Industries Order Management (OM) na org de produção (prod-brasiltecpar), levantadas hoje.

1. Case Salesforce #473919801 (aberto em 23/06/2026 pelo João Pedro, fechado em 02/07). O suporte confirmou que a preprod (Org 00DHZ000006zyyM) tinha as licenças OrderManagement, OrderManagementAddon, IndustriesOMB2BOrders1000AddOn e IndustriesOMB2COrders5000AddOn e que a produção não tinha, orientando acionar o AE para provisionar. O João registrou que as licenças de produção eram trial e que a compra seria feita após definir o volume de ordens por mês. O suporte informou que o último orchestration plan em produção foi criado em 28/05/2026. Anexo 1.

2. Usage-Based Entitlements de produção (Setup > Company Information), em 15/09/2026. O único direito de OM é "Maximum B2C orders submitted via Industries Order Management allowed for an org": início 11/06/2025, término 16/06/2026, frequência Once, Allowance 0, 252 ordens usadas, último uso em 29/05/2026. Não existe linha de ordens B2B. Todos os demais direitos da org vencem em 17/06/2028. Anexo 2.

3. Permission Set Licenses de produção, em 15/09/2026. Não há nenhuma PSL de Order Management. A Comms Cloud Plus está ativa com 2.100 assentos, 1.950 atribuídos, válida até 17/06/2028; Document Generation for CME com 624 usuários e OmniStudio com 262. Anexo 3.

4. Installed Packages de produção: Vlocity CMT 900.650.3, instalado em 13/09/2025. O OM faz parte desse pacote; o que falta é a licença de uso, não a instalação. Anexo 4.

Conclusão: a cortesia de OM foi provisionada por 12 meses, de 11/06/2025 a 16/06/2026, e não até 2028. O que vai até 17/06/2028 é o contrato principal e as demais licenças. O case foi aberto sete dias depois do vencimento e a decomposição de ordens parou junto com ele. A preprod mostrava as licenças em junho porque a sandbox copia as licenças de produção na data do refresh. Se as licenças de OM já constam do novo aditivo, elas ainda não foram provisionadas em produção: a linha de ordens B2C segue vencida com Allowance 0 e não há linha de ordens B2B nem PSL de OM.

Impacto no projeto: enquanto a provisão não ocorrer, nenhuma jornada que submete pedido ao Order Management pode ir a produção (decomposição e orquestração B2C, Imputar Venda B2B, MACD B2B, aviso prévio de cancelamento). A work W-000134 no Agile Accelerator acompanha o tema.

O que precisamos:
a) Texto ou número da ordem da cortesia de OM, com a data de término contratada, para confrontar com o 16/06/2026 da org.
b) Número do pedido do novo aditivo e a data prevista de provisão das licenças de OM em produção, com confirmação do AE de que os add-ons de ordens B2B e B2C e a licença de plataforma OrderManagement serão provisionados.
c) O Gerson vai gerar com você as evidências complementares da preprod (data do último refresh e a tela de entitlements de lá).

Fico à disposição para acompanhar a provisão e revalidar na org assim que o AE confirmar.

Abraço,
Diego
