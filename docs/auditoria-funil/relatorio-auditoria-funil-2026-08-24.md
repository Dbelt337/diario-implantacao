# Auditoria do funil comercial — Oportunidades sem Order, Quotes em Draft e vendas sem Contrato

**Data da extração:** 24/08/2026
**Origem:** 3 varreduras SOQL na produção, derivadas dos casos-índice **0005526** (Opportunity avançada sem Order) e **0009727** (Opportunity parada em "Aguardando contrato" sem Contract).
**Planilha operacional:** `auditoria-funil-sem-order-2026-08-24.xlsx` (abas: Resumo, Varredura A, Piores Casos, Varredura B, Varredura C, Por Dono) — pronta para envio à Tayza e ao time de BKO.

## Números consolidados

| Varredura | O que mede | Total |
|---|---|---|
| **A** | Oportunidades abertas em "Contrato assinado"/"Aguardando instalação" **sem Order** | **2.217** |
| **B** | Quotes em **Draft** com funil avançado ("Aguardando contrato" em diante) | **2.538** (2.490 opps distintas; 44 com mais de uma quote Draft) |
| **C** | Oportunidades em "Aguardando contrato" **sem Contrato** há mais de 15 dias | **183** |

### Leitura da Varredura A (o padrão do caso 0005526 é sistêmico)

- 2.144 em "Aguardando instalação" e 73 em "Contrato assinado"; mix: 896 B2W, 884 B2B, 384 B2G, 53 sem tipo.
- **2.202 das 2.217 (99,3%) têm a Quote sincronizada parada em Draft** — a etapa avança sem a quote ser finalizada. Não é caso isolado: é o comportamento padrão do funil hoje.
- **Nenhuma gerou Order** — toda a esteira de ativação dessas vendas depende de intervenção manual.
- Envelhecimento (dias desde a última mudança de etapa): **258 paradas há mais de 180 dias**, 805 entre 91–180, 797 entre 31–90, 357 com menos de 31. A mais antiga é de **09/12/2025** (SEDESE — Rede PRODEMGE, 258 dias).
- 85 donos distintos. Top 5: Lucidia Anzanello Ampessan (258 — majoritariamente B2W "VENDIDO..."), Tamires Moreira Antero (99), Hermes Elias Gregorio (97), Carla Reis Espindola (92), Luiz Carlos da Silva Padilha e Cristiane Aparecida Busatto (90 cada).

### Piores casos (sem Contrato e/ou sem Quote — reconstrução total do ciclo)

16 oportunidades avançadas sem Quote sincronizada e/ou sem Contrato; as 9 marcadas **Contrato+Quote** não têm nenhum dos dois:

| Opportunity | Etapa | Dono | O que falta | Dias |
|---|---|---|---|---|
| Câmara Municipal de Alta Floresta | Contrato assinado | Roberto Wagner Sandrin | Contrato | 256 |
| Camera 13 - Vila Etelvina PM Itaara | Contrato assinado | Sandro Scharten Soares | Quote | 249 |
| APOSTILAMENTO MUNICIPIO DE BARRA DO QUARAI | Contrato assinado | Sandro Scharten Soares | Quote | 249 |
| SOPHOS B. A. P. AUTOMOTIVA LTDA | Aguardando instalação | Gregory Ragosta C. De Souza | Quote | 248 |
| SIM INTERNET PROVEDORES DE INTERNET LTDA | Contrato assinado | Luiz Carlos da Silva Padilha | Quote | 215 |
| SEJUSP NOVOS PEDIDOS REDE PRODEMGE 4/12 | Contrato assinado | Claudio Fernando De A. E Silva | Quote | 210 |
| TECKSOLUÇÕES_FIREWALL | Contrato assinado | Kelly Moraes Dos Santos | Contrato+Quote | 179 |
| Link Smart Basic | Contrato assinado | Daniela Wanzinck | Quote | 178 |
| PEDIDO 005 PROJETO 2026 | Contrato assinado | Alexsandro Jose P. De Andrade | Contrato+Quote | 175 |
| WIND NET SOCIEDAD ANONIMA | Aguardando instalação | Gabriel Fernando da Silva | Contrato+Quote | 175 |
| Rosul - Smart Internet Corporativa dupla abordagem | Contrato assinado | Wevelyn Gardin T. De Alencar | Contrato+Quote | 152 |
| MIGRACAO DE CIRCUITOS AVATO P/ ALT | Contrato assinado | Darlan Schneider | Contrato+Quote | 151 |
| SYNERGY BRAZIL | Aguardando instalação | Marcelo Mattos De Santana | Contrato+Quote | 144 |
| DECK - 34 PATROCINIO | Aguardando instalação | Kaio Mathias Amaral Ferreira | Contrato+Quote | 144 |
| MANIPURE PRODUTOS FARMACEUTICOS - PRES. OLEGARIO | Aguardando instalação | Kaio Mathias Amaral Ferreira | Contrato+Quote | 70 |
| Link - PME + Voz - NEW WALL GROUP INDUSTRY | Contrato assinado | Edivania Gomes Frois | Contrato+Quote | 35 |

### Leitura da Varredura C (o padrão do caso 0009727)

183 oportunidades em "Aguardando contrato" sem Contrato há mais de 15 dias: 4 há mais de 180 dias (a mais antiga, **PROJETO DOBLE AVATO**, 245 dias), 46 entre 91–180, 85 entre 31–90, 48 entre 15–30. Top donos: Leonardo Miguel Silva Vaz (13), Willian Goncalves Do Carmo Rocha e Luan Jair Geraldo (10 cada), Bruno Tavares Jose (9).

## Plano de ação proposto

1. **Mutirão de regularização (BKO + donos)** — trabalhar a planilha por prioridade (Crítica >180d primeiro). Regra geral: finalizar/aceitar a Quote sincronizada → conferir/vincular Contrato → gerar a Order retroativa. Negócio morto: fechar como Perdido em vez de deixar poluindo o funil.
2. **Os 16 piores casos** têm dono nomeado acima e exigem reconstrução do ciclo (ou descarte) — tratá-los como fila própria, com verificação caso a caso se o serviço já foi ativado por fora.
3. **Correção estrutural** — duas validation rules (works abaixo) para impedir novos casos. Com 2.217 ocorrências, a tese de "exceção pontual" está descartada.

## Works para o Agile (padrão do board, com ACs)

### Work 1 — Bloquear avanço para "Aguardando instalação" sem Order

Como Administrador do Salesforce, quero impedir que uma Opportunity avance para a etapa "Aguardando instalação" sem Order vinculada, para que nenhuma venda entre na esteira de ativação sem pedido gerado.

ESCOPO: campo de controle `Possui_Order__c` (checkbox) populado por record-triggered flow na criação/vinculação da Order + validation rule na Opportunity condicionada à mudança de etapa. Não retroage sobre o legado (tratado no mutirão); permissão custom `Bypass_Validacoes_Funil` para regularizações administrativas.

Justificativa: varredura de 24/08/2026 encontrou **2.217** oportunidades abertas em "Contrato assinado"/"Aguardando instalação" sem Order (mais antiga: 09/12/2025), incluindo 9 sem Contrato e sem Quote.

Dependências: definição com BKO do momento oficial de geração da Order no processo.
Fonte: relatório `auditoria-funil-2026-08-24`, casos 0005526/0009727.

Acceptance Criteria (3 registros):

1. **Bloqueio** — Dado que uma Opportunity não possui Order vinculada, quando o usuário tentar alterar a etapa para "Aguardando instalação", então a alteração é bloqueada com mensagem orientando a geração da Order.
2. **Liberação automática** — Dado que uma Order foi criada e vinculada à Opportunity, quando a etapa for alterada para "Aguardando instalação", então o avanço ocorre sem intervenção de administrador.
3. **Bypass auditado** — Dado que um usuário possui a permissão custom `Bypass_Validacoes_Funil`, quando alterar a etapa em regularização de legado, então a regra não se aplica e a alteração fica rastreável no histórico do campo.

### Work 2 — Bloquear avanço além de "Análise financeira" com Quote em Draft ou sem Quote sincronizada

Como Administrador do Salesforce, quero impedir que uma Opportunity avance além de "Análise financeira" com a Quote sincronizada em status Draft (ou sem Quote sincronizada), para que nenhuma venda avance no funil sem proposta finalizada.

ESCOPO: validation rule na Opportunity com referência cross-object `SyncedQuote.Status` e `SyncedQuoteId`; aplica-se às etapas "Validação técnica", "Aguardando contrato", "Contrato assinado" e "Aguardando instalação". Mesma permissão de bypass da Work 1. Não retroage sobre o legado.

Justificativa: varredura de 24/08/2026 — **2.538 quotes em Draft** em funil avançado (2.490 oportunidades distintas; 44 com múltiplas quotes Draft); **99,3%** das oportunidades avançadas sem Order têm a quote sincronizada em Draft.

Dependências: confirmar com o comercial o status-alvo da Quote ("Accepted"/"Approved") que representa proposta finalizada.
Fonte: relatório `auditoria-funil-2026-08-24`.

Acceptance Criteria (3 registros):

1. **Bloqueio** — Dado que uma Opportunity está sem Quote sincronizada ou com `SyncedQuote.Status = Draft`, quando o usuário tentar avançar a etapa além de "Análise financeira", então a alteração é bloqueada com mensagem indicando a pendência da Quote.
2. **Liberação** — Dado que a Quote sincronizada está no status-alvo aprovado, quando a etapa for avançada, então o avanço ocorre normalmente.
3. **Bypass auditado** — Dado que um usuário possui a permissão custom `Bypass_Validacoes_Funil`, quando alterar a etapa em regularização de legado, então a regra não se aplica e a alteração fica rastreável.

### Work 3 (opcional) — Mutirão de regularização do estoque

Como BKO, quero regularizar as 2.217 oportunidades sem Order e as 183 sem Contrato mapeadas na auditoria de 24/08/2026, para que o funil reflita a realidade operacional antes da ativação das validation rules. AC de saída: zero oportunidades abertas em etapa avançada sem Order com mais de 30 dias de parada, confirmado por reexecução das varreduras A e C.

## Queries de reexecução (monitoramento)

As três queries (varreduras A, B e C) estão documentadas na planilha e podem ser reexecutadas mensalmente; a meta é o retorno tender a zero após a ativação das works 1 e 2.
