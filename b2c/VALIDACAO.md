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
