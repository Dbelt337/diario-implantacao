# Historias Refinadas B2C — validacao de cobertura (2026-08-20)

Relatorio completo: https://claude.ai/code/artifact/bc0d4dab-ab0a-4066-8ba6-316ff8c88d8b

Veredito: as 13 historias sao cobriveis. 8 com o que a plataforma ja oferece,
5 dependendo de integracao externa ou licenca. Nenhuma exige capacidade que o
Salesforce nao tenha. O org ja possui as tres bases caras: Communications
Cloud (Vlocity), Field Service e OmniStudio.

Riscos do programa (fora do Salesforce):
- 10 integracoes externas assumidas prontas (CEP, GIS/Ozimap, reserva de
  porta, Serasa, Customer Core x2, Zendesk, baixa BSS/SAP, biometria/assinatura,
  WhatsApp). So duas tem dono nomeado no documento.
- 2 licencas a confirmar: Marketing Cloud Engagement + WhatsApp (H10) e
  Omni-Channel nos perfis de venda (H1).

Achados editoriais no documento (corrigir antes de estimar):
- H4 e H8 sao a MESMA historia (flag de endereco inadimplente) — consolidar.
- H6b (Governanca/Unidade Operacional) esta colada no fim da H7 sem titulo.
- Numeros caidos na formatacao: "resposta da API em __ segundos" (H13),
  "ao termino do __ dia" (H10), "ha __ dias" (H11).
- Pendencia herdada da politica de credito: score exatamente no corte
  (350/380) segue indefinido.

Conexoes com trabalho anterior desta semana:
- Campo IBGE no endereco (H13) = conversa de modelagem de endereco; ViaCEP
  resolve CEP + IBGE numa unica integracao (H1 + H13).
- Regra parametrizada por canal (H3) = recomendacao da Politica de Credito
  Amigo (Decision Matrix / Custom Metadata).
- Trava de botao pos-assinatura (H9) = mecanica identica ao Revisao
  Diretoria (W0382).

Aviso de roadmap: a partir do Winter '27 o acesso TMF via gateway MuleSoft
sera descontinuado em favor de acesso direto (Connect/Apex REST). Desenhar
integracoes novas ja no modelo direto. Para viabilidade (H2/H13), usar
TMF679 (Product Offering Qualification), certificado no Communications Cloud.

## Roadmap Vlocity/Premises — confirmado na letra fria (2026-08-20)

Fontes coladas pelo Diego: release notes Winter '27 (264, preview) de
Omnistudio; highlights Summer '26 (262); artigo Slalom sobre Spring '26;
blog oficial de roadmap de deployments (fev/2026); guia de migracao OMA.

1. NOME ATUALIZADO DE NOVO: Summer '26 renomeou "Communications Cloud" para
   **Agentforce Communications**. Cadeia completa: Vlocity (2020) ->
   Salesforce Industries -> Communications Cloud -> Agentforce Communications.
   O stack on-core chama "Revenue Cloud for Communications on Salesforce
   Platform". Namespace vlocity_cmt permanece como heranca tecnica.
2. Managed package SEGUE recebendo feature (Summer '26: Mixed Mode Cart APIs,
   Cart Templates, Deep Clone, e **Availability & Eligibility Interfaces no
   Get List of Products API** — que e exatamente o filtro em duas etapas da
   H13: availability geografica + eligibility de regras de negocio).
3. Omnistudio Hybrid (Summer '26) suporta OFICIALMENTE coexistencia dos dois
   runtimes no mesmo org, com Migration Assistant via CLI. "Novo no standard
   runtime, legado no package, migracao faseada" deixou de ser conselho e
   virou o caminho suportado.
4. Sinal amarelo: Industries Order Management ficou SEM release notes no
   Summer '26; a Salesforce posiciona o DRO como substituto e como "primeiro
   passo pratico" de migracao para core (Slalom/Spring '26). Verificar se a
   BTP usa o OM do pacote — se sim, planejar DRO antes que vire urgencia.
5. Blog oficial (fev/2026): investimento de deployment concentrado no caminho
   metadata/standard runtime (atomic deploy, dependency mgmt, 2GP).
6. Winter '27 e PREVIEW — o proprio disclaimer manda decidir compra apenas
   por funcionalidade GA. Vale como norte, nao como compromisso.

Veredito mantido e reforcado: Premises/ServicePoint sem deprecacao; construir
o B2C no pacote e consistente com o org; artefatos novos de OmniStudio ja no
standard runtime; integracoes TMF em acesso direto; pedir ao AE a matriz
core x package por escrito.

## Registro de interfaces do CPQ em producao (2026-08-20)

Fonte: InterfaceImplementation__c + InterfaceImplementationDetail__c, producao.

1. PremisesInterface -> DefaultPremisesImplementation ATIVO. Hook existe e
   nunca foi customizado. Adocao limpa do lado do motor.
2. DESCOBERTA PRINCIPAL: o filtro de prateleira por contexto esta DESLIGADO.
   ProductAvailabilityInterface e ProductEligibilityInterface rodam nas
   implementacoes Default (que nao filtram nada); as alternativas
   (FilterAvailability/FilterEligibility/CtxRulesProductsOpen/
   AccountTypeProductEligibility) estao TODAS inativas. Context rules estao
   ativas so para PRECO (CtxRulesPriceLists/PriceElements ativos). Ou seja:
   hoje o org nao filtra catalogo por elegibilidade de contexto — a H13 nao e
   ajuste, e ligar+implementar esse filtro.
3. ValidateAddressInterface -> ValidateAddressImplementation ATIVO (o Default
   esta inativo). RESOLVIDO: NamespacePrefix = vlocity_cmt — e classe DO
   PACOTE, nao ha codigo custom de endereco. Alguem apenas trocou a
   implementacao ativa por configuracao. Consequencia: o ponto de extensao ja
   foi mexido uma vez e funciona; plugar CEP/ViaCEP/IBGE = criar UMA classe
   custom implementando essa interface e registra-la como ativa — padrao
   suportado, baixo risco.
4. OM DO PACOTE (XOM) EM USO: OdinAPIHandler -> XOMOMStandardOdinAPIHandler
   ativo, XOMSupplementalOrderLifecycleImpl ativo, SendSubmitToOM/Freeze/
   Unfreeze ativos. Confirma o sinal amarelo: o OM do pacote ficou sem
   release notes no Summer '26 e a Salesforce posiciona DRO como substituto.
   DRO ja aparece no registro (DROQualifier, DroReplacementHandler) = pacote
   recente. Planejar avaliacao DRO no programa.
5. Sabor telco do pacote confirmado: TelcoCloneAdditionalObjects e
   TelcoUpdateFrameContract ativos.

Pendente ainda: COUNT de Premises__c e ServicePoint__c; versao do pacote
(Setup > Pacotes instalados); NamespacePrefix da ValidateAddressImplementation;
COUNT de OrchestrationPlan__c (confirmacao de volume no XOM).

## Contagens: Premises 0, ServicePoint 0, OrchestrationPlan 0 (2026-08-20)

- Premises__c = 0 e ServicePoint__c = 0: adocao limpa total. Nao ha dado
  legado, nao ha migracao, o modelo pode ser desenhado do zero.
- OrchestrationPlan__c = 0: CORRIGE minha leitura anterior. Os handlers XOM
  ativos no registro de interfaces indicavam OM do pacote "em uso" — mas zero
  planos de orquestracao significa que a decomposicao do OM nunca rodou (ou
  nunca persistiu). Leitura provavel: OM configurado na implantacao, porem o
  fulfillment real acontece FORA do Salesforce (ERP/Customer Core via
  MuleSoft), como as proprias historias B2C assumem. Confirmacao final:
  SELECT COUNT() FROM vlocity_cmt__FulfilmentRequest__c — se tambem for 0,
  o XOM esta oficialmente sem uso e a avaliacao de DRO cai de "item do
  programa" para "monitorar roadmap".

Pendente: versao do pacote (Setup > Pacotes instalados) — decide se as
interfaces de Availability & Eligibility do Summer '26 estao disponiveis.
