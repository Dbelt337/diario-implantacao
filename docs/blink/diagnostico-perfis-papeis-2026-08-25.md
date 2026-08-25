# Blink Telecom (cluster BH) — Diagnóstico de perfis, papéis e permissões

**Data:** 25/08/2026
**Origem:** varredura SOQL na org `blinktelecom` (queries de inventário de User/Profile/UserRole/PermissionSetAssignment), motivada pelo incidente do usuário descongelado + pedido da Lilian (edição do campo Turno pelo perfil Coordenador).

## Números

- **168 usuários ativos** em 14 perfis com uso; **24 perfis sem nenhum usuário ativo** (herança de setup — candidatos a poda).
- Núcleo: Operação Comercial (79), Comercial Community/parceiros (53), Supervisão Comercial (7), Administrador (6), Gerência (5), Coordenação (5).
- Perfil **Atendimento: ~230 usuários, todos desativados** (out–nov/2024). A árvore de papéis de atendimento (Gerente Atendimento → Coordenador → Analistas/Supervisores) está inteira sem usuários ativos.
- 44 papéis, **4 raízes**: CEO, Gerente (TI), Gerente Atendimento (morta), JustWeb (vazia).

## Achados críticos

1. **Integrações com perfil Administrador:** "Integration User" (e-mail mkt.blink@gmail.com) e "Usuário Chatbot" têm perfil Administrador do sistema. Mover para licença Salesforce Integration + Minimum Access API Only + permission set dedicado (padrão que já existe na org).
2. **"PSG Administrador" é um nome enganoso — RESOLVIDO em 25/08.** Inspeção do agregado mostrou todas as permissões de sistema em false (sem Manage Users/Modify All Data) e componentes = **Feature Hubsoft + RT Lead Corporativo/Justweb/Nova/Blink**: é um pacote de record types de Lead multimarca + Hubsoft, não de administração. Os 14 atribuídos (5 perfis admin, os 5 da Coordenação, Isabela/Gerência, 3 externos) carregam acesso a leads, não poderes de admin. Ações: **renomear** para "PSG Leads Multimarca" (nome de permission set é documentação); **não remover** dos coordenadores — é o acesso de trabalho deles; revisar externos sem urgência de segurança. O descongelamento acidental, portanto, ocorreu no período em que a gestão ainda tinha o **perfil** admin (a troca para Coordenador já fechou o buraco) — confirmar autor no SetupAuditTrail e varrer outras fontes com: `SELECT Label, IsOwnedByProfile, Profile.Name FROM PermissionSet WHERE PermissionsManageInternalUsers = true OR PermissionsManageUsers = true OR PermissionsModifyAllData = true`. Lição de playbook: inspecionar conteúdo antes de remover acesso pelo nome — a remoção "óbvia" teria derrubado o acesso a leads de toda a coordenação (mesmo padrão do incidente do Turno).
3. **Usuários de negócio ativos sem papel** (invisíveis na hierarquia — mesmo padrão do caso Adriano/Tayza no cluster): **Thiago Almeida** (Coordenação) e **Mariana Ferreira Venâncio dos Santos** (Operação Comercial). Integrações sem papel estão corretas.
4. **Papéis de parceiro pendurados em papéis de TI:** "Erod Conta pessoal de Parceiro" (22 ativos) sob *Analista de Sistemas*; "lcaet" (23 ativos) sob *Desenvolverdor TI* (typo oficial). TI herda visibilidade de toda a operação de parceiros via hierarquia. Realocar sob "Supervisão de parceiros".
5. **"Never Expires Password" (3 atribuições)** — validar que são apenas usuários de integração.
6. Higiene: duplicados ativos (Stefenson Menezes 2×), e-mails compartilhados (vários usuários com e-mail de thiago.silva@), usernames malformados (`samuelcoelho@...@rnova.com.br`), dezenas de duplicatas `.prod` inativas.
7. **Varredura de permissões perigosas (25/08) — CONFIRMADO: o perfil Gerência é um Administrador do sistema renomeado.** Detalhamento: Gerência e Integrações têm TODAS as permissões (Manage Users, Manage Internal Users, Modify All Data, View All Data, Reset Passwords, Assign Permission Sets); Atendimento (dormente) tem Manage Internal Users + Assign Permission Sets. Total de administradores efetivos: **12** (6 perfil Admin + 5 Gerência + 1 Integrações), sendo 3 integrações. Pool de suspeitos do descongelamento: os 11 humanos com Manage Users. Permission sets avulsos com essas permissões são todos gerenciados pela plataforma (Messaging Bot Admin, E360/C2C, Regrello) — conferir que estão só em usuários de sistema. Correção: remover permissões de gestão de usuários/dados do perfil Gerência (a decisão de negócio já foi tomada ao tirar admin da gestão); necessidades legítimas da gerência (visão ampla) via View All por objeto no PSG Gerencia; "alterar turno" via o mesmo screen flow da coordenação. Query de detalhamento por perfil: `SELECT Profile.Name, PermissionsManageUsers, PermissionsManageInternalUsers, PermissionsModifyAllData, PermissionsViewAllData FROM PermissionSet WHERE IsOwnedByProfile = true AND Profile.Name IN ('Gerência','Integrações','Atendimento')`

## Estado vs. modelo native-first (permission set–led)

A org já tem PSGs por persona — o desenho está meio pronto:

| Persona | Perfil | PSG | Gap |
|---|---|---|---|
| Vendedor (71) | Operação Comercial | PSG Operacao Comercial (77) | — |
| Parceiro (46+) | Comercial Community | PSG Comercial Community (46) | — |
| Supervisão (7) | Supervisão Comercial | PSG Supervisao Comercial (7) | — |
| **Coordenação (5)** | Coordenação | **inexistente** | **única persona sem PSG — a mesma do chamado da Lilian** |
| Gerência (5) | Gerência | PSG Gerencia (4) | 1 usuário fora |
| Admin (4 humanos) | Administrador | PSG Administrador (14!) | limpar excedentes |

## Plano de ação (ordem)

1. Atribuir papel a Thiago Almeida e Mariana F. V. dos Santos.
2. Auditar e limpar PSG Administrador (query acima) e Never Expires Password.
3. Tirar perfil admin das integrações (Integration User, Usuário Chatbot) → Minimum Access API Only + PS.
4. Realocar papéis de parceiro (Erod, lcaet, ddrea duplicado, ljust, lmasc, falva, tsilv) sob Supervisão de parceiros.
5. Criar **PSG Coordenacao Comercial** (incluindo acesso ao flow "Alterar Turno" — solução desenhada em 25/08 para o pedido da Lilian: screen flow em system context, sem Manage Internal Users).
6. Criar **User Access Policies** por persona (critério = perfil; disparo on create/update; Apply Policy manual para o estoque).
7. Poda: perfis sem usuários, árvore de papéis de Atendimento, raiz JustWeb, correção do typo "Desenvolverdor TI".
8. Pendente para fechar o nível 3: rodar `ObjectPermissions` (perfil × objeto) e a query de permissões administrativas (`PermissionsManageUsers`, `PermissionsModifyAllData`...) por perfil.

## Referência

Modelo alvo conforme one-pager `docs/identidade-acessos/provisionamento-perfil-papel-permission-sets.md` (perfil mínimo + PSG por persona + UAP; SCIM/Okta para perfil e papel).
