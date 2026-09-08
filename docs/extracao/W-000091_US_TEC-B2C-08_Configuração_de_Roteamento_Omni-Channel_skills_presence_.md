# W-000091 — US TEC-B2C-08 — Configuração de Roteamento Omni-Channel (skills, presence e filas regionais)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:40 por Diego Beltrão de Moraes | Alterado: 31/08/2026 19:40 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

Narrativa: Como time de implantação, quero o motor de roteamento Omni-Channel configurado com filas regionais, habilidades e status de presença, para a distribuição de leads e atendimentos da jornada B2C ocorrer por skill e região sem intervenção manual (fundação exigida pela US-03 / B2C-01).

Abordagem native first: o Omni-Channel roteia Lead nativamente como work item (documentação oficial lista cases, leads, chats e objetos custom), sem código.

Escopo técnico:
- Routing Configurations e filas regionais B2C, com de/para região x fila alinhado ao comercial
- Skills (região, produto, canal) e atribuição de skills aos agentes
- Skill Mapping Sets traduzindo valores de campo do Lead (região, canal) em habilidades requeridas para o skills-based routing
- Presence Statuses e configuração de capacidade por agente
- Painel do supervisor Omni para as coordenações regionais

Dependências: definição oficial de regiões e filas com o comercial; TEC-B2C-07 (perfis e permissões dos agentes).

## Critérios de Aceite (related list)

**1. Cenário 3: Visão do supervisor** (New)
Dado um coordenador regional com acesso de supervisor
Quando ele abre o painel do Omni
Então enxerga as filas, os agentes, os status de presença e os tempos de espera da sua regional

**2. Cenário 2: Sem agente disponível** (New)
Dado que nenhum agente da fila está online ou com capacidade
Quando um lead chega
Então ele permanece na fila sem atribuição e é distribuído automaticamente assim que houver presença disponível, sem perda ou desvio de fila

**3. Cenário 1: Roteamento por região e skill** (New)
Dado um lead qualificado de uma região atendida
Quando o roteamento Omni-Channel executa
Então o lead entra na fila regional correta e é atribuído a um agente disponível com a skill daquela região, respeitando a capacidade configurada
