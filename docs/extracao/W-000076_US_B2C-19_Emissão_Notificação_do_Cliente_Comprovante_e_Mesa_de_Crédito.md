# W-000076 — US B2C-19 — Emissão, Notificação do Cliente, Comprovante e Mesa de Crédito

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

Referência: US-16 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-16: Emissão, Notificação do Cliente, Comprovante e Mesa de Crédito
1. NARRATIVA DE NEGÓCIO
Como Vendedor, Cliente e Analista de Crédito
Quero gerenciar todo o ciclo da Taxa de Ativação (gerar cobrança, notificar, anexar comprovante, analisar isenção/liberação e agendar)
Para que a Brasil TecPar garanta o recebimento do custo de ativação antes de deslocar a equipe de campo, abrindo exceções apenas sob governança estrita da Mesa de Crédito.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Estruturação das etapas 4 a 8 apontadas pelo negócio, cobrindo o fluxo financeiro de aprovação de crédito/ativação.
Regras:
* Etapa 5 (Gerar Taxa) & Etapa 6 (Informar Cliente): O sistema deve consumir a API do Billing para gerar o link de pagamento (Pix/Boleto) e disparar notificação automática (WhatsApp/E-mail) alertando sobre a necessidade de pagamento.
* Etapa 4 (Agendamento Direto por Isenção): Caso a taxa seja isenta (Aprovada pela Mesa ou configurada na Promoção), o sistema deve liberar o agendamento no Field Service imediatamente, pulando a esteira de cobrança.
* Etapa 7 (Envio do Comprovante) & Etapa 8 (Análise de Liberação): Quando o cliente envia o comprovante de pagamento, o vendedor deve anexar a evidência (PDF/Imagem) na Oportunidade/Ordem e acionar a Mesa de Crédito. A Mesa analisará a evidência e liberará o agendamento técnico.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Opportunity, Order, ContentVersion/ContentDocumentLink (Anexos), ApprovalProcess.
Automação / Lógica:
* Integration Procedure: Geração de Fatura no BSS.
* Processo de Aprovação: "Análise de Comprovante - Mesa de Crédito".
* Screen Flow: Upload de Arquivo (lightning-file-upload) obrigatório para avançar.
Integração / APIs:
* TMF678 (Customer Bill Management API) para emissão do meio de pagamento.
* Disparo via Marketing Cloud Journey Builder para notificação do cliente (Etapa 6).
Segurança e Acessos: Fila "Mesa de Crédito - Liberação de Taxa". Vendedor com acesso apenas de upload e leitura do status.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Isenção aprovada liberando agendamento (Etapa 4)
Dado que a taxa de ativação foi definida como Isenta (R$ 0,00) na cotação
Quando a oportunidade avançar para o estágio de Delivery
Então o sistema oculta as etapas de cobrança e desbloqueia diretamente a interface de agendamento (Field Service).
Cenário 2: Anexar comprovante e análise da Mesa (Etapas 7 e 8)
Dado que o cliente enviou o comprovante de pagamento via WhatsApp e o retorno do banco (BSS) ainda não compensou automaticamente
Quando o vendedor anexa a evidência e clica em "Solicitar Liberação Manual"
Então o sistema envia o registro para aprovação da Mesa de Crédito, bloqueia a Oportunidade e só libera o agendamento após a Mesa clicar em "Aprovar Comprovante".
5. DEPENDÊNCIAS E RISCOS
Dependências: Integração com motor de faturamento para gerar o QR Code Pix/Boleto e integração MKT Cloud para os disparos ativos.
Riscos/Premissas: [Edge Cases] O comprovante anexado pode ser ilegível. A Mesa de Crédito deve ter a opção "Rejeitar - Solicitar Novo Anexo", enviando uma Task de volta ao vendedor.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: Oportunidade isenta de taxa; Geração de link de pagamento com mock TMF678; Upload de PDF e aprovação pela Mesa.
Estimativa de Esforço: 13 Story Points.

## Critérios de Aceite (related list)

**1. Cenário 2: Anexar comprovante e análise da Mesa (Etapas 7 e 8)** (New)
Dado que o cliente enviou o comprovante de pagamento via WhatsApp e o retorno do banco (BSS) ainda não compensou automaticamente
Quando o vendedor anexa a evidência e clica em "Solicitar Liberação Manual"
Então o sistema envia o registro para aprovação da Mesa de Crédito, bloqueia a Oportunidade e só libera o agendamento após a Mesa clicar em "Aprovar Comprovante".

**2. Cenário 1: Isenção aprovada liberando agendamento (Etapa 4)** (New)
Dado que a taxa de ativação foi definida como Isenta (R$ 0,00) na cotação
Quando a oportunidade avançar para o estágio de Delivery
Então o sistema oculta as etapas de cobrança e desbloqueia diretamente a interface de agendamento (Field Service).

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: parcial (matriz #9) + gap financeiro (matriz #23; TMF678 nao localizada).
REUSAR: aprovacao da Mesa via FLW_Approval_InstallationFee e componentes da taxa (ver W-000068).
CONSTRUIR: geracao de cobranca (link Pix/boleto), notificacao, anexo de comprovante e liberacao manual - sem cadeia financeira 1:1 no AS-IS.
DIRETRIZ SYSMAP: contrato da emissao de cobranca (TMF678 como alvo, endpoint do BSS como realidade) precisa ser definido com o financeiro antes do desenvolvimento; nao mockar baixa bancaria em UAT sem plano de reconciliacao.
