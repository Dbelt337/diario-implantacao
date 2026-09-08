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
4. **"Responsável: Davi Israel de Abreu" nos 66 docs.** Verificar se é o Assignee real de todas as
   works ou valor fixo do gerador (as 16 works novas do script 02 foram criadas sem assignee).

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
