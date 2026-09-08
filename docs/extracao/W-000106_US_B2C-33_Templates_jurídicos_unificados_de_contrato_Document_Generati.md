# W-000106 — US B2C-33 — Templates jurídicos unificados de contrato (Document Generation)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:17 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:17 por Diego Beltrão de Moraes

US B2C (agenda presencial 02/09: ação "Alinhar Templates Jurídicos" e tema "Motor de assinatura eletrônica"; dependência declarada na B2C-25).

NARRATIVA
Como Jurídico e Gestão de Produtos, quero um conjunto único de templates de contrato por segmento e família, aprovado e versionado, usado pelo Document Generation na cotação, para que todo contrato gerado seja juridicamente válido, regulatoriamente adequado e igual em todos os canais e marcas do grupo.

CONTEXTO E CENÁRIO DE NEGÓCIO
A B2C-25 (W-000082) gera a minuta na cotação e a TEC-B2C-06 (W-000089) provê a infraestrutura de Document Generation, mas os templates hoje variam por marca e por canal. Com o rebranding para Grupo Evo e a decisão de nomes genéricos, o jurídico precisa unificar os modelos, e o time precisa saber quais variáveis o template consome para que a cotação as tenha preenchidas.

REGRAS DE NEGÓCIO
RN-01 Um template por combinação segmento × família × tipo de operação (venda nova, mudança de plano, cortesia); nada por marca ou canal.
RN-02 Versionamento: todo template tem versão e vigência; a cotação grava a versão usada; alteração de template não altera contratos já gerados.
RN-03 Variáveis obrigatórias: dados do cliente, endereço de instalação, itens e preços, prazo e fidelidade, campos fiscais quando aplicável, canal de assinatura e Service Tag quando já existir.
RN-04 Cláusulas regulatórias: Anatel (SCM e SVA) e CDC são blocos fixos aprovados pelo jurídico; não são editáveis pela gestão de produtos.
RN-05 Idioma e marca: texto em português com a marca do grupo; nomes de produto genéricos; nenhuma menção a marca antiga.
RN-06 Sem edição manual: o vendedor não edita o texto; ajustes comerciais entram por variáveis (desconto, prazo), nunca por texto livre.
RN-07 Aprovação: novo template ou nova versão só entra em produção com aprovação do jurídico registrada.

ESPECIFICAÇÃO TÉCNICA
Document Templates do OmniStudio Document Generation por combinação; DataRaptor Extract único com todas as variáveis da cotação (Quote, QuoteLineItem, Account, Premises, campos fiscais da linha); catálogo de variáveis publicado para a B2C-25; controle de versão e vigência em objeto próprio; geração assíncrona pelo canal de eventos (US TEC-INT-01); PDF bloqueado anexado à Quote.

DEPENDÊNCIAS E RISCOS
Dependências: reunião com o jurídico (ação de 02/09); B2C-25 e TEC-B2C-06; plataforma de assinatura (pendência); rebranding aprovado.
Riscos: prazo do jurídico; variáveis exigidas pelo template ainda não capturadas na jornada; contratos estaduais com exigências específicas.

CRITÉRIOS DE ACEITE
Cenário 1: Geração pela combinação. Dado uma cotação B2C de internet residencial, venda nova, quando a minuta for gerada, então o template usado é o da combinação correta, na versão vigente, e a versão fica gravada na cotação.
Cenário 2: Variável ausente. Dado uma cotação sem endereço de instalação validado, quando a geração for solicitada, então o sistema bloqueia e informa a variável faltante.
Cenário 3: Nova versão. Dado uma nova versão de template aprovada, quando entrar em vigência, então cotações novas a usam e contratos anteriores permanecem inalterados.
Cenário 4: Nome genérico. Dado o contrato gerado, quando lido, então não há nome de marca antiga e os produtos aparecem com nome genérico.
