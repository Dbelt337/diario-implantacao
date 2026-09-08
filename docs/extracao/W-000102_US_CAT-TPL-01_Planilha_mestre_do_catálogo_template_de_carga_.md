# W-000102 — US CAT-TPL-01 — Planilha mestre do catálogo (template de carga)

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 04/09/2026 15:07 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:07 por Diego Beltrão de Moraes

US de arquitetura (decisao 02-04/09). O "wizard" da fase 1 e uma PLANILHA MESTRE: template unico com tudo que precisa ser preenchido para gerar o catalogo, eliminando manipulacao manual linha a linha.

NARRATIVA
Como Gestao de Produtos, quero um template mestre padronizado com todas as abas e colunas necessarias para especificar o catalogo completo, para que o preenchimento de premissas gere a carga do EPC sem conhecimento tecnico de Salesforce e com chance de erro proxima de zero.

ESCOPO (abas do template)
1. Ofertas comerciais (nomes GENERICOS, sem marca - decisao do rebranding Grupo Evo);
2. Product Specs e atributos por Object Type (herdando a estrutura das EPC-01/03/04/05);
3. Picklists e valores;
4. Zonas de disponibilidade (carga IBGE -> zona) e zonas de preco (tabelas A/B/C por concorrencia);
5. Matriz de precos com os 4-5 parametros: velocidade/atributo x zona de preco x prazo de contrato (12/24/36/48/60) x segmento, com preco base, sugerido e floor;
6. Promotions/combos (incluindo linhas dedicadas para combos com variacao drastica de preco);
7. Codigos de material SAP + descricao fiscal por item;
8. Campo de STATUS por linha (rastreio de carga: pendente/carregado/erro).
REGRAS
- O template e a fonte de verdade da carga; toda oferta nova nasce nele;
- Validacoes de preenchimento na propria planilha (dominios, obrigatoriedade, caracteres proibidos conforme manual de padroes);
- Prazo executivo: catalogo completo ate 11/10.

DEPENDENCIAS: templates e esqueleto fornecidos pela lideranca (ata 03/09); listagem de atributos sanitizada (Welker); EPC-01/03/04/05.

CRITERIOS DE ACEITE
1. Dado o template preenchido para uma familia, quando revisado pela gestao de produtos, entao nenhuma coluna obrigatoria esta vazia e os dominios de valores conferem com o dicionario aprovado.
2. Dado o template aprovado, quando a carga for executada, entao cada linha ganha status de carga (carregado/erro) e nenhum item e criado fora do template.
3. Dado um erro de carga, quando o status indicar erro, entao a linha traz a causa e pode ser corrigida e recarregada sem duplicar registros.
