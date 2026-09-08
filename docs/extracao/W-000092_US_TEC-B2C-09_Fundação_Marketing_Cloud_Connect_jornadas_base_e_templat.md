# W-000092 — US TEC-B2C-09 — Fundação Marketing Cloud (Connect, jornadas base e templates WhatsApp)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:40 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

Narrativa: Como time de implantação, quero a fundação do Marketing Cloud conectada e governada, para as réguas e jornadas da jornada B2C (lembretes de assinatura da US-14 / B2C-10, notificações de cobrança e reengajamento LGPD da US-NEW-03 / B2C-26) dispararem por e-mail e WhatsApp respeitando o consentimento.

Escopo técnico:
- Marketing Cloud Connect: usuário de integração e sincronismo dos objetos Lead, Opportunity e consentimentos
- Jornada base no Journey Builder com entrada por dado sincronizado e Exit Criteria por mudança de status
- WhatsApp via GroupConnect com templates submetidos à aprovação da Meta (prazo de até 24h por template) e disparo pela atividade nativa de WhatsApp do Journey Builder
- Remetentes de e-mail autenticados (aproveitar SPF/DKIM já configurados)
- Janela de envio padrão 08h às 20h nas jornadas
- Consentimento por canal respeitado nas audiências (ContactPointTypeConsent / opt-out, conforme complemento da B2C-26)

Dependências: licenças e contas do Marketing Cloud ativas com GroupConnect habilitado; aprovação dos templates na Meta; B2C-26 (modelo de consentimento); domínios de e-mail autenticados.

## Critérios de Aceite (related list)

**1. Cenário 4: Somente templates homologados** (New)
Dado um template de WhatsApp ainda não aprovado pela Meta
Quando uma jornada tenta utilizá-lo
Então o envio é bloqueado e o erro registrado, permitindo apenas templates homologados

**2. Cenário 3: Consentimento respeitado** (New)
Dado um cliente com opt-out registrado
Quando qualquer jornada monta a audiência
Então o cliente não é incluído e nenhum disparo é feito para os pontos de contato dele

**3. Cenário 2: Entrada, janela e saída da jornada** (New)
Dado uma oportunidade em Aguardando Assinatura
Quando ela entra na jornada de lembretes
Então os disparos ocorrem somente na janela das 08h às 20h e a jornada é encerrada imediatamente pelo Exit Criteria quando o contrato é assinado

**4. Cenário 1: Sincronismo Salesforce x Marketing Cloud** (New)
Dado um registro criado ou alterado no Salesforce
Quando o sincronismo do Marketing Cloud Connect executa
Então a data extension reflete o dado dentro do SLA definido, sem erro de mapeamento

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: gap confirmado (matriz #20, severidade alta).
CONSTRUIR: nenhuma regua de comunicacao localizada em producao - fundacao Marketing Cloud e construcao plena (Connect, jornadas, templates WhatsApp com aprovacao Meta, consentimento, janela 08h-20h, monitoramento), conforme esta work ja especifica.
DIRETRIZ SYSMAP: bloquear o inicio ate a confirmacao da licenca MC + GroupConnect (pendencia corroborada pelo AS-IS); usar o fallback nativo (flow + canal do bot) se a licenca atrasar.
