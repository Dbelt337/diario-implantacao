# HU-009 — Runbook de Implantação (config + testes + deploy)

**Atualizado:** 11/07/2026 · Pacote de promoção: `deploy/hu009_promote/HU009_Promote.zip` (27 arquivos, estado final consolidado)

---

## 1. O QUE LEVAR NO DEPLOY — `HU009_Promote.zip`

Um único zip com o estado final (sem destructive — para org limpa/QA/UAT):

| # | Componente | Tipo |
|---|---|---|
| 1 | `Opportunity` (`enableHistory` + `OriginatingDigitalAdvisor__c`, `HandOffDate__c`, `HandOffStatus__c`) | CustomObject/CustomField |
| 2 | `Activity.BranchCode__c` (picklist 8 sucursales CR), `VisitStatus__c`, `ServiceAppointmentId__c` | CustomField |
| 3 | `GRP_Sucursal_CR_*` (8) + `GRP_Sucursal_SV_*` (2) | Group |
| 4 | `Event_AfterSave_ShareBranchHandOff` (ativo) | Flow |
| 5 | `Opportunity_Screen_ReceiveCustomer` v1.1 (ativo, System Mode Without Sharing) | Flow |
| 6 | `Opportunity.ReceiveCustomer` ("Recibir Cliente") | QuickAction |
| 7 | `ReceiveCustomer` | CustomPermission |
| 8 | `PS_Base_Sales_GrupoQ` (FLS dos 6 campos) ⚠️ | PermissionSet |
| 9 | `PS_Branch_Reception` (gate + flowAccess + FLS) | PermissionSet |
| 10 | `Admin` (FLS dos campos) | Profile |
| 11 | `EventSubject` (assuntos padrão: Visita al Showroom, Test Drive, Avalúo/Trade-In, Entrega de Vehículo, Firma de Documentos + os 5 standard) | StandardValueSet ⚠️ |

**Opções do Workbench:** Single Package ✅ · Check Only ☐ · Rollback on Error ✅ (sem destructive, pode ser atômico) · Ignore Warnings desnecessário.

**⚠️ Cuidados na promoção:**
- **PS_Base_Sales_GrupoQ é full-replace**: o arquivo carrega o estado da DevSales. Se o PS da org destino divergiu, fazer retrieve lá antes e mesclar o FLS dos 6 campos, em vez de sobrescrever cego.
- Grupos vão vazios (membro é dado, não metadado).
- Pré-requisito de org destino: **OWD de Opportunity = Private** para o sharing ter efeito real. ✅ APLICADO na DevSales em 11/07 (Lead Private + Opportunity Private; Account mantido Public Read/Write por decisão — apertar para Read Only quando o negócio referendar). QA pendente: Lead ainda ReadWriteTransfer.
- **StandardValueSet substitui a lista inteira**: antes de promover, conferir os valores atuais de EventSubject na org destino (Object Manager → Event → Subject) e mesclar no arquivo se houver valores locais que não estejam nele.
- NÃO levar: nada de ChannelCode (eliminado — origem é LeadSource nativo), campos em espanhol (extintos), GVS `ChannelCode__gvs` (órfão, pendente de delete até na DevSales).

---

## 2. CONFIGURAÇÃO MANUAL (por org, na ordem — o deploy sozinho não basta)

| # | Configuração | Onde | Status DevSales |
|---|---|---|---|
| C1 | **Owner** marcado no Set History Tracking | Object Manager → Opportunity → Fields → Set History Tracking | ⏳ conferir |
| C2 | Campos no **page layout da Opportunity** (`Asesor Digital Originador`, `Fecha de Hand-Off`, `Estado Hand-Off` — sugestão: seção "Hand-Off Digital") | Object Manager → Opportunity → Page Layouts | ✅ |
| C3 | `Sucursal` + `Estado de la Visita` no **page layout do Event** | Object Manager → Event → Page Layouts | ✅ |
| C4 | `Sucursal` (+ `Estado de la Visita`) no **layout da Global Action "New Event"** — o compositor da aba Activity usa layout próprio; F5 depois de salvar | Setup → Global Actions → New Event → Layout | ⏳ |
| C5 | Action **Recibir Cliente** na record page da Opportunity via **Dynamic Actions** com visibility rule `$Permission.ReceiveCustomer = true` | Lightning App Builder → Highlights Panel → Upgrade to Dynamic Actions | ⏳ (hoje está no layout clássico, visível a todos) |
| C6 | **Atribuir `PS_Branch_Reception`** a recepcionistas/hosts + gerentes de ventas do piloto | Permission Sets → Manage Assignments | ⏳ |
| C7 | **Membros nos grupos** `GRP_Sucursal_CR_*` (recepcionistas de cada sucursal) | Setup → Public Groups | ⏳ |
| C8 | **List view de Events** "Visitas pendientes — [sucursal]": filtros `Sucursal = <código>` + `Estado de la Visita = Pendiente` (uma por sucursal do piloto) | Aba/console de Activities ou Calendar list | ⏳ |

Sem C6+C7 o botão não aparece para a recepção e a sucursal não recebe o share — são os dois passos que "ligam" o processo.

### Visibilidade do botão × perfis do blueprint (decisão 11/07)
O blueprint aprovado (AC_*) **não tem perfil de Recepcionista** — recepção é FUNÇÃO, não família: perfil base `AC_Vend_Veh` + `PS_Branch_Reception` por cima (mesmo padrão do InvoiceCasualCustomer/HU-014). A visibility rule é `$Permission.ReceiveCustomer` — independente de perfil.

| Perfil | Vê o botão | Como |
|---|---|---|
| Recepcionista/Host (base AC_Vend_Veh) | ✅ | PS_Branch_Reception |
| AC_Ger_Suc (respaldo do refinamento) | ✅ | PS_Branch_Reception |
| AC_Admin | ✅ | atribuir o PS (suporte) |
| Demais (AC_Vend_Veh sem PS, AC_Ger_Ven, AC_BDC_Ag, AC_Vend_Rep, AC_Sup_Rep, AC_Fleet, AC_Exec_Serv, AC_Calidad) | ❌ | — |

Auditoria de "quem recebe cliente": `SELECT Assignee.Name, Assignee.Profile.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'PS_Branch_Reception'`

---

## 3. TESTES

### ✅ Já validados na DevSales (11/07)
| # | Cenário |
|---|---|
| T1 | Event com sucursal → `Pendiente Recepción` + asesor estampado + share `Read/Manual` com o grupo |
| T3 | Troca de Owner → share Manual removido nativamente |
| T4 | 2º hand-off não sobrescreve o Asesor Originador |
| T5 | Código sem grupo → Task de log, processo não quebra |
| PC | Recibir Cliente: Owner trocado, `Recibido`, `HandOffDate` estampada |
| E10 | Walk-in (Opp sem Event) recebido via System Mode |

### ⏳ Fazer na DevSales (rápidos, pós-config)
| # | Cenário | Como |
|---|---|---|
| V1 | **Gate do botão**: usuário SEM `PS_Branch_Reception` não vê "Recibir Cliente"; COM o PS, vê e executa | após C5+C6, Login As |
| V2 | **Visita Atendida**: Recibir Cliente numa Opp COM Event pendente → `VisitStatus = Atendida` | criar Event antes |
| V3 | **List view** mostra só as visitas pendentes da sucursal | após C8 |
| V4 | **Assuntos padrão**: dropdown do Subject no New Event mostra "Visita al Showroom", "Test Drive" etc. | após deploy do SVS |
| T6 | Event em Account (não-Opp) → flow ignora | 1 min |
| T8/T9 | LeadSource escolhido no Lead manual → copia nativo para a Opp na conversão | 2 min |
| T10 | Field history mostra mudanças de `Estado Hand-Off` e Owner com autor/data | após C1 |

### 🔜 Somente em QA/UAT (OWD Private)
| # | Cenário |
|---|---|
| T2 | Recepcionista (apenas membro do grupo, sem outros acessos) **não vê** a Opp antes do agendamento → **vê** após o share → **perde acesso** após o Recibir Cliente. ✅ TESTÁVEL NA DEVSALES desde 11/07 (OWD virado para Private). |
| REG | Regressão do ciclo completo com perfis reais de recepcionista/gerente |

---

## 4. Pendências fora do escopo do deploy (backlog registrado)
- Parte D — espelho do Test Drive (Scheduler→Event): depende do cadastro ServiceTerritory/sucursales (inventário Modelo B: 4 queries pendentes).
- Faxina: GVS `ChannelCode__gvs` órfão (zip Cleanup pronto), campo fantasma `CanalOriginador__c` (conferir dados), artefatos HU-009 na org errada de 10/07.
- Integração: validation rule limitando `LeadSource` ao catálogo nas criações via API (go-live do middleware).
