# Parecer — Sharing/Roles Lead & Opportunity vs Matriz de Perfil v14

Fonte: `GrupoQ_Matriz_Perfil_Funcionalidad_v14` (aprovada pelo cliente — decisões
Juan Carlos 04/05/2026, "no consideren más dudas" 17/04/2026). Cruzada com o
retrieve real da org (Profiles, PermissionSets, Roles, OWD, SharingRules).

## 1. Modelo de segurança APROVADO (matriz)
- **OWD:** Lead Private · Opportunity Private · ApplicationForm Private ·
  FinancialAccount Private. (bate com a org ✅)
- **Duas árvores independentes** sob `GQ_Holding`: **GrupoQ AC** e **CrediQ FSC**,
  sem herança cruzada.
- **Role = escopo de VISIBILIDADE, não função.** Função = Profile + Permission Sets.
- **Por sucursal só 2 roles:** `Ger_Suc` + `Op` (um único role operativo p/ todos
  os perfis da sucursal; diferenciação por Profile+PS).
- **Sharing Rules previstas SÓ para:**
  - **CrediQ → Leads GrupoQ** (Criteria-Based `SR_Lead_CQ_Todos_GQ` + PS
    `PS_VisibilidadLeads_CQ`) — cross-tree.
  - **AC_Calidad** auditoria transversal (Public Group `PG_Calidad` + regra
    "todos os registros" Read-Only em Lead, Opportunity, Account, Vehicle, Asset,
    Case, WorkOrder, ApplicationForm, FinancialAccount).
  - **CrediQ usuários compartilhados** — segregação por sociedade via Sharing
    Rules (validar com Cesar).

## 2. RESPOSTA: precisa montar sharing de Lead/Opp? → NÃO (o básico)
Para visibilidade **dentro do GrupoQ**, a **Role Hierarchy resolve sozinha**
(`Ger_Pais → Ger_Suc → Op`): vendedor vê o dele; gerentes veem para baixo.
**Não é preciso** sharing rule por sociedade/peer — a matriz não pede isso, e a
minha sugestão anterior (regras por `CompanyCode__c`) **NÃO era o desenho correto**.
As únicas sharing rules do projeto são as do item 1 (CrediQ + Calidad), específicas
e já previstas.

## 3. Discrepâncias ORG × MATRIZ v14 (o que AJUSTAR)

### 🔴 A1 — Roles `GQ_Sup_PDV_CR_*` NÃO deviam existir (P1.1)
Decisão do cliente (Juan Carlos 04/05/2026): **"Supervisor NO aprueba descuentos.
39 roles GQ_Sup_PDV_* eliminados. Approval Process via User.ManagerId."** O
supervisor **não é nó da hierarquia** — é um usuário sob `Ger_Suc` com
`User.ManagerId` preenchido para a cadeia de aprovação.
- **Na org existem 7** `GQ_Sup_PDV_CR_*` (Ayarco, Guápiles, LaUruca, Liberia,
  Lindora, PerezZeledón, SanCarlos) — **contra o desenho aprovado.**
- **Isso resolve a discussão do "supervisor não vê os vendedores":** o role
  **não deve existir**. Não é re-parent nem sharing rule → **é DELETAR o role** e
  reatribuir os usuários ao role correto (`GQ_Op_CR_*` ou `GQ_Ger_Suc_CR_*`),
  preenchendo `User.ManagerId`.

### 🔴 A2 — Role `GQ_Valuador_CR` NÃO devia existir (P3.1)
Decisão: **"Tasador NO accede a Salesforce. 6 roles GQ_Valuador_* eliminados."**
O avalúo vem por SAP (agenda no SF → SAP → resultado sincroniza). **Deletar
`GQ_Valuador_CR`.** (PS_Avaluo_Vehiculo_Usado também está OBSOLETO por P3.1.)

### 🟡 A3 — Sucursales faltando na org
A matriz v14 tem ~21 sucursales CR (Trigal, La Sabana, Pinares, Santa Ana,
Cartago, San Pedro, Alajuela, Escazu, Moravia, Heredia, Las Brisas, Desamparados,
Cariari, Grecia, San Pedro…). A org tem só **7**. Confirmar se as demais entram
neste ambiente (senão, usuários dessas sucursales ficam sem role → perdem
visibilidade no go-live).

### 🟡 A4 — Nós de topo faltando
Matriz v14 tem `GQ_VP_Comercial` e `GQ_VP_Postventa` (entre CEO e Regional) para
a cadeia de aprovação de 4 passos. Confirmar se existem na org.

### 🟡 A5 — Árvore CrediQ ausente
Matriz define a árvore paralela CrediQ (`CQ_*` / `CrediQ_*`, 19 roles) sob
`GQ_Holding`. Não veio no retrieve. Se CrediQ está no escopo desta fase, faltam.

## 4. Ação imediata (destrava o teste em andamento)
1. **Deletar os 7 `GQ_Sup_PDV_CR_*`** → reatribuir usuários ao role correto +
   preencher `User.ManagerId`. (Resolve o "supervisor não vê"; ele nunca deveria
   ver por role — a supervisão é por ManagerId no Approval Process.)
2. **Deletar `GQ_Valuador_CR`.**
3. Lead/Opp **não precisa** de sharing rule nova. As únicas a criar (quando CrediQ
   e Calidad entrarem) são as do item 1.

## 5. Flag adicional (do retrieve, a validar)
`PS_OmniChannel_Ventas` concede **View All + Modify All em Opportunity** — quem
tiver esse PS vê TODAS as opps (fura o Private). Confirmar se é intencional (ex.:
roteamento) ou sobre-exposição. Não está descrito assim na matriz.
