# W-000060 — US B2C-04 — Antecipação da Consulta de Débito no Endereço (Pré-Viabilidade / Flag)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:15 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:50 por Diego Beltrão de Moraes

"Como Vendedor e Analista de Compliance
Quero que o sistema identifique se o endereço de instalação possui histórico de débitos ou reincidência de inadimplência (cruzando CEP, número e vínculos) e exiba uma sinalização visual (Flag) sem bloquear a venda
Para que o atendimento comercial siga de forma fluída e as propostas realizadas em locais inadimplentes sejam consolidadas em relatórios estratégicos pós-venda para análise de risco.

SOLUÇÃO TÉCNICA: consulta de histórico do endereço na MESMA viagem da viabilidade (W-B2C-02);
chave CEP + número + IBGE — nunca complemento. Sem trava e sem alçada (requisito explícito).
REUSO: modelo Endereco__c + Address + junção EnderecoUtilizadoOpportunity__c; Reports nativos.
CONSTRUIR: Opportunity.AddressDebtFlag__c (Checkbox) + AddressDebtSummary__c (Long Text com o resumo
da API); FlexCard de alerta na jornada; relatório ""Vendas Concluídas em Endereços Inadimplentes""
(acesso: coordenadores/gerentes).

Dependências: API de histórico de inadimplência por endereço no Customer Core (dono: TI).
Consolidação: substitui as DUAS histórias duplicadas do refinamento original (H4 e H8).

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-04."

## Critérios de Aceite (related list)

**1. 2** (New)
Consolidação em Relatório Gerencial Pós-Venda — Dado que uma venda foi concluída com sucesso em um endereço sinalizado com débito; Quando a Oportunidade/Pedido é salvo; Então o registro deve ser incluído automaticamente no relatório pós-venda "Vendas Concluídas em Endereços Inadimplentes" para análise da gestão.

**2. 1** (New)
Identificação de Débito no Endereço sem Bloqueio de Venda — Dado que o endereço "Rua das Flores, 100, Apto 21" possui histórico de contrato inadimplente na base; Quando o vendedor cadastra uma nova proposta para o mesmo imóvel; Então o sistema deve exibir a sinalização visual de alerta de débito e permitir que a venda prossiga normalmente sem exigir aprovação bloqueante.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: gap confirmado (matriz #3, severidade media - historico do endereco sem cadeia 1:1 no ZIP).
CONSTRUIR: capacidade completa como especificado nesta work (consulta na mesma viagem da viabilidade, flag sem bloqueio, relatorio pos-venda).
DIRETRIZ SYSMAP: definir com TI a fonte (API de inadimplencia por endereco no Customer Core), chave CEP+numero+IBGE, bloqueios de acesso (FLS) e privacidade ANTES de iniciar o desenvolvimento.

--- MODELO DE ENDERECO (decisao 01/09, registro 04/09) ---
A secao REUSO desta work cita Endereco__c + EnderecoUtilizadoOpportunity__c. Isso fica INVALIDADO pela decisao de arquitetura de 01/09 (registrada em W-000094/W-000097): o objeto custom Endereco__c esta DESCONTINUADO e nenhuma funcao nova nasce nele. A flag de debito no endereco (AddressDebtFlag__c / AddressDebtSummary__c) passa a viver no Premises/ServicePoint do pacote (chave CEP+numero+IBGE, criado on-demand pela W-B2C-02), que e o mesmo registro consultado pela viabilidade. Reports continuam nativos. Convivencia com a base legada via de-para (external ID) na migracao (US CAT-MIG-01, W-000103).

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-04 — Sinalização de Débito no Endereço (Flag/Relatório) e Histórico sem Trava Impeditiva to US B2C-04 — Antecipação da Consulta de Débito no Endereço (Pré-Viabilidade / Flag)
