# W-000112 — US CAT-CHD-01 — Componentes comerciais como produtos filhos (Porta secundária, Anti-DDoS, NOC, Locação de Roteador)

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:22 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:22 por Diego Beltrão de Moraes

US de catálogo (versão 2 da planilha de Object Types da SysMap, 04/09: anotações "vira produto" e "retirar" na Oferta de Internet Corporativa; decisão de 03/09 de separar atributo comercial de SKU técnico).

NARRATIVA
Como Gestão de Produtos, quero que os componentes com preço, SLA ou estoque próprios (Porta de Acesso à Rede Secundária, Anti-DDoS, Monitoramento NOC e Locação de Roteador) sejam produtos filhos opcionais das ofertas corporativas, e não atributos, para que cada um tenha preço, inventário e provisionamento independentes.

CONTEXTO E CENÁRIO DE NEGÓCIO
Na planilha original esses itens eram atributos da oferta. A SysMap propôs na v2 que virem produtos, o que está alinhado à regra do EPC: característica é atributo; o que tem preço, SLA ou estoque é produto filho. A proposta anotou apenas a Oferta de Internet Corporativa; a PME e os atributos remanescentes (Anti-DDoS e Nível de NOC) precisam de decisão.

REGRAS DE NEGÓCIO
RN-01 Critério de modelagem: vira produto filho o que tem preço próprio, SLA próprio ou movimenta estoque; permanece atributo o que só caracteriza (Meio de acesso, Banda, IPv4, IPv6).
RN-02 Produtos filhos da Onda 1: Porta Secundária (redundância), Anti-DDoS, Monitoramento NOC e Locação de Roteador; opcionais, com cardinalidade mínima zero.
RN-03 Um produto com atributo, não N produtos: Monitoramento NOC é um produto com atributo Nível (Bronze, Prata, Ouro); Anti-DDoS é um produto com atributo de modo (padrão ou parametrizado); "NOC Premium" é nome comercial.
RN-04 Ausência é o default: sem o produto filho não há NOC nem Anti-DDoS; os valores "Sem NOC" e "Desativado" deixam de existir nas picklists.
RN-05 PME segue a mesma regra: a Oferta de Internet Corporativa PME herda a mesma estrutura de filhos; Pacote SVA sai das ofertas corporativas.
RN-06 Locação de Roteador: produto filho de equipamento com estoque, modelo como atributo técnico (SKU) e locação com prazo compartilhado (PL_PRAZO_MESES).
RN-07 Preço: cada filho tem Price List Entry própria por zona quando aplicável e entra na matriz como linha própria.

ESPECIFICAÇÃO TÉCNICA
Product Specs e produtos filhos nas ofertas corporativas (Object Types da revisão v2); atributos Nível de NOC e Anti-DDoS movidos para os produtos filhos; Locação de Roteador com filho de inventário; cardinalidades e regras de compatibilidade (ex.: Porta Secundária exige meio de acesso diferente do primário); decomposição no OM gera itens técnicos por filho; picklists ajustadas (remoção de Sem NOC e Desativado).

DEPENDÊNCIAS E RISCOS
Dependências: aprovação da revisão v2 da planilha (Object Type alinhado à aba Valores); EPC-04 e EPC-05; W-000085; vendors de firewall e Wi-Fi (P-02, WITO) para o SKU técnico.
Riscos: migração de ofertas legadas onde esses itens eram atributos; combinações de filhos multiplicando a matriz de preço.

CRITÉRIOS DE ACEITE
Cenário 1: Oferta sem opcionais. Dado uma Oferta de Internet Corporativa, quando adicionada ao carrinho sem filhos, então não há NOC nem Anti-DDoS e o preço é só o da conectividade.
Cenário 2: NOC como produto. Dado o vendedor incluir Monitoramento NOC nível Ouro, quando precificar, então aparece linha própria com preço da zona e a decomposição gera item técnico de monitoramento.
Cenário 3: Porta secundária. Dado a inclusão de Porta Secundária com o mesmo meio de acesso do primário, quando validar, então o carrinho bloqueia e exige tecnologia diferente.
Cenário 4: PME. Dado uma Oferta PME, quando montada, então os mesmos filhos opcionais estão disponíveis e Pacote SVA não aparece.
