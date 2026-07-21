# Runbook — Limpeza de Roles (alinhar org à Matriz v14)

Remove os roles criados fora do desenho aprovado (Supervisor PDV e Valuador).
Base: `PARECER-MATRIZ-v14.md` (decisões Juan Carlos 04/05/2026).

## Decisão a confirmar ANTES
Destino de cada usuário hoje em `GQ_Sup_PDV_CR_*`:
- Supervisor vê a sucursal inteira → `GQ_Ger_Suc_CR_[sucursal]`.
- Supervisor vê só o próprio → `GQ_Op_CR_[sucursal]`.
Regra prática: encargado que supervisiona o PDV → `Ger_Suc`.

## Passo 0 — Levantar usuários afetados
```sql
SELECT Id, Name, Username, UserRole.DeveloperName, IsActive
FROM User
WHERE UserRole.DeveloperName LIKE 'GQ_Sup_PDV_CR_%'
   OR UserRole.DeveloperName = 'GQ_Valuador_CR'
ORDER BY UserRole.DeveloperName
```

## Passo 1 — Reatribuir usuários do Sup_PDV
Setup → Users → usuário → campo Role → role destino (mesma sucursal) → Save.
(Em lote: Data Loader no User, campo `UserRoleId`.)

## Passo 2 — Deletar os 7 roles Sup_PDV
Setup → Roles → Del em:
GQ_Sup_PDV_CR_Ayarco, _Guapiles, _LaUruca, _Liberia, _Lindora,
_PerezZeledon, _SanCarlos. (roles-folha, deleção direta.)

## Passo 3 — Valuador
- Usuários que são tasadores → desativar/remover licença (P3.1: não acessa SF).
- Mal-atribuídos → mover para `GQ_Op_Usados_CR`.
- Setup → Roles → Del em `GQ_Valuador_CR`.

## Passo 4 — User.ManagerId
Para cada vendedor, setar Manager apontando ao supervisor/gerente responsável
(o Approval Process de desconto usa ManagerId no lugar do role Sup_PDV).
Setup → Users → Manager → Save. (Em lote: Data Loader, `ManagerId`.)

## Passo 5 — Validar
```sql
SELECT DeveloperName FROM UserRole
WHERE DeveloperName LIKE 'GQ_Sup_PDV_CR_%' OR DeveloperName = 'GQ_Valuador_CR'
-- deve voltar 0
```
```sql
SELECT Id, Name FROM User WHERE IsActive = true AND UserRoleId = null
-- ninguém pode ficar sem role
```
Teste: Gerente de Sucursal vê leads/opps dos vendedores da sucursal ✅;
vendedor vê só os dele.

## Sharing rules Lead/Opp
NÃO criar nada. A Role Hierarchy resolve. Únicas regras do projeto: CrediQ→Leads
e AC_Calidad (só quando esses módulos entrarem).

## Ajustes maiores pendentes (não bloqueiam o teste — confirmar escopo)
- A3: sucursales CR faltando (matriz ~21, org 7).
- A4: GQ_VP_Comercial / GQ_VP_Postventa.
- A5: árvore CrediQ (19 roles).
- Flag: `PS_OmniChannel_Ventas` dá View All/Modify All em Opportunity — validar.
