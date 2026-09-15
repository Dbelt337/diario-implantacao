# US B2B-13 — Refidelização pura e simples B2B: renovação de prazo sem alteração de escopo (aditivo de tempo)

| Campo | Valor |
|---|---|
| Work | (a criar no Agile Accelerator) |
| Épico | B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente |
| Time (Scrum Team) | SysMap |
| Status | New |
| Responsável | a definir |
| Documento gerado em | 15/09/2026 |

US de negócio B2B (documento de 10/09, "Histórias novas", história 26; decisões de 10/09 na W-000100 notas (c) e (f); comentários de negócio de 14/09 na história 14: refidelização cobre todas as etiquetas do contrato guarda-chuva, prazo "e outros"). Fundamentação técnica em `docs/2026-09-15-fundamentacao-tecnica-historias-26-29.md`.

## Descrição
Como Gerente de Relacionamento
Quero renovar o prazo de fidelidade de um contrato B2B ativo, sem alterar produtos, quantidades nem valores, escolhendo 12, 24, 36, 48, 60 meses ou um prazo customizado, com aditivo de tempo gerado pelo sistema e aprovação do BKO
Para que a vigência jurídica seja estendida e o MRR garantido sem abrir uma ordem de alteração técnica.

## Contexto e Cenário de Negócio
A W-000100 trata refidelização apenas junto com upgrade. Não existe fluxo para renovar prazo sem mexer no escopo, que é a operação mais frequente de retenção preventiva. O contrato B2B é guarda-chuva: a renovação vale para todas as etiquetas e ativos do contrato, não para um ativo isolado. Não há Arquitetura, carrinho nem Order Management: só datas, aditivo, aprovação e sincronização de vigência com o Customer Core.

## Regras de Negócio Associadas
RN-01 Entrada pela Visão 360º do grupo econômico (B2B-10) no contrato escolhido. Perfis: GR dono da conta e gestor. SDR não executa.
RN-02 Elegibilidade: Contract com Status na categoria Activated e sem outra Oportunidade aberta de record type Alteração Contratual ou Refidelização Simples para o mesmo contrato. Havendo, o sistema bloqueia e aponta a oportunidade em andamento.
RN-03 Prazo: picklist 12, 24, 36, 48, 60 meses ou "Outro" (campo numérico em meses). "Outro" exige justificativa obrigatória, como já decidido na W-000100 (c).
RN-04 Escopo travado: o OmniScript exibe os ativos do contrato em somente leitura (nome, atributos principais, MRC atual) para confirmação visual. Não há carrinho, não se adiciona nem remove item, não se altera preço. Qualquer necessidade de mudança de escopo encerra este fluxo e direciona ao MACD (W-000100 ou W-000125).
RN-05 Vigência: a renovação grava novo Contract Term (months) e nova Contract Start Date da vigência renovada; Contract End Date é calculada pela configuração padrão do Contract (start + term). A Data Fim de Fidelidade (campo custom no Contract e nos Assets do contrato) é atualizada para todas as etiquetas do contrato (guarda-chuva).
RN-06 Aditivo de tempo gerado pelo Amend Frame Agreement do Industries CLM (TEC-CLM-01) com contract type próprio "Aditivo de Refidelização": o aditivo nasce ligado ao contrato master (lista Amendment Contracts) e ao registro que o originou. No aditivo o sistema grava Contract Start Date e Contract Term (months) e estende a Effective End Date dos descontos contract-based do frame agreement (desconto de fidelidade B2B, W-000100 nota (g)). Como o Amend não copia os termos gerais, o template do aditivo carrega as cláusulas de renovação. Aceite pelo signatário legal conforme B2B-09.
RN-07 Ciclo do aditivo pelo Contract State Model do CLM: estados Rascunho → Aguardando Aceite → Aguardando BKO → Ativo → (Rejeitado), com Vlocity Actions por estado e Applicable User Profile: o GR só cria e envia; a ação "Aprovar Aditivo" aparece apenas para o perfil BKO, no estado Aguardando BKO. O BKO só lê, não edita valores (W-000101). A sincronização com o legado só ocorre na transição para Ativo.
RN-08 Sincronização: após aprovação, Integration Procedure envia as novas datas de vigência ao Customer Core pelo endpoint proprietário via MuleSoft (decisão 04/09, W-000087); TMF651 fica como mapa de capacidade. Só após retorno 200 o contrato passa a "Renovado" e a oportunidade a Ganha.
RN-09 Nenhuma ordem técnica, nenhuma tarefa de Arquitetura, nenhuma submissão ao OM.
RN-10 Alerta pré-vencimento: scheduled path no Contract com Time Source = Data Fim de Fidelidade e offset de 60 dias antes (parametrizável em Custom Metadata) cria Task para o GR "Fidelidade vence em 60 dias". O path é cancelado automaticamente se o contrato deixar de atender (renovado, cancelado) e reagendado se a data mudar.
RN-11 Desconto de fidelidade: no B2B ele é contract-based discount do frame agreement, e a RN-06 estende sua vigência sem tocar nos assets. Se algum ativo tiver ajuste de promoção com Time Plan/Time Policy (Source = ABP), a nova duração é aplicada pelo Repricing Batch Processor restrito aos assets da conta/contrato, em batch de até 20 line items, porque o repricing atualiza as datas de efetividade dos ajustes de promoção conforme a price list vigente. Nenhum repricing automático de assets fora desse caso: a org mantém "Retain Original Price during MACD" para os preços não mudarem por efeito colateral.
RN-12 Multa: não se aplica, pois não há alteração de escopo nem cancelamento. Reajuste financeiro não tramita aqui (W-000100 nota (b)).

## Especificação Técnica (Salesforce)
Opportunity record type "Refidelização Simples" criada a partir da 360 (B2B-10); OmniScript "Renovação Contratual B2B" com FlexCard de ativos em somente leitura (Integration Procedure lendo Assets por Contract e Asset Reference ID); campos custom no Contract: Data Fim de Fidelidade, Prazo de Fidelidade (meses), Justificativa de Prazo; Validation Rule para RN-02; Vlocity CLM Amend com contract type "Aditivo de Refidelização" e template próprio (TEC-CLM-01, W-000106); Approval Process BKO com record lock; Integration Procedure de sincronização via Named Credential MuleCallout / IntegrationConfig__mdt; record-triggered flow no Contract com scheduled path (RN-10); Custom Metadata para offset do alerta e lista de prazos.

## Dependências, Riscos e Estimativa
Dependências: W-000123 (B2B-10, ponto de entrada), W-000100 (regras de prazo e justificativa), W-000126 (TEC-CLM-01 aditivo), W-000122 (B2B-09 signatário), W-000101 (fila BKO), W-000087 (integrações), W-000103 (Assets com fidelidade carregada), P1 do Joel (prazo de contrato na oferta).
Riscos: Customer Core precisa devolver as vigências atuais e aceitar update de datas; contratos sem Asset sincronizado (hoje a org só tem OrderItems com action Add, W-000099) não podem ser renovados pela 360.
Estimativa: 8 Story Points.

## Critérios de Aceite (formato Agile Accelerator: Name | Status | Description)

| Name | Status | Description |
|---|---|---|
| Critério 1 — Elegibilidade e trava | New | Dado um contrato B2B ativo com uma Oportunidade de Alteração Contratual aberta, quando o GR aciona "Refidelizar" na 360, então o sistema bloqueia e exibe o número da oportunidade em andamento. |
| Critério 2 — Prazo padrão | New | Dado um contrato ativo há 12 meses sem MACD aberto, quando o GR escolhe 24 meses e confirma, então o sistema gera o aditivo sem acionar Arquitetura e envia à fila de aprovação do BKO. |
| Critério 3 — Prazo customizado | New | Dado o OmniScript de renovação, quando o GR escolhe "Outro" e informa 18 meses sem justificativa, então o sistema bloqueia o avanço até a justificativa ser preenchida. |
| Critério 4 — Escopo somente leitura | New | Dado o OmniScript carregado, quando o GR visualiza os ativos, então eles aparecem em somente leitura e não existe ação de adicionar item, remover item ou alterar preço. |
| Critério 5 — Aditivo e datas | New | Dado o aditivo de 36 meses aceito pelo signatário legal e aprovado pelo BKO, quando a sincronização com o Customer Core retorna sucesso, então Contract Term = 36, Contract End Date recalculada, Data Fim de Fidelidade atualizada em todos os assets do contrato e o aditivo listado em Amendment Contracts. |
| Critério 6 — BKO obrigatório | New | Dado o aditivo em Aguardando BKO, quando um usuário GR abre o registro, então a ação "Aprovar Aditivo" não aparece; e enquanto o BKO não aprova, nenhuma chamada ao Customer Core é feita e o contrato permanece com os dados anteriores. |
| Critério 9 — Desconto de fidelidade | New | Dado um frame agreement com desconto contract-based vencendo em 31/12, quando a refidelização de 24 meses é ativada, então a Effective End Date do desconto passa para 24 meses após o novo início e os MRC dos assets não mudam. |
| Critério 7 — Alerta pré-vencimento | New | Dado um contrato com Data Fim de Fidelidade em 60 dias, quando o scheduled path executa, então uma Task é criada para o GR; e se o contrato for renovado antes, o path pendente é cancelado sem gerar Task. |
| Critério 8 — Guarda-chuva | New | Dado um contrato com três etiquetas ativas, quando a refidelização é concluída, então as três recebem a mesma Data Fim de Fidelidade. |

Massa de teste sugerida: Business Account (CNPJ) com contrato de conectividade ativo há 12 meses e três assets; renovação para 36 meses; usuário perfil BKO para aprovar; contrato com Oportunidade de upgrade aberta para o critério 1.
