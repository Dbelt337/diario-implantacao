# W-000107 — US CPQ-BRE-01 — Motor de regras de precificação de projetos especiais (Prisma → Business Rules Engine)

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:18 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:18 por Diego Beltrão de Moraes

US de CPQ B2B (agenda presencial 02/09: ações "Configurar Sandbox BRE", "Compartilhar Planilha" do Joel, "Analisar planilha e proposta"; tema "Implementação e Padronização via BRE" e "Fluxo de Aprovação Automatizado").

NARRATIVA
Como Gerente de Relacionamento B2B, quero que a precificação de projetos especiais (links dedicados, multi-site, terceiros) seja calculada por um motor de regras no Salesforce, a partir das regras hoje embutidas na planilha do Joel e no código do Prisma, para que a cotação saia com preço, margem e alçada corretos sem cálculo manual fora do sistema.

CONTEXTO E CENÁRIO DE NEGÓCIO
Hoje a regra de precificação de projetos especiais vive em uma planilha de referência com lógica oculta e no código da plataforma interna (Prisma). Em 02/09 decidiu-se extrair essa lógica e rodá-la no Business Rules Engine em uma sandbox limpa, com apoio de IA na conversão. O motor calcula custo total, divide por endereços quando o link é de terceiro, aplica indicadores financeiros e aciona a aprovação hierárquica (RED, COL) quando um indicador é ferido.

REGRAS DE NEGÓCIO
RN-01 Fonte única das regras: a planilha do Joel, depois de formalizada, é a especificação; toda regra implementada referencia a linha ou aba de origem.
RN-02 Parâmetros de entrada mínimos: velocidade, meio de acesso, prazo de contrato, quantidade de endereços, custo de terceiro por endereço (quando houver), segmento e zona de preço.
RN-03 Saídas obrigatórias: preço de venda sugerido, preço mínimo (floor), margem de contribuição estimada e indicador de alçada necessária.
RN-04 Alçada automática: se margem ou payback ferirem os limites configurados, a cotação entra em aprovação do nível correspondente antes de gerar proposta.
RN-05 Rastreabilidade: cada cálculo grava a versão das regras usada e os parâmetros, para auditoria e para reprocessamento em caso de mudança de tabela.
RN-06 Sem preço manual: o vendedor não digita preço de projeto especial; pode aplicar desconto dentro da alçada, sobre o valor calculado.

ESPECIFICAÇÃO TÉCNICA
Business Rules Engine (Decision Matrices e Decision Tables) com Expression Sets por tipo de projeto; invocado por Integration Procedure a partir do carrinho da cotação B2B (W-000098).
Sandbox dedicada (ação do Bismarck) sem dados de clientes para o desenvolvimento das regras; carga das tabelas via CSV a partir da planilha formalizada.
Versionamento das matrizes; log do cálculo em objeto próprio ligado à Quote; integração com o Approval Process de margem já previsto na B2B-03.

DEPENDÊNCIAS E RISCOS
Dependências: planilha de regras formalizada pelo Joel; sandbox limpa; licenciamento do Business Rules Engine confirmado com o AE; B2B-03 (cotação multi-site e alçadas).
Riscos: regras implícitas não documentadas na planilha; divergência entre o Prisma e a planilha; volume de combinações nas matrizes.

CRITÉRIOS DE ACEITE
Cenário 1: Cálculo de projeto simples. Dado uma cotação B2B com um endereço, velocidade e prazo informados, quando o vendedor solicitar o preço, então o motor devolve preço sugerido, floor e margem iguais aos da planilha de referência para o mesmo caso.
Cenário 2: Projeto com terceiros. Dado um projeto com 5 endereços e custo de terceiro por endereço, quando o cálculo rodar, então o custo total é dividido pelos endereços e o preço unitário reflete a divisão.
Cenário 3: Alçada. Dado um resultado com margem abaixo do limite, quando a cotação avançar, então ela é bloqueada em aprovação do nível correspondente e a proposta não é gerada antes da aprovação.
Cenário 4: Auditoria. Dado um cálculo concluído, quando consultado, então a versão das regras e os parâmetros usados estão gravados e legíveis.
