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
2. **PSG Administrador com 14 atribuições ativas vs. 6 admins** — 8 não-admins com pacote de admin via permission set. Provável resquício do período "gestão toda com admin": redefiniram o perfil, o PSG ficou. Verificar com:
   `SELECT Assignee.Name, Assignee.Profile.Name FROM PermissionSetAssignment WHERE PermissionSet.Label = 'PSG Administrador' AND Assignee.IsActive = true`
3. **Usuários de negócio ativos sem papel** (invisíveis na hierarquia — mesmo padrão do caso Adriano/Tayza no cluster): **Thiago Almeida** (Coordenação) e **Mariana Ferreira Venâncio dos Santos** (Operação Comercial). Integrações sem papel estão corretas.
4. **Papéis de parceiro pendurados em papéis de TI:** "Erod Conta pessoal de Parceiro" (22 ativos) sob *Analista de Sistemas*; "lcaet" (23 ativos) sob *Desenvolverdor TI* (typo oficial). TI herda visibilidade de toda a operação de parceiros via hierarquia. Realocar sob "Supervisão de parceiros".
5. **"Never Expires Password" (3 atribuições)** — validar que são apenas usuários de integração.
6. Higiene: duplicados ativos (Stefenson Menezes 2×), e-mails compartilhados (vários usuários com e-mail de thiago.silva@), usernames malformados (`samuelcoelho@...@rnova.com.br`), dezenas de duplicatas `.prod` inativas.

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
