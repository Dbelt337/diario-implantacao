# HU-009 — Hand-off Digital → Sucursal · Registro para o DLG

**Org validada:** DevSales · **Data:** 11/07/2026 · **Autor:** Diego Beltrão · **Idioma/convención:** inglês técnico + PascalCase (GRPQM Naming Conventions)

---

## 1. Componentes para registrar no DLG

### Campos novos (CustomField)
| API Name | Objeto | Tipo | Propósito |
|---|---|---|---|
| `OriginatingDigitalAdvisor__c` | Opportunity | Lookup(User) | Asesor digital que originou a Opp; estampado pelo flow no 1º agendamento presencial, imutável (rastreabilidade de comissão) |
| `HandOffDate__c` | Opportunity | DateTime | Momento do Recibir Cliente |
| `HandOffStatus__c` | Opportunity | Picklist restrita (Sin hand-off / Pendiente Recepción / Recibido), **field history ON** | Estado operativo do hand-off |
| `BranchCode__c` | Activity (visível em Event) | Picklist restrita — 8 sucursales de ventas CR (`CR_URUCA`, `CR_LIBERIA`, `CR_SANCARLOS`, `CR_LINDORA`, `CR_AYARCO`, `CR_SANTAANA`, `CR_GUAPILES`, `CR_PEREZZELEDON`) | Sucursal da atividade presencial; **contrato do sharing** (valor = código do grupo) |
| `VisitStatus__c` | Activity | Picklist restrita (Pendiente/Atendida/No Show/Cancelada/Reprogramada) | Estado da visita |
| `ServiceAppointmentId__c` | Activity | Text(18) externalId | Chave do espelho Test Drive (Parte D, futuro) |

Alteração de objeto: **Opportunity `enableHistory=true`** (+ Owner marcado no Set History Tracking — manual).

### Automação (Flow)
| API Name | Tipo | Gatilho/Modo | Função |
|---|---|---|---|
| `Event_AfterSave_ShareBranchHandOff` | Record-Triggered (after save, Create+Update, order 10) | Event com `BranchCode__c` preenchida e WhatId = Opportunity | Cria `OpportunityShare` (Read, RowCause **Manual**) para o grupo `GRP_Sucursal_[code]`; estampa asesor originador (1ª vez) e `HandOffStatus=Pendiente Recepción`; grupo inexistente → Task de log |
| `Opportunity_Screen_ReceiveCustomer` (label "Recibir Cliente") | Screen Flow | **System Mode Without Sharing** (decisão: cobre Escenario 10 — walk-in sem share prévio — e dispensa Transfer Records) | Troca Owner p/ asesor presencial, estampa `HandOffDate` + `Recibido`, marca visita pendente como Atendida |

**Mecanismo-chave (anotar no DLG):** o share usa RowCause `Manual` de propósito — a plataforma o **apaga nativamente na troca de Owner**. A "limpeza automática de acesso" do refinamento é nativa, sem flow de remoção.

### Demais componentes
| Componente | Tipo | Observação |
|---|---|---|
| `Opportunity.ReceiveCustomer` (label "Recibir Cliente") | QuickAction (Flow) | Na page layout da Opportunity (manual) |
| `GRP_Sucursal_CR_*` (8) | Public Group | Membros = recepcionistas/hosts por sucursal (dado, não metadado) |
| `GRP_Sucursal_SV_AUTOSUR` / `SV_SANTAELENA` | Public Group | Pré-criados p/ rollout El Salvador |
| `PS_Base_Sales_GrupoQ` | PermissionSet (atualizado) | +FLS dos 6 campos novos |
| `Admin` | Profile (atualizado) | FLS dos campos novos (campos via API não concedem FLS a ninguém) |

### Eliminados / decisões registradas
- `Lead.ChannelCode__c` e `Opportunity.ChannelCode__c` **eliminados** — origem do lead = **LeadSource nativo** (vendedor escolhe; middleware mapeia `channelCode`→LeadSource; conversão copia nativa). Pendência integração: validation rule limitando LeadSource ao catálogo em criações via API.
- GVS `ChannelCode__gvs` órfão — **pendente de exclusão** (zip Cleanup pronto).
- Lead Conversion Mapping para canal: **não é mais necessário**.
- OWD Opportunity na DevSales = Public Read Only → sharing é redundante NESTA sandbox; desenho pressupõe **Private** (produção). Não alterar OWD na sandbox compartilhada.

---

## 2. Plano de testes (roteiro completo em `testes/roteiro_testes_HU009_AB.md`)

### Executados e verdes (11/07, DevSales)
| # | Cenário | Resultado |
|---|---|---|
| T1 | Event com sucursal → estampa + share `Sucursal Uruca (CR)`/Read/Manual | ✅ |
| T3 | Troca de Owner → share Manual desaparece sozinho (cleanup nativo) | ✅ |
| T4 | 2º hand-off não sobrescreve o Asesor Originador | ✅ |
| T5 | Código sem grupo → Task de log "branch group missing", sem quebrar | ✅ |
| C | Recibir Cliente: Owner trocado, `Recibido`, `HandOffDate` estampada | ✅ |
| E10 | Walk-in (Opp sem Event) recebido via System Mode | ✅ |

### Pendentes
| # | Cenário | Condição |
|---|---|---|
| T2 | Recepcionista (só membro do grupo) enxerga a Opp compartilhada e perde acesso após o hand-off | **Requer OWD Private** → validar em QA/UAT que espelhe produção |
| T6 | Event em Account (não-Opp) → flow ignora | rápido, DevSales |
| T7 | Sucursal preenchida depois (update) dispara o flow | já provado indiretamente |
| T8/T9 | LeadSource na criação manual + cópia nativa na conversão | rápido, DevSales |
| T10 | Field history: `HandOffStatus` e Owner com autor/data | rápido, DevSales |
| — | Visita marcada Atendida pelo Recibir Cliente (caso com Event) | rápido, DevSales |
| — | List view "Visitas pendientes de mi sucursal" filtrando por `BranchCode` + `VisitStatus=Pendiente` | criar view (manual) |

---

## 3. Visibilidade do botão "Recibir Cliente"

**Quem DEVE ver/executar (do refinamento):**
| Persona | Vê o botão | Motivo |
|---|---|---|
| **Recepcionista / Host da sucursal** | ✅ | É quem executa o hand-off na chegada do cliente |
| **Gerente de Ventas da sucursal** | ✅ | Respaldo operativo (sucursal sem recepcionista / ausência — cenário do refinamento) |
| Asesor digital / vendedores | ❌ | Não recebem cliente; o botão não faz parte do fluxo deles |
| Admin | ✅ | Suporte |

**Mecanismo (mesmo padrão do `InvoiceCasualCustomer` da HU-014):**
1. **Custom Permission `ReceiveCustomer`** — o gate.
2. **Permission Set `PS_Branch_Reception`** (persona recepcionista/gerente): concede a custom permission, o acesso de execução ao flow e FLS de leitura dos campos de hand-off. Atribuir às recepcionistas e gerentes das sucursales do piloto.
3. **Dynamic Actions na record page da Opportunity** (manual): Lightning App Builder → Highlights Panel → "Upgrade to Dynamic Actions" → adicionar a action **Recibir Cliente** com **visibility rule** `$Permission.ReceiveCustomer = true`. Assim o botão some para quem não tem o gate — em vez de todo mundo ver e tomar erro.
4. (Reforço opcional) No flow, ativar "Override default behavior → restrict access to enabled profiles or permission sets" — o PS já carrega o flowAccess.

**Nota de risco (System Mode):** o flow roda em system context por desenho; o gate acima é o que impede uso indevido. Botão visível = pessoa autorizada.
