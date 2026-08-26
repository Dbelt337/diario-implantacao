# Diretrizes permanentes do Diego (valem em toda sessão)

1. **Native-first, sempre.** Recursos padrão do Salesforce e dos pacotes instalados (Vlocity CMT/Communications Cloud, Flow Approvals, Permission Sets/Groups, User Access Policies, OmniStudio) antes de qualquer coisa custom. **Sem objeto custom quando o modelo do produto já cobre o conceito** — o modelo CMT é aderente ao SID/TM Forum; a resposta certa começa por ele.
2. **Resposta fundamentada.** Toda recomendação de arquitetura vem com base em documentação oficial (help.salesforce.com, TM Forum) e exemplos de mercado Telco, com fontes citadas.
3. **Registrar tudo no diário.** Decisões, defeitos encontrados, causas raiz e checklists de produção vão para `docs/` e são commitados ("Vai anotando pq vamos precisar ajustar tudo em prod").
4. **Metadado > print.** Conclusão sobre comportamento da org sai de retrieve/queries (SOQL, Tooling, EntityDefinition), não de tela da UI.
5. **Entregas como pacote.** Correções viram zip de deploy (Workbench → Single Package + Rollback On Error), commitados em `deploy/`, enviados para o Diego fazer o deploy.
6. **Testes de aprovação/orquestração sempre em registro novo** (runs ficam presos na versão em que nasceram) e com usuários **ativos** nos lookups (staging tem duplicados inativos).
7. **Ambientes:** prod `prod-brasiltecpar`, sandbox `preprod-brasiltecpar--staging`, org Blink separada (`blinktelecom`). Retrieve comparativo antes de promover qualquer coisa.
8. **Idioma:** respostas e documentos em português.
9. **Estilo:** nunca usar emojis nem travessões/separadores decorativos (como traço longo ou ponto central) em respostas, tabelas e documentos. Texto limpo, sem vestígios de IA. Hífen só quando faz parte da grafia (Wi-Fi, B2B).
