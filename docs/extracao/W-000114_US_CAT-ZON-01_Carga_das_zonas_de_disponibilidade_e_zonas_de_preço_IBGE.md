# W-000114 — US CAT-ZON-01 — Carga das zonas de disponibilidade e zonas de preço (IBGE → zona)

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 15:52 por Diego Beltrão de Moraes | Alterado: 08/09/2026 15:52 por Diego Beltrão de Moraes

US de catálogo (agenda presencial 03/09: ações "Criar Zonas Disponibilidade" e "Entregar Templates"; decisão de separar zona de disponibilidade de zona de preço).

NARRATIVA
Como Gestão de Produtos, quero que todas as cidades atendidas (código IBGE) estejam associadas a uma zona de disponibilidade e a uma zona de preço (A, B ou C), carregadas no Salesforce a partir do template da liderança, para que a QUAL-01 habilite as ofertas certas por cidade e a matriz de preço aplique a tabela certa sem cadastro cidade a cidade.

CONTEXTO E CENÁRIO DE NEGÓCIO
A QUAL-01 (W-000056) define o mecanismo de resolução cidade → zona via GeographicCommercialPolicy, mas não existe US para montar e carregar o conteúdo: cerca de 40 a 50 regiões, em nível único, e as três tabelas de preço por concorrência. Sem essa carga nenhuma oferta aparece no funil e nenhum preço regional é aplicado. A decisão de 03/09 separa os dois conceitos: a zona de disponibilidade habilita ou oculta ofertas; a zona de preço escolhe a Price List Entry.

REGRAS DE NEGÓCIO
RN-01 Duas dimensões independentes: cada cidade tem exatamente uma zona de disponibilidade e exatamente uma zona de preço; as duas podem coincidir, mas são registros distintos.
RN-02 Chave é o código IBGE: o município é identificado pelo código IBGE de 7 dígitos, nunca pelo nome; cidades sem código não são carregadas.
RN-03 Nível único: não há hierarquia de zonas (estado → região → cidade); a estrutura é plana, conforme decidido em 03/09.
RN-04 Carga idempotente: a mesma planilha pode ser recarregada quantas vezes for preciso sem duplicar registros; a chave externa é o código IBGE.
RN-05 Vigência: mudança de zona de uma cidade não altera pedidos e ativos já existentes; vale para novas cotações a partir da data de vigência.
RN-06 Cidade sem zona: se um endereço qualificado cair em cidade sem zona cadastrada, a jornada bloqueia com mensagem orientando o cadastro, em vez de assumir uma zona default.

ESPECIFICAÇÃO TÉCNICA
Objetos: registros de política geográfica (GeographicCommercialPolicy, modelo do §37.2 do manual) com CityIBGECode, AvailabilityZoneCode e PriceZoneCode; Pricing Context Rules por PriceZoneCode para as Price List Entries (W-000085).
Carga: aba "Zonas" da planilha mestre (US CAT-TPL-01) com colunas UF, município, IBGE, zona de disponibilidade, zona de preço, vigência; carga via Data Loader ou script com upsert pela chave externa.
Consumo: a viabilidade (W-B2C-02) grava o IBGE no Premises; a QUAL-01 resolve a zona de disponibilidade; o Create Cart (W-000084) passa o PriceZoneCode ao contexto de precificação.
Governança: alteração de zona exige aprovação da gestão de produtos e registro de vigência; relatório de cidades sem zona.

DEPENDÊNCIAS E RISCOS
Dependências: template de zonas da liderança (ata 03/09); US CAT-TPL-01; QUAL-01 e W-000085; P-17 (solução técnica IBGE).
Riscos: divergência entre a base de cidades do legado e a lista IBGE; municípios atendidos parcialmente (bairros) não têm granularidade nesta fase.

CRITÉRIOS DE ACEITE
Cenário 1: Carga completa. Dado a planilha de zonas aprovada, quando a carga for executada, então toda cidade da lista existe no Salesforce com zona de disponibilidade e zona de preço e a recarga não cria duplicidade.
Cenário 2: Resolução na jornada. Dado um endereço qualificado em cidade da zona de preço B, quando o carrinho abrir, então as ofertas exibidas são as da zona de disponibilidade da cidade e os preços vêm da tabela B.
Cenário 3: Cidade sem zona. Dado um endereço em cidade sem zona cadastrada, quando a viabilidade concluir, então a jornada bloqueia com mensagem de cadastro pendente e nenhum preço default é aplicado.
