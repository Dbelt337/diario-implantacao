# Guia de Deploy — HU `Lead.Country__c` (conversão de Lead)
Promoção DevSales → UAT → Produção. Formato Traditional (Metadata API), Check Only antes.

## A) Pré-deploy — VERIFICAR no ambiente destino (Fase 0 por ambiente)
Nada disto está no pacote; confirmar ANTES para não quebrar:
1. **`Account.Country__c` (destino):** listar os valores de API e confirmar que são **idênticos** aos que vamos deployar em `Lead.Country__c` (byte a byte, incl. `PA Panamá` com acento). Se o destino tiver valores diferentes, ajustar o clone antes.
2. **`Lead.CompanyCode__c` (destino):** listar os valores da picklist. Cada valor precisa ter registro correspondente no `Sociedad_Config__mdt` (senão o país não carimba). Em DevSales são 13: C101, C105, G101, G105, H101, H105, N101, N105, P101, P105, S101, S105, S206.
3. **`User.Sociedad__c`** existe no destino (o flow usa no fallback).
4. **`Lead_Routing_Config__mdt`** tem o registro `Default` com `Default_Sociedad__c` (fallback do flow).
5. **`Sociedad_Config__mdt`** existe com os registros; se faltar `G105`/`P103`, criar (scripts prontos).
6. **Setting** "Deploy processes and flows as active" (Process Automation Settings) — se OFF, o flow vem Inactive e precisa ativar manual.
7. **Validation rule** "Para calificar/convertir el lead debe registrar: nombre, teléfono/correo, fecha estimada de compra" — é pré-existente (não é desta HU); confirmar que existe no destino (afeta a UX da conversão, mas não é nosso build).

## B) Componentes de metadata a deployar
1. **Value set do `Lead.Country__c`:**
   - **Opção recomendada (consistência com DevSales):** manter como está em DevSales. Se for **Global Value Set "País"**, deployar o `GlobalValueSet País` + o campo. Se for **local**, o campo já é self-contained.
   - Obs: a conversão pela tela padrão funcionou com o Lead em **GVS** e Account **local** — então GVS↔local **não** foi bloqueio. Só garantir **paridade de valores** entre os dois.
2. **`Lead.Country__c`** (campo).
3. **`Sociedad_Config__mdt.Country_Picklist_Value__c`** (campo Text 40).
4. **Flow `Lead_BS_DeriveSociedad`** (versão evoluída: entry `CompanyCode__c IsNull OR Country__c IsNull`; assignments em `CompanyCode__c`; ramo que carimba `Country__c` via CMT).
5. **Permission set `Lead_Country_Access`** (FLS do `Country__c`) — ou setar FLS direto nos perfis.

## C) Passos que NÃO vão no metadata (manual / dados) — fazer em CADA ambiente
6. **Registros de CMT** (`Sociedad_Config__mdt`):
   - Criar `G105` (clone de G101) e `P103` (clone de P105) se não existirem — `Criar_G105_CMT.apex` / `Criar_P103_CMT.apex`.
   - **Popular** `Country_Picklist_Value__c` nos registros — `Popular_CMT_Country.apex` (14 valores). **Pré-requisito do carimbo automático.**
   - ⚠️ Ajustar o **prefixo de namespace** no `fullName` do Apex se o CMT tiver namespace no destino.
7. **Map Lead Fields:** Object Manager → Lead → Fields → *Map Lead Fields* → aba **Account** → `País (Country__c)` → `Country__c` (Account) → Save.
   - Recomendo **manual na UI** (é 1 mapeamento). Deployar `LeadConvertSettings` por pacote **sobrescreve** todos os mapeamentos existentes — só use se tiver o LeadConvertSettings completo do destino.
8. **Atribuir** o permission set `Lead_Country_Access` aos perfis de Vendas + **Integration User**.

## D) Ordem de execução
Campos (+ GVS, se aplicável) → campo do CMT → **criar/popular registros CMT** → flow → Map Lead Fields → FLS/atribuição.

## E) Pós-deploy — testes de aceite
1. Criar Lead com `CompanyCode__c=C101` → `Country__c = "CR Costa Rica"` carimbado no **save** (valida flow + CMT).
2. Um lead por país (P101/P103/P105 → `PA Panamá` com acento).
3. **Converter pela tela padrão "Convert"** (Create New Account) → **sem** erro de field mapping; `Account.Country__c` = valor do Lead.
4. Converter para **conta existente** → valor da conta preservado.
5. Confirmar no Flow Builder que a versão **Active** do `Lead_BS_DeriveSociedad` é a evoluída (tem "Assign Country").

## F) Rollback
- **Flow:** reativar a versão anterior do `Lead_BS_DeriveSociedad` (anotar a versão ativa antes do deploy).
- **Campo/mapping:** o campo é aditivo; se preciso, remover o mapping em Map Lead Fields. CMT: o campo novo é aditivo.

## G) Riscos / observações (documentar)
- **Escopo GO-FORWARD (sem backfill):** leads **novos** nascem com país; leads **antigos** ganham ao serem **salvos** (entry pega `Country__c` vazio). Não há update em massa. Lead antigo sem país → **Create New Account** bloqueia (Account.Country__c obrigatório); converter pra **conta existente** funciona, ou preencher o país no lead.
- **Backlog de SLA:** leads antigos com ação time-based pendente (`Lead_SLA_Escalation`) dão "in use by workflow" na conversão até o Status sair de "Nuevo" ou a ação disparar. **Dependência:** o **ajuste do `Lead_SLA_Escalation`** (entry `Status=Nuevo` + `doesRequireRecordChangedToMeetCriteria`) precisa estar no destino para novos leads não repetirem o problema.
- **Máquina de estados de Status** (`Lead_BS_TransicionEstado`): transições são restritas (ex.: `Nuevo → Asignado` bloqueada). Considerar ao mudar Status via automação/Apex.
- **Governança de valores:** país novo deve ser adicionado em **`Lead.Country__c`**, **`Account.Country__c`** E no `Country_Picklist_Value__c` do CMT (documentado no help text dos campos).
- **`Default_Queue_Prefix__c` do G105** foi herdado de G101 (= `Leads_G101`) na clonagem — não afeta o país, mas se G105 tiver fila própria, revisar (pode impactar roteamento).
