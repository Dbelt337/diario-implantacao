# W-000110 — US TEC-INT-02 — Integração com fornecedores de SVA e mapeamento de IDs de plano

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:21 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:21 por Diego Beltrão de Moraes

US técnica (agenda presencial 02/09: ações "Configurar Integração Produto" (Disney, PlayHub) e "Definir Mapeamento IDs"; 03/09: "Contatar Parceiro" para telefonia móvel).

NARRATIVA
Como time de integração, quero que cada oferta de SVA, streaming e móvel do catálogo carregue o identificador do plano no fornecedor e que a ativação e o cancelamento sejam disparados pelo plano de orquestração, para que o cliente receba o serviço do parceiro automaticamente e a baixa aconteça no cancelamento.

CONTEXTO E CENÁRIO DE NEGÓCIO
As ofertas de serviços digitais dependem de fornecedores externos (agregadores de streaming, parceiro de telefonia móvel). Em 02/09 ficou em aberto onde guardar os IDs de plano do fornecedor e como parametrizar as integrações. A decisão de nomes genéricos (rebranding) exige que o nome comercial e o identificador técnico do fornecedor sejam separados.

REGRAS DE NEGÓCIO
RN-01 Separação comercial e técnica: o atributo comercial (ex.: Nível de Streaming) nunca contém o ID do fornecedor; o ID vive em atributo técnico não visível ao vendedor.
RN-02 Um ID por fornecedor por produto: o mesmo produto pode ter IDs distintos por fornecedor ou por região; o mapeamento é tabela versionada, não código.
RN-03 Ativação orquestrada: a ativação no fornecedor é um item do plano de orquestração após confirmação de pagamento ou crédito, nunca chamada da tela.
RN-04 Cancelamento espelhado: cancelamento ou downgrade do SVA dispara a baixa no fornecedor e o cliente não é cobrado após a data de baixa.
RN-05 Falha tolerada: falha do fornecedor não cancela o pedido; gera tarefa de fallout com retentativa e prazo.
RN-06 Móvel: a ativação de linha exige integração com o parceiro MVNO e não emite NF pela BTP (Anatel).
RN-07 Limite de licenças: o fornecedor recebe a quantidade de licenças do atributo Limite de Licenças; excedente não é permitido no carrinho.

ESPECIFICAÇÃO TÉCNICA
Atributo técnico de identificador de fornecedor nas Product Specs de SVA/Streaming/Móvel (categoria técnica, não exibida); Custom Metadata ou objeto de mapeamento produto × fornecedor × ID × vigência; Orchestration Items de Callout via MuleSoft com endpoints proprietários na Onda 1 e adapter TMF quando formalizado (W-000087); fallout management do OM; contratos de payload registrados na W-000087.

DEPENDÊNCIAS E RISCOS
Dependências: contratos com os fornecedores de conteúdo e com o parceiro móvel (contato do Gabriel); US CAT-FAM-01 (modelagem das famílias); W-000087 e W-000093.
Riscos: APIs de fornecedor sem ambiente de homologação; mudanças de IDs sem aviso; limites de licença divergentes entre fornecedor e catálogo.

CRITÉRIOS DE ACEITE
Cenário 1: Ativação de streaming. Dado um pedido com streaming Premium pago, quando o plano de orquestração chegar ao item do fornecedor, então a chamada leva o ID técnico mapeado e a quantidade de licenças, e o retorno de sucesso ativa o Asset.
Cenário 2: Falha do fornecedor. Dado indisponibilidade do fornecedor, quando a chamada falhar, então o pedido não é cancelado, uma tarefa de fallout é criada e a retentativa ocorre no prazo definido.
Cenário 3: Cancelamento. Dado o cancelamento de um SVA, quando confirmado, então a baixa é enviada ao fornecedor e a cobrança cessa na data de baixa.
Cenário 4: Nome genérico. Dado a oferta exibida ao vendedor, quando inspecionada, então o nome comercial é genérico e o ID do fornecedor não aparece.
