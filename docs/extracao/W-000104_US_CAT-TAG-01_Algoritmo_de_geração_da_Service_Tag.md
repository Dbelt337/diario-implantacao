# W-000104 — US CAT-TAG-01 — Algoritmo de geração da Service Tag

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 04/09/2026 15:07 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:07 por Diego Beltrão de Moraes

US tecnica (decisoes das atas 02-03/09: etiqueta gerada no PEDIDO, ~16 caracteres, carimbo de data/hora, checagem de duplicidade; algoritmo estruturado pelo Bismarck com especificacao da arquitetura).

NARRATIVA
Como Operacao e Sistemas Downstream, quero que cada servico e equipamento receba uma etiqueta unica (Service Tag) gerada na aceitacao do pedido, para identificar cliente + oferta + endereco de instalacao em todo o ecossistema (Salesforce, Customer Core, SAP, campo).

PRINCIPIO CENTRAL: a unicidade NAO e garantida pelo algoritmo, e garantida pelo BANCO. Consulta previa antes de inserir tem condicao de corrida (duas transacoes simultaneas passam na checagem e gravam a mesma tag). O desenho correto usa restricao de unicidade no campo e retry na colisao.

ESPECIFICACAO
1. Campo ServiceTag__c no Asset (espelhado na linha do pedido): Text(16), External ID, UNIQUE (case-insensitive). O flag Unique cria a restricao no banco - e ela que garante a unicidade.
2. Formato (16 posicoes): [PREFIXO 2][TIMESTAMP 9][ALEATORIO 5] em Base32 Crockford (alfabeto sem I, L, O, U - legivel por telefone, sem ambiguidade). Prefixos por dominio: SV = servico, EQ = equipamento (CPE). Timestamp em milissegundos codificado da ordenacao temporal (o "carimbo de data/hora" da reuniao); sufixo aleatorio elimina colisao no mesmo milissegundo.
3. Geracao: na ACEITACAO DO PEDIDO (decisao de reuniao: no pedido, nao na cotacao) - trigger/Auto Task do plano de orquestracao. Apex: gerar tag, insert/update; em DUPLICATE_VALUE, regenerar o sufixo e repetir (maximo 3 tentativas). Aleatoriedade via Crypto.getRandomInteger(). Alternativa se o formato de 16 posicoes for flexibilizado: classe nativa UUID.randomUUID() (36 chars, validar disponibilidade na versao da org).
4. FRONTEIRA COM O ASSET REFERENCE ID (nao confundir): vlocity_cmt__AssetReferenceId__c e o GUID DO PACOTE, gerado no carrinho, usado para rastreio pai-filho e MACD (decisao de reuniao: mantem esse papel). NAO deve ser tocado nem substituido. A Service Tag e a identidade de NEGOCIO. Dois identificadores, dois papeis.
5. Regras: tag imutavel apos ativacao (validation rule); CPE recebe tag propria (prefixo EQ) vinculada ao serial no inventario; a tag viaja no payload de integracao (Customer Core/SAP) como referencia cruzada; formato validado por expressao regular no salvamento.

CRITERIOS DE ACEITE
1. Dado dois pedidos processados simultaneamente, quando as tags forem geradas, entao jamais ha duplicidade (teste com insercao paralela) e a colisao forcada e resolvida por retry sem erro ao usuario.
2. Dado um pedido aceito, quando a orquestracao executa, entao a tag existe na linha do pedido e no Asset ativado, no formato especificado.
3. Dado um Asset ativado, quando alguem tentar alterar a tag, entao a edicao e bloqueada.
4. Dado um combo com equipamento, quando ativado, entao servico e CPE possuem tags proprias (SV/EQ) e o AssetReferenceId do pacote permanece intocado e distinto.
