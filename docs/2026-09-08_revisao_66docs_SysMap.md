# Revisão do pacote "Works_Requisitos_SysMap_0809_66docs.zip" (08/09/2026)

Lidos os 66 .docx na íntegra (W-000051 a W-000117). Geração: 08/09/2026 19:30 UTC (16:30 BRT),
autor "Brasil TecPar", cabeçalho "Requisitos", rodapé "Brasil TecPar — Confidencial" com PAGE/NUMPAGES
reais, título do arquivo = "W-nnnnnn - Subject". Estrutura por doc: capa, tabela (Work, Épico, Time,
Status, Responsável, Data), Descrição (Como/Quero/Para que), seções do Details, Critérios de Aceite
(inclui a related list Acceptance Criteria), Notas de Refinamento.

## Veredito: não está tudo certo. 4 problemas de geração, 3 de conteúdo na org, 1 de conferência.

### A. Problemas do pacote (corrigir no gerador e regerar)
1. **Falta a W-000070** (EPC-10 — Criação dos catálogos comerciais por família e estrutura B2B/B2C).
   O intervalo 51..117 tem 67 works; o zip tem 66. Causa provável: filtro por Subject começando com
   "US " (a EPC-10 é a única sem esse prefixo). Confirmar se a exclusão foi intencional.
2. **Docs gerados ANTES dos scripts 09 e 11.** W-000117 (CAT-ACC-01) e W-000103 (CAT-MIG-01) estão
   sem as notas "CENARIO REAL DA ORG DE PRODUCAO (08/09)", "CONTAS ANTES DOS ATIVOS (08/09)",
   "CORRECAO APOS AUDITORIA DAS CONTAS BILLING (08/09)" e "CORRECAO DO PASSO 2 DA CARGA (08/09)".
   A tabela diz "conteúdo integral ... incluindo notas de refinamento", o que não é verdade para
   essas duas. Efeito: a SysMap receberia a CAT-ACC-01 com RN-01 (ParentId), RN-09 (Person Account
   obrigatório) e o item (b) já sabidamente errados. As 4 notas do script 08 (W-000065, 082, 089,
   105) estão presentes, logo o pacote foi gerado entre o script 08 e o 09.
3. **Critérios de Aceite dentro da seção de notas** em W-000083, W-000087, W-000088, W-000089 e
   W-000090: o gerador abre "Notas de Refinamento e Decisões Registradas" na primeira nota que
   encontra (ALINHAMENTO COM B2B / COMPLEMENTO DE ARQUITETURA) e os Critérios ficam depois, no meio
   das notas. Ordem esperada: Critérios antes das notas.
4. ~~"Responsável" fixo~~ **Confirmado pela extração (script 13): Davi é o Assignee real das 67 works.**
   Sem erro aqui. Em compensação, o **nome do épico B2B está errado nos docs**: os 7 docs B2B
   (W-000096 a 101 e W-000107) mostram "B2B - Jornadas de Venda e Gestão de Contratos", e na org o
   épico se chama "B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente". O gerador tem o
   nome antigo fixo em código ou o épico foi renomeado depois.

### B. Problemas no conteúdo da org (script 12 corrige)
5. Fragmentos de markdown do documento de origem colados no Details:
   - W-000073: "## 2. Risco & Viabilidade" no fim da Estimativa;
   - W-000075: "## 4. Pagamento, Delivery & Field Service" no fim da Massa de Teste;
   - W-000083: "## 1. Entrada & Qualificação de Lead" no fim de Automação.
6. W-000099 e W-000100: "Validação E2E ... Massa de Teste Sugerida" na mesma linha (quebra perdida).
7. W-000068: título "R$ 149,99" x corpo "R$ 149,90". Já apontado na W-000085 como pendência de
   negócio; o título deve ser ajustado quando o valor for confirmado.

### C. Conferência de conteúdo (sem erro de geração, mas para a pauta com a SysMap)
- Marcas abertas: [CONFIRMAR] em W-000057 (Person Account), W-000064 (SSO/SCIM), W-000066 (licença
  Marketing Cloud + WhatsApp); [DEFINIR] em W-000059 (corte 350/380), W-000067 (SLA 5 dias x boleto
  48h), W-000069 (mecanismo de filtro conforme versão do pacote CMT).
- Person Account aparece como premissa em W-000093, 094, 095 (Objetos Impactados e massa de teste)
  e W-000057. A auditoria de 08/09 mostrou que não está habilitado; a decisão (opção ii) está só na
  nota da W-000117, que não entrou no pacote. Levar como ponto explícito.
- W-000085 pede confirmação do valor da taxa (149,90 x 149,99).
- Coerência interna OK: decisões 01/09 (endereço, decomposição única), 03/09 (zona de preço, prazo
  no carrinho, família, móvel sem aparelho), 04/09 (contrato na cotação, diretriz TMF x proprietário,
  campos fiscais) e 08/09 (script 08) aparecem consistentes entre as works que se referenciam
  (056↔069, 082↔089↔105↔065, 085↔108↔114, 088↔093↔101, 094↔097↔060, 104↔093↔100↔116).
- Referências cruzadas por número (W-000056, 081, 084, 085, 087, 088, 093, 094, 097, 098, 099,
  100, 103, 104, 105) conferem com os subjects do panorama.

## Ações
1. Rodar o script 12 (limpa os 3 fragmentos "## n.").
2. Corrigir o gerador: incluir W-000070 (filtro por Name no intervalo, não por prefixo "US"),
   Critérios sempre antes das notas, Responsável = Assignee real (ou remover a linha).
3. Regerar o pacote completo (67 docs) depois do script 12, agora com as notas dos scripts 09 e 11.
4. Rodar o 04 v8 compacto depois do 12 (esperado continua 81 OK; o 12 não mexe em marcador).

## Execução
- Script 12 rodado em produção (08/09): W-000073 (-25 chars), W-000075 (-41), W-000083 (-36),
  `works limpas: 3, puladas: 0`. Os três fragmentos "## n." saíram do Details. Item B.5 resolvido.

## Extração completa (script 13, 08/09 18:04) — docs/extracao/
- 67 works (W-000051..117), todas User Story, Status New, Product Tag "Salesforce", Assignee Davi.
  Scrum Team: 54 SysMap, 13 Salesforce. Épicos: 45 B2C, 15 Catálogo, 7 B2B. Priority, Story Points
  e Sprint vazios em todas. Product Owner: Priscila De Lima (54), Thiago Campos Almeida (5, EPC-01..05),
  **sem PO em 8**: W-000102, 103, 104, 108, 111, 112, 113, 114 (todas de catálogo, time Salesforce).
- Acceptance Criteria: 51 works com registros (1 a 6 cada); **16 sem nenhum** (W-000102..117), com os
  critérios no corpo. Script 14 em DRY_RUN: 16 works, 64 critérios, títulos corretos
  ("Critério n" nos formatos numerados, "Cenário n: Título" nos demais).
- 49 comentários, todos automáticos do Agile Accelerator (troca de assignee, épico e subject); nenhum
  conteúdo de refinamento fora do Details. 0 tasks. Campo Description vazio em todas.
- W-000070 (EPC-10, time SysMap, 3 AC, sem notas) **conflita com decisões posteriores**: define
  catálogos POR FAMÍLIA (CAT_INTERNET, CAT_SEGURANCA, CAT_WIFI, CAT_VOZ, CAT_STREAMING, CAT_SVA,
  CAT_TV) enquanto a QUAL-01 (W-000056) define catálogos POR MERCADO com família como categoria de
  navegação e "proibido catálogo por família"; cita marcas (Playhub, Aya, Ubiquiti, Huawei, Ruckus)
  contra a decisão de nomes genéricos; reserva CAT_TV contra o "sem TV" de 03/09; lista de famílias
  (Internet, Segurança, Wi-Fi, Voz, Streaming, Serviços Digitais) diferente da de 03/09 (Internet,
  Stream, Câmera, Móvel). Precisa de nota de refinamento ou de decisão explícita.
- Tamanho de Details divergente em 1 a 3 chars em 6 works (065, 080, 081, 090, 094, 102): quebras
  CRLF normalizadas pelo log. Sem impacto.
- **W-000070, AC "3" com 6.569 chars**: além do critério 3, guarda o texto "Decisões do cliente —
  fechamento das pendências P-01 a P-19" (18 decisões da Onda 0, registro de 26/08), invisível no
  Details e ausente dos docs. Numeração conflita com QUAL-01/B2C-13/CAT-ZON-01 (P-17 e P-19) e o
  texto diz "não há itens abertos" enquanto 3 works tratam P-19 como pendente. Script 15 move o
  texto para nota e registra as pendências de alinhamento (estrutura por família x mercado, lista de
  famílias, marcas x nomes genéricos, numeração), sem decidir.
- Script 14 (DRY_RUN=false): 64 Acceptance Criteria inseridos, 16 works atualizadas (corpo com
  ponteiro). Script 15: AC 3 da W-000070 reduzida a 335 chars, 6.231 chars de decisões movidos para
  nota + nota de pendências (Details 2.369 -> 10.542, 2 notas). 04 v8 compacto depois de tudo:
  `81 OK, 0 FALTANDO, 0 DUPLICADOS`. Itens B.5, "critérios no corpo" e "AC 3" resolvidos.
  A extração em docs/extracao/ é ANTERIOR aos scripts 14 e 15; regerar com o 13 antes de produzir docs.
