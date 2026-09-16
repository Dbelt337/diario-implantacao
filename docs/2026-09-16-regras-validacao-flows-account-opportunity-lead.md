# 16/09/2026 - Regras de validacao e flows de Account, Opportunity e Lead (retrieve da prod)

Retrieve feito na primeira sessao conectada (`sf project retrieve start -o btp-prod`), org 00DHu00000FcxIgMAJ, API 67.0.
Fonte: `org/force-app/main/default/objects/{Account,Opportunity,Lead}` e `org/force-app/main/default/flows`. Formulas
resumidas em uma linha; o XML completo esta no repositorio.

Leitura rapida para os chamados de sustentacao:
- **Account**: 5 regras ativas de 12. As que pegam nas cargas: ValidaPreenchimentoCluster (exige cluster no usuario executor
  quando a conta B2B PJ nao tem ClusterManual__c; e a do cluster temporario dos scripts 31 e 37), ImpedeTrocaProprietario
  (troca de dono so por Admin Acesso, Administrador do sistema ou B2B - Backoffice, ou com Bypass__c) e ImpedirMudancaDeEndereco
  (endereco so pelo objeto Endereco). As regras de CPF/CNPJ (ValidaCNPJvalido, ValidaCPFeCNPJ, CPForCNPJValidation) estao INATIVAS.
- **Opportunity**: 14 ativas de 18, quase todas travas por fase para o record type B2B, com escape por Bypass__c:
  BloqueiaAlteracaoAnaliseCliente e BloqueiaAlteracaoAguardandoContrato (as duas que o script 37 contorna com Bypass__c = true),
  BloqueiaAlteracaoAprovacaoComercial (so quem tem a permissao SalesManager edita em "Aprovacao comercial"; e a que barra
  ManagerAccount__c ate com unlock), BloqueiaAlteracaoManualFase, BloqueiaAlteracaoCluster, BloqueiaEdicaoOportunidadeGanha,
  BloqueiaEdicaoFechadoPerdido, BloqueiaAlteracaoTermoAprovado. A fase "Aguardando instalacao" nao tem trava de edicao.
- **Lead**: 7 ativas de 14. Conversao e perda so pelos botoes (BloqueiaSelecaoManualLeadGanho / Perdido), endereco completo
  para converter (ValidaCamposObrigatorios), mascaras de telefone e celular so para o record type LegalEntity_B2B (VRPhoneMask,
  VRCellphoneMask) e ValidaPreenchimentoCluster igual a de Account. Para a carga de leads da SDR: as regras de CPF/CNPJ
  (ValidaCPFeCNPJ, DocumentValidation) estao INATIVAS, entao o validador offline e a unica barreira de CNPJ.

## Regras de validacao

### Account (12 regras)

- **BillingAddressRequired** (inativa): Por favor, preencha endereço com as informações: Logradouro, complemento, cidade, estado, país e CEP no formato 99999-999.
  - `AND( NOT(ISNEW()), OR( ISBLANK(BillingStreet), ISBLANK(BillingAddressComplement__c), ISBLANK(BillingCity), ISBLANK(BillingState), ISBLANK(BillingCountry), ISBLANK( BillingAddressNumber__c ), ISBLANK( BillingDistrict__c ), NOT( REGEX(BillingPostalCode, "^[0-9]{5}-[0-9]{3}$") ) ) )`
- **CPForCNPJValidation** (inativa): O campo "Número do Documento" deve estar no formato: -CPF: 999.999.999-99 ou sem os caracteres especiais; -CNPJ: 99.999.999/9999-99 ou sem os caracteres especiais.
  - `NOT( OR( /* CPF com máscara OU sem máscara */ REGEX(DocumentNumber__c, "^[0-9]{3}\\.[0-9]{3}\\.[0-9]{3}-[0-9]{2}$"), REGEX(DocumentNumber__c, "^[0-9]{11}$"), /* CNPJ com máscara OU sem máscara */ REGEX(DocumentNumber__c, "^[0-9]{2}\\.[0-9]{3}\\.[0-9]{3}/[0-9]{4}-[0-9]{2}$"), REGEX(DocumentNumber__c, "^[0-9]{14}$") ) )`
- **ImpedeTrocaProprietario** (ativa): Você não tem permissão para alterar o proprietário desta conta.
  - `AND( NOT(ISNEW()), ISCHANGED(OwnerId), OR( RecordType.DeveloperName = "PersonEntity_B2B", RecordType.DeveloperName = "LegalEntity_B2B" ), AND( NOT( OR( $Profile.Name = "Admin Acesso", $Profile.Name = "Administrador do sistema", $Profile.Name = "B2B - Backoffice" ) ), NOT(Bypass__c) ) )`
- **ImpedirMudancaDeEndereco** (ativa): A atualização de endereço deve ser feita pelo objeto personalizado Endereço
  - `AND( RecordTypeName__c = "B2B - Pessoa jurídica", NOT(ISNEW()), NOT(Bypass__c), OR( ISCHANGED(BillingAddressComplement__c), ISCHANGED(BillingAddressNumber__c), ISCHANGED(BillingCity), ISCHANGED(BillingCountryCode), ISCHANGED(BillingNeighborhood__c), ISCHANGED(BillingObservations__c), ISCHANGED(BillingPostalCode), ISCHANGED(BillingStateCode), ISCHANGED(BillingStreet), ISCHANGED(ShippingAddressComplement__c), ISCHANGED(ShippingAddressNumber__c), ISCHANGED(ShippingCity), ISCHANGED(ShippingCountryCode), ISCHANGED(ShippingNeighborhood__c), ISCHANGED(ShippingObservations__c), ISCHANGED(ShippingPostalCode), ISCHANGED(ShippingStateCode), ISCHANGED(ShippingStreet) ) ) && !ISCHANGED(ByPassStamp__c)`
- **PhoneValidationFormat** (inativa): O número de telefone deve estar no formato DDD + Número, com 10 ou 11 dígitos. Ex: 11987654321 (celular) ou 1134567890 (fixo).
  - `NOT( REGEX(Phone, "^[0-9]{10,11}$" ) )`
- **ValidaCNPJvalido** (inativa): Atenção, o CNPJ informado é incorreto para este tipo de registro. Informar um valor válido e formato correto. Ex: CNPJ: XX.XXX.XXX/XXXX-XX
  - `AND( /* regras gerais */ NOT(IsInternational__c), !ISBLANK(DocumentNumber__c), RecordTypeName__c = "B2B - Pessoa jurídica", /*Valida o formato correto do CNPJ*/ OR( NOT( AND( LEN(DocumentNumber__c) = 18, MID(DocumentNumber__c, 3, 1) = ".", MID(DocumentNumber__c, 7, 1) = ".", MID(DocumentNumber__c, 11, 1) = "/", MID(DocumentNumber__c, 16, 1) = "-" ) ), /*Valida os digitos verificadores do CNPJ*/ IF(LEN(DocumentNumber__c)=18, OR( AND( MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2) ),11)<=1, VALUE(MID(DocumentNumber__c,18,1))!=0 ), AND( MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2) ),11)>1, (11-MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2) ),11) )!=VALUE(MID(DocumentNumber__c,18,1)) ) ), false) ) )`
- **ValidaCPFeCNPJ** (inativa): Atenção, o CNPJ/CPF informado é incorreto. Informar um valor válido e formato correto. Ex: CPF: XXX.XXX.XXX-XX CNPJ: XX.XXX.XXX/XXXX-XX
  - `AND( /*Valida o formato correto do CPF*/ OR(NOT(AND( LEN(DocumentNumber__c) = 14, MID(DocumentNumber__c, 4, 1) = ".", MID(DocumentNumber__c, 8, 1) = ".", MID(DocumentNumber__c, 12, 1) = "-")) ,/*Valida os digitos verificadores do CPF*/ NOT(OR( LEN(DocumentNumber__c)=0,AND(MOD(MOD(11-MOD( VALUE(MID(DocumentNumber__c,1,1))*10+ VALUE(MID(DocumentNumber__c,2,1))*9+ VALUE(MID(DocumentNumber__c,3,1))*8+ VALUE(MID(DocumentNumber__c,5,1))*7+ VALUE(MID(DocumentNumber__c,6,1))*6+ VALUE(MID(DocumentNumber__c,7,1))*5+ VALUE(MID(DocumentNumber__c,9,1))*4+ VALUE(MID(DocumentNumber__c,10,1))*3+ VALUE(MID(DocumentNumber__c,11,1))*2,11),11),10)= VALUE(MID(DocumentNumber__c,13,1)),MOD(MOD(11-MOD( VALUE(MID(DocumentNumber__c,1,1))*11+ VALUE(MID(DocumentNumber__c,2,1))*10+ VALUE(MID(DocumentNumber__c,3,1))*9+ VALUE(MID(DocumentNumber__c,5,1))*8+ VALUE(MID(DocumentNumber__c,6,1))*7+ VALUE(MID(DocumentNumber__c,7,1))*6+ VALUE(MID(DocumentNumber__c,9,1))*5+ VALUE(MID(DocumentNumber__c,10,1))*4+ VALUE(MID(DocumentNumber__c,11,1))*3+ VALUE(MID(DocumentNumber__c,13,1))*2,11),11),10)= VALUE(MID(DocumentNumber__c,14,1)))))) , /*Valida o formato correto do CNPJ*/ OR(NOT(AND( LEN(DocumentNumber__c) = 18, MID(DocumentNumber__c, 3, 1) = ".", MID(DocumentNumber__c, 7, 1) = ".", MID(DocumentNumber__c, 11, 1) = "/", MID(DocumentNumber__c, 16, 1) = "-")) ,/*Valida os digitos verificadores do CNPJ*/ IF(LEN(DocumentNumber__c)=18,OR(AND(MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2)) ,11)<=1 ,VALUE(MID(DocumentNumber__c,18,1))!=0) ,AND(MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2)) ,11)>1 ,(11-MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2) ),11 ))!=VALUE(MID(DocumentNumber__c,18,1)))),false)), NOT($Profile.Name = 'System Administrator'), NOT(IsInternational__c) )`
- **ValidaCPFvalido** (inativa): Atenção, o CPF informado é incorreto para este tipo de registro. Informar um valor válido e formato correto. Ex: CPF: XXX.XXX.XXX-XX
  - `AND( /* regras gerais */ NOT(IsInternational__c), RecordType.DeveloperName = "PersonEntity_B2B", /*Valida o formato correto do CPF*/ OR( NOT( AND( LEN(DocumentNumber__c) = 14, MID(DocumentNumber__c, 4, 1) = ".", MID(DocumentNumber__c, 8, 1) = ".", MID(DocumentNumber__c, 12, 1) = "-" ) ), /*Valida os digitos verificadores do CPF*/ NOT( OR( LEN(DocumentNumber__c)=0, AND( MOD(MOD(11-MOD( VALUE(MID(DocumentNumber__c,1,1))*10+ VALUE(MID(DocumentNumber__c,2,1))*9+ VALUE(MID(DocumentNumber__c,3,1))*8+ VALUE(MID(DocumentNumber__c,5,1))*7+ VALUE(MID(DocumentNumber__c,6,1))*6+ VALUE(MID(DocumentNumber__c,7,1))*5+ VALUE(MID(DocumentNumber__c,9,1))*4+ VALUE(MID(DocumentNumber__c,10,1))*3+ VALUE(MID(DocumentNumber__c,11,1))*2,11),11),10)= VALUE(MID(DocumentNumber__c,13,1)), MOD(MOD(11-MOD( VALUE(MID(DocumentNumber__c,1,1))*11+ VALUE(MID(DocumentNumber__c,2,1))*10+ VALUE(MID(DocumentNumber__c,3,1))*9+ VALUE(MID(DocumentNumber__c,5,1))*8+ VALUE(MID(DocumentNumber__c,6,1))*7+ VALUE(MID(DocumentNumber__c,7,1))*6+ VALUE(MID(DocumentNumber__c,9,1))*5+ VALUE(MID(DocumentNumber__c,10,1))*4+ VALUE(MID(DocumentNumber__c,11,1))*3+ VALUE(MID(DocumentNumber__c,13,1))*2,11),11),10)= VALUE(MID(DocumentNumber__c,14,1)) ) ) ) ) )`
- **ValidaEnderecoObrigatorio** (inativa): Atenção: Para atualizar a conta, todos os campos da seção 'endereço' devem ser preenchidos.
  - `AND( NOT(ISNEW()), OR( AND( OR( NOT(ISBLANK(BillingStreet)), NOT(ISBLANK(BillingCity)), NOT(ISBLANK(BillingState)), NOT(ISBLANK(BillingPostalCode)), NOT(ISBLANK(BillingCountry)), NOT(ISBLANK(BillingNeighborhood__c)), NOT(ISBLANK(BillingAddressNumber__c)) ), OR( ISBLANK(BillingStreet), ISBLANK(BillingCity), ISBLANK(BillingState), ISBLANK(BillingPostalCode), ISBLANK(BillingCountry), ISBLANK(BillingNeighborhood__c), ISBLANK(BillingAddressNumber__c) ) ), AND( OR( NOT(ISBLANK(ShippingStreet)), NOT(ISBLANK(ShippingCity)), NOT(ISBLANK(ShippingState)), NOT(ISBLANK(ShippingPostalCode)), NOT(ISBLANK(ShippingCountry)), NOT(ISBLANK(ShippingNeighborhood__c)), NOT(ISBLANK(ShippingAddressNumber__c)) ), OR( ISBLANK(ShippingStreet), ISBLANK(ShippingCity), ISBLANK(ShippingState), ISBLANK(ShippingPostalCode), ISBLANK(ShippingCountry), ISBLANK(ShippingNeighborhood__c), ISBLANK(ShippingAddressNumber__c) ) ) ) )`
- **ValidaPreenchimentoCluster** (ativa): Atenção: seu usuário não está definido a um cluster. Necessário preenchimento do campo para seguir.
  - `AND( RecordTypeName__c = "B2B - Pessoa jurídica", ISPICKVAL($User.Cluster__c, ""), OR( ISPICKVAL(ClusterManual__c, ""), ISBLANK(TEXT(ClusterManual__c)) ) )`
- **vlocity_cmt__EnforceAutoPaymentMethodPicked** (ativa): Please choose the auto payment method and payment amount to enable the auto payment.
  - `( vlocity_cmt__EnableAutopay__c ) && (ISNULL( vlocity_cmt__AutoPaymentMethodId__c ) || ISPICKVAL( vlocity_cmt__AutoPaymentAmount__c , '') )`
- **vlocity_cmt__EnforceBillingEmailAdressFilled** (ativa): Please fill in your billing email address.
  - `ISPICKVAL(vlocity_cmt__BillDeliveryMethod__c, 'eMail') && (ISNULL(vlocity_cmt__BillingEmailAddress__c) || ISBLANK(vlocity_cmt__BillingEmailAddress__c) )`

### Opportunity (18 regras)

- **BloqueaEdicaoRelacionados** (inativa): Atenção: não é possível editar os campos 'Observações da proposta', 'Grupo econômico' e 'Contrato relacionado' nesta fase da Oportunidade.
  - `AND( NOT(ISNEW()), OR( ISPICKVAL(StageName, 'Viabilidade técnica'), ISPICKVAL(StageName, 'Fechado/Ganho'), ISPICKVAL(StageName, 'Fechado/Perdido') ), OR( ISCHANGED(ProposalDescription__c), ISCHANGED(EconomicGroup__c), ISCHANGED(ContractId) ) )`
- **BloqueiaAlteracaoAguardandoContrato** (ativa): Atenção: Durante a fase de 'Aguardando contrato', apenas é permitido editar as informações da seção 'Informações do Contrato'.
  - `AND( RecordTypeName__c = 'B2B', TEXT(StageName) = 'Aguardando contrato', NOT(ISCHANGED(StageName)), NOT(ISCHANGED(AttachedTerm__c)), NOT(Bypass__c), NOT(ISCHANGED(Bypass__c)), OR( ISBLANK(TEXT(ContractStartType__c)), ISBLANK(ContractStartDate__c), ISBLANK(TEXT(ContractEndManual__c)), NOT( OR( ISCHANGED(ContractStartType__c), ISCHANGED(ContractStartDate__c), ISCHANGED(ContractEndManual__c), ISCHANGED(ContractPendencies__c) ) ) ) )`
- **BloqueiaAlteracaoAnaliseCliente** (ativa): Atenção: usuário não possui autorização para manipular o registro nesta fase.
  - `AND( RecordTypeName__c = 'B2B', NOT(ISNEW()), TEXT(StageName) = 'Análise cliente', Bypass__c = false, NOT(ISCHANGED(Bypass__c)), NOT( AND( NOT(ISCHANGED(StageName)), NOT(ISCHANGED(OverallApproval__c)), NOT(ISCHANGED(Bypass__c)), OR( ISCHANGED(CloseDate), ISCHANGED(Stage__c), ISCHANGED(ProposalSubmitted__c), ISCHANGED(Amount), ISCHANGED(ContractEndManual__c) ) ) ) )`
- **BloqueiaAlteracaoAprovacaoComercial** (ativa): Atenção: não é possível ao usuário 'Vendedor/GR' editar uma Oportunidade/Cotação enquanto o registro está em aprovação.
  - `AND( RecordTypeName__c = 'B2B', TEXT(StageName) = 'Aprovação comercial', NOT(ISCHANGED(StageName)), NOT($Permission.SalesManager), NOT(Bypass__c), NOT(ISCHANGED(Bypass__c)) )`
- **BloqueiaAlteracaoAprovacaoTecnica** (ativa): Atenção: usuário não possui autorização para editar este registro nesta fase
  - `AND( RecordTypeName__c = 'B2B', NOT(ISNEW()), TEXT(StageName) = 'Viabilidade e desenho da solução', NOT(ISCHANGED(StageName)), NOT(ISCHANGED(SyncedQuoteId)), $Permission.Seller, NOT(Bypass__c), NOT(ISCHANGED(Bypass__c)) )`
- **BloqueiaAlteracaoCluster** (ativa): Atenção: não é possível criar ou editar registros que não sejam do seu cluster. Contate o administrador para suporte
  - `AND( $Profile.Name <> 'System Administrator', TEXT($User.Cluster__c) != TEXT(Cluster__c), TEXT(PRIORVALUE(Cluster__c)) != TEXT(Cluster__c), NOT(ISBLANK(TEXT(PRIORVALUE(Cluster__c)))) )`
- **BloqueiaAlteracaoManualFase** (ativa): Atenção: não é possível editar manualmente a fase do registro.
  - `AND( RecordTypeName__c = 'B2B', ISCHANGED(StageName), NOT(Bypass__c) )`
- **BloqueiaAlteracaoTermoAprovado** (ativa): Atenção: não é possível realizar edições do registro após a Oportunidade ter um termo anexado.
  - `AND( RecordTypeName__c = 'B2B', TEXT(StageName) = 'Contrato assinado', TEXT(PRIORVALUE(StageName)) = 'Contrato assinado', NOT(Bypass__c), NOT(ISCHANGED(Bypass__c)) )`
- **BloqueiaAvancarAnaliseClienteCamposObrig** (ativa): Atenção: Necessário preencher os campos obrigatórios da fase 'Análise cliente' para avançar a fase.
  - `AND( RecordTypeName__c = 'B2B', NOT(ISNEW()), PRIORVALUE(StageName) = 'Análise cliente', NOT(BaseContractFilled__c), ISCHANGED(StageName), OR( TEXT(StageName) = 'Análise financeira', Text(StageName) = 'Validação técnica' ) )`
- **BloqueiaCamposViabilidadeFechado** (inativa): Atenção: Não é permitido alterar os campos 'Observações da Proposta', 'Vincular ao grupo econômico' ou 'Contrato relacionado' nesta fase da Oportunidade
  - `AND( OR( ISPICKVAL(StageName, 'Viabilidade técnica'), ISPICKVAL(StageName, 'Fechado/Ganho'), ISPICKVAL(StageName, 'Fechado/Perdido') ), OR( ISCHANGED(ProposalDescription__c), ISCHANGED(LinkEconomicGroup__c), ISCHANGED(RelatedContract__c) ) )`
- **BloqueiaEdicaoFechadoPerdido** (ativa): Atenção: não é possível editar a Oportunidade após ter sido perdida.
  - `OR( AND( NOT(ISNEW()), NOT(ISCHANGED(StageName)), TEXT(StageName) = 'Fechado/Perdido', NOT(Bypass__c), NOT(ISCHANGED(Bypass__c)) ), AND( NOT(ISNEW()), TEXT(PRIORVALUE(StageName)) = "Fechado/Perdido", ISCHANGED(StageName) ) )`
- **BloqueiaEdicaoLeadSource** (ativa): Atenção: o campo 'Origem do Lead' não pode ser modificado na Oportunidade.
  - `AND( NOT(ISNEW()), LeadConverted__c, ISCHANGED(LeadSource) )`
- **BloqueiaEdicaoOportunidadeGanha** (ativa): Atenção: não é possível manipular dados de uma Oportunidade que já está fechada
  - `AND( NOT(ISNEW()), NOT(Bypass__c), NOT( AND( ISCHANGED(Bypass__c), PRIORVALUE(Bypass__c) = true ) ), OR( AND( TEXT(StageName) = 'Instalado', NOT(ISCHANGED(StageName)) ), AND( TEXT(PRIORVALUE(StageName)) = "Instalado", ISCHANGED(StageName) ) ) )`
- **ImpedeTrocaProprietario** (ativa): Atenção: Você não tem permissão para alterar o proprietário desta Oportunidade.
  - `AND( NOT(ISNEW()), ISCHANGED(OwnerId), RecordTypeName__c = 'B2B', NOT( OR( $Profile.Name = "Admin Acesso", $Profile.Name = "Administrador do sistema", $Profile.Name = "B2B - Backoffice" ) ) )`
- **LossReasonRequired** (ativa): É obrigatório preencher o campo "Motivo de Perda" quando a Fase for "Fechado/Perdido"
  - `AND( ISPICKVAL(StageName, "Fechado/Perdido"), ISBLANK(TEXT( LossReason__c )), $RecordType.Name = "B2C" )`
- **ObrigaCamposAprovacaoTermo** (inativa): Atenção: Necessário preencher os campos 'Início do contrato', 'Data de início do contrato', 'Renovação automática', 'Prazo do contrato' para seguir com a Oportunidade.
  - `AND( ISPICKVAL(StageName, 'Termo aprovado'), OR( ISBLANK(TEXT(ContractStartType__c)), ISBLANK(ContractStartDate__c), ISBLANK(TEXT(DeliveryTerm__c)) ) )`
- **ObrigaCamposFechadoPerdido** (ativa): Atenção: Necessário preencher o 'Motivo de cancelamento' e 'Descrição do cancelamento' para finalizar a Oportunidade.
  - `AND( ISPICKVAL(StageName, 'Fechado/Perdido'), NOT(Bypass__c), OR( ISBLANK(TEXT(CancellationType__c)), ISBLANK(CancellationDetails__c ) ) )`
- **ObrigaCamposViabilidadeTecnica** (inativa): Atenção: Necessário preencher o 'Tipo de Viabilidade' para seguir com a Oportunidade.
  - `AND( ISPICKVAL(StageName, 'Viabilidade técnica'), ISBLANK(TEXT(ViabilityType__c)) )`

### Lead (14 regras)

- **AddressComplementRequired** (inativa): As informações de endereço são obrigatórios no Lead.
  - `AND( RecordType.DeveloperName = "B2C", OR( ISBLANK(Address), ISBLANK(AddressComplement__c ), ISBLANK( District__c ), ISBLANK( AddressNumber__c ) ) )`
- **BloqueiaConversaoSemCPFCNPJ** (inativa): Atenção: Antes de converter um Lead é necessário preencher o campo 'CPF/CNPJ'.
  - `AND( ISBLANK(DocumentNumber__c), NOT(ISNEW()), IsConverted )`
- **BloqueiaEdicaoLeadPerdido** (ativa): Atenção: Esse lead já está perdido, não é possível converte-lo. Necessário criar um novo!
  - `AND( NOT(ISNEW()), ISCHANGED(Status), ISPICKVAL(PRIORVALUE(Status), 'Unqualified') )`
- **BloqueiaSelecaoManualLeadGanho** (ativa): Atenção: apenas é possível converter o lead através do botão "Converter".
  - `AND( ISCHANGED(Status), OR( AND( ISPICKVAL(Status, 'Qualified'), NOT(IsConverted) ), AND( ISPICKVAL(PRIORVALUE(Status), 'Qualified'), IsConverted ) ) )`
- **BloqueiaSelecaoManualLeadPerdido** (ativa): Atenção: apenas é possível perder o lead através do botão "Perder Lead'.
  - `AND( ISCHANGED(Status), ISPICKVAL(Status, 'Unqualified'), ISBLANK(TEXT(LossType__c)) )`
- **DocumentValidation** (inativa): O campo "Número do Documento" deve estar no formato: -CPF: 999.999.999-99 ou sem os caracteres especiais; -CNPJ: 99.999.999/9999-99 ou sem os caracteres especiais.
  - `NOT( OR( /* CPF com máscara OU sem máscara */ REGEX(DocumentNumber__c, "^[0-9]{3}\\.[0-9]{3}\\.[0-9]{3}-[0-9]{2}$"), REGEX(DocumentNumber__c, "^[0-9]{11}$"), /* CNPJ com máscara OU sem máscara */ REGEX(DocumentNumber__c, "^[0-9]{2}\\.[0-9]{3}\\.[0-9]{3}/[0-9]{4}-[0-9]{2}$"), REGEX(DocumentNumber__c, "^[0-9]{14}$") ) )`
- **ManuallyLeadCreationStatus** (inativa): O lead deve ser criado com o status “Novo”
  - `ISNEW() && NOT(ISPICKVAL(Status, "Novo"))`
- **PhoneValidationFormat** (inativa): O número de telefone deve estar no formato DDD + Número, com 10 ou 11 dígitos. Ex: 11987654321 (celular) ou 1134567890 (fixo).
  - `NOT( REGEX(Phone, "^[0-9]{10,11}$" ) )`
- **VRAddressFields** (inativa): Para continuar, complete todos os campos do endereço ou deixe-os vazios.
  - `AND( NOT( AND( ISBLANK(Street), ISBLANK(City), ISBLANK(PostalCode), ISBLANK(Neighborhood__c), ISBLANK(AddressNumber__c), AND(ISBLANK(Country), ISPICKVAL(CountryCode, '')), AND(ISBLANK(State), ISPICKVAL(StateCode, '')) ) ), OR( ISBLANK(Street), ISBLANK(City), ISBLANK(PostalCode), ISBLANK(Neighborhood__c), ISBLANK(AddressNumber__c), AND(ISBLANK(Country), ISPICKVAL(CountryCode, '')), AND(ISBLANK(State), ISPICKVAL(StateCode, '')) ) )`
- **VRCellphoneMask** (ativa): Atenção, o Celular informado é incorreto. Informar um valor válido e formato correto. Ex: Nacional: 11987654321 Internacional: +5511987654321 ou +14155552671
  - `AND( RecordType__c = "LegalEntity_B2B", NOT(ISBLANK(MobilePhone)), NOT( OR( REGEX(MobilePhone, "^[1-9]{2}9[0-9]{8}$"), REGEX(MobilePhone, "^\\+[1-9][0-9]{7,14}$") ) ) )`
- **VRPhoneMask** (ativa): Atenção, o Telefone informado é incorreto. Informar um valor válido e formato correto. Ex: 1144223366 ou 08001239999
  - `AND( RecordType__c = "LegalEntity_B2B", NOT(ISBLANK(Phone)), NOT(REGEX(Phone, "^[1-9]{2}[0-9]{8}$")), NOT(REGEX(Phone, "^0800[0-9]{7}$")) )`
- **ValidaCPFeCNPJ** (inativa): Atenção, o CNPJ/CPF informado é incorreto. Informar um valor válido e formato correto. Ex: CPF: XXX.XXX.XXX-XX CNPJ: XX.XXX.XXX/XXXX-XX
  - `AND( RecordType__c = "LegalEntity_B2B", /*Valida o formato correto do CPF*/ OR(NOT(AND( LEN(DocumentNumber__c) = 14, MID(DocumentNumber__c, 4, 1) = ".", MID(DocumentNumber__c, 8, 1) = ".", MID(DocumentNumber__c, 12, 1) = "-")) ,/*Valida os digitos verificadores do CPF*/ NOT(OR( LEN(DocumentNumber__c)=0,AND(MOD(MOD(11-MOD( VALUE(MID(DocumentNumber__c,1,1))*10+ VALUE(MID(DocumentNumber__c,2,1))*9+ VALUE(MID(DocumentNumber__c,3,1))*8+ VALUE(MID(DocumentNumber__c,5,1))*7+ VALUE(MID(DocumentNumber__c,6,1))*6+ VALUE(MID(DocumentNumber__c,7,1))*5+ VALUE(MID(DocumentNumber__c,9,1))*4+ VALUE(MID(DocumentNumber__c,10,1))*3+ VALUE(MID(DocumentNumber__c,11,1))*2,11),11),10)= VALUE(MID(DocumentNumber__c,13,1)),MOD(MOD(11-MOD( VALUE(MID(DocumentNumber__c,1,1))*11+ VALUE(MID(DocumentNumber__c,2,1))*10+ VALUE(MID(DocumentNumber__c,3,1))*9+ VALUE(MID(DocumentNumber__c,5,1))*8+ VALUE(MID(DocumentNumber__c,6,1))*7+ VALUE(MID(DocumentNumber__c,7,1))*6+ VALUE(MID(DocumentNumber__c,9,1))*5+ VALUE(MID(DocumentNumber__c,10,1))*4+ VALUE(MID(DocumentNumber__c,11,1))*3+ VALUE(MID(DocumentNumber__c,13,1))*2,11),11),10)= VALUE(MID(DocumentNumber__c,14,1)))))) , /*Valida o formato correto do CNPJ*/ OR(NOT(AND( LEN(DocumentNumber__c) = 18, MID(DocumentNumber__c, 3, 1) = ".", MID(DocumentNumber__c, 7, 1) = ".", MID(DocumentNumber__c, 11, 1) = "/", MID(DocumentNumber__c, 16, 1) = "-")) ,/*Valida os digitos verificadores do CNPJ*/ IF(LEN(DocumentNumber__c)=18,OR(AND(MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2)) ,11)<=1 ,VALUE(MID(DocumentNumber__c,18,1))!=0) ,AND(MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2)) ,11)>1 ,(11-MOD(( (VALUE(MID(DocumentNumber__c,1,1))*6)+ (VALUE(MID(DocumentNumber__c,2,1))*5)+ (VALUE(MID(DocumentNumber__c,4,1))*4)+ (VALUE(MID(DocumentNumber__c,5,1))*3)+ (VALUE(MID(DocumentNumber__c,6,1))*2)+ (VALUE(MID(DocumentNumber__c,8,1))*9)+ (VALUE(MID(DocumentNumber__c,9,1))*8)+ (VALUE(MID(DocumentNumber__c,10,1))*7)+ (VALUE(MID(DocumentNumber__c,12,1))*6)+ (VALUE(MID(DocumentNumber__c,13,1))*5)+ (VALUE(MID(DocumentNumber__c,14,1))*4)+ (VALUE(MID(DocumentNumber__c,15,1))*3)+ (VALUE(MID(DocumentNumber__c,17,1))*2) ),11 ))!=VALUE(MID(DocumentNumber__c,18,1)))),false)), NOT($Profile.Name = 'System Administrator'), NOT(ISBLANK(DocumentNumber__c)) )`
- **ValidaCamposObrigatorios** (ativa): Atenção: é necessário preencher todos os campos da seção 'Informações de endereço' antes de converter um lead
  - `AND( OR( ISBLANK(Street), ISBLANK(City), ISBLANK(State), ISBLANK(PostalCode), ISBLANK(Country) ), ISCHANGED(IsConverted), IsConverted )`
- **ValidaPreenchimentoCluster** (ativa): Atenção: seu usuário não está definido a um cluster. Necessário preenchimento do campo para seguir.
  - `AND( RecordType__c = "LegalEntity_B2B", ISPICKVAL($User.Cluster__c, ""), OR( ISPICKVAL(ClusterManual__c, ""), ISBLANK(TEXT(ClusterManual__c)) ) )`

## Flows ligados a Account, Opportunity e Lead

De 233 flows na org (FlowDefinitionView), 171 sem objeto de disparo (autolaunched, tela, orquestracao). Filtro: objeto de
disparo Conta/Oportunidade/Lead ou nome com Account/Opportunity/Lead. Coluna Retrieve = veio para o repositorio.

| Flow | Tipo | Disparo | Objeto | Ativo | Retrieve |
|---|---|---|---|---|---|
| CancelLeads | Flow | - | - | sim | sim |
| CancelOpportunity_B2B | Flow | - | - | sim | sim |
| CreateLeadAndOpp | FieldServiceMobile | - | - | sim | nao |
| CreateSalesLead | AutoLaunchedFlow | - | - | sim | nao |
| DcCreateLeadAndOpp | DataCaptureFlow | - | - | nao | nao |
| LeadGetAddress | Flow | - | - | sim | sim |
| LeadProductInterestScreen | Flow | - | - | sim | sim |
| LeadRequiredFields | Flow | - | - | sim | sim |
| OpportunityClientAnalysisRequiredFields | Flow | - | - | sim | sim |
| OpportunityGuidedFlow_B2B | Flow | - | - | sim | sim |
| OpportunityNewQuote_B2B | Flow | - | - | sim | sim |
| OpportunitySelectAddress_B2B | Flow | - | - | sim | sim |
| OpportunitySendCLevelApproval_B2B | Flow | - | - | sim | sim |
| OpportunityStageApprovalProcess_B2B | AutoLaunchedFlow | - | - | sim | sim |
| OpportunityTermApproval | ApprovalWorkflow | - | - | nao | sim |
| OpportunityValidateCommercialApproval_B2B | Flow | - | - | sim | sim |
| OpportunityValidateCreditApproval_B2B | Flow | - | - | sim | sim |
| Account_Update_Service_Territory | AutoLaunchedFlow | RecordAfterSave | Conta | sim | sim |
| InsertAccountIDInQuote | AutoLaunchedFlow | RecordBeforeSave | Cotação | sim | nao |
| ApprovalDispatcher | AutoLaunchedFlow | RecordAfterSave | Lead | nao | nao |
| ModifyLostLead | AutoLaunchedFlow | RecordAfterSave | Lead | sim | sim |
| ReferralNotification | AutoLaunchedFlow | RecordAfterSave | Lead | nao | nao |
| OpportunityApprovalSteps_B2B | ApprovalWorkflow | RecordAfterSave | Oportunidade | sim | sim |
| OpportunityUpdatePricebookB2B | AutoLaunchedFlow | RecordAfterSave | Oportunidade | sim | sim |

Nao vieram no retrieve (aparecem na FlowDefinitionView, mas nao como metadado Flow acessivel; provavelmente pacote gerenciado
ou fluxo do app movel): CreateLeadAndOpp, CreateSalesLead, DcCreateLeadAndOpp, InsertAccountIDInQuote, ApprovalDispatcher, ReferralNotification.

O que interessa para os chamados: OpportunityApprovalSteps_B2B (orquestracao de aprovacao; a etapa "Aprovacao - Comercial"
e designada ao ManagerAccount__c e e o item que o script 37 reatribui), OpportunityStageApprovalProcess_B2B e
OpportunitySendCLevelApproval_B2B (disparo das aprovacoes), OpportunityUpdatePricebookB2B (record-triggered, troca o catalogo
de precos), Account_Update_Service_Territory (record-triggered em Conta), ModifyLostLead e CancelLeads (perda de lead),
LeadRequiredFields e LeadGetAddress (telas do lead B2B).
