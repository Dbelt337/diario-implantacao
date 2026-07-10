# Auditoria de Permission Sets — DevSales (resumo executivo)

**Data:** 2026-07-10 · **Fontes:** Q1 inventário (~250 PSs) · Q2 grupos/composição · Q3 assignments · Q4 retrieve XML (32 PSs parseados campo a campo)
**Regra de ouro cumprida:** análise 100% read-only; nenhuma exclusão executada — decisão é do arquiteto.

## Totais
| Categoria | Qtde | Veredicto em bloco |
|---|---|---|
| Estándar/Produto (namespace `force` ou `IsCustom=false`) | ~200 | MANTENER (regra produto) |
| Managed plataforma (`sfdcInternalInt`/`sfdc_*`, Platform Integration User) | 9 | MANTENER (não tocar) |
| **Locais (custom do projeto)** | **26** | analisados 1 a 1 (CSV) |
| Grupos (PSG) | 22, todos de produto | nenhum grupo local existe |

## 🗑️ Candidatas a eliminar (4)
| PS | Motivo | Ação antes de apagar |
|---|---|---|
| `cases_Permisssion_Set` | Herança do org pooled (dez/2025, Juan Juarez/Pooled Org Admin — fora do projeto), typo no nome, 1 userPerm solta | nenhuma |
| `HU010_Campos_SLA_Lead` | 0 assignments; 2 campos do MESMO tema de PS_Lead_SLA_Fields | fundir os 2 campos em PS_Lead_SLA_Fields |
| `Lead_Country_Access` | 0 assignments; micro-PS de 1 campo | mover Lead.Country__c pra PS_Base_Sales_GrupoQ |
| `GQ_Lead_Repuestos_FLS` | só 1 admin (redundante); 4 campos de repuestos | absorver em VendedorRepuestos |

**Caso especial — `PS_OmniChannel_Ventas`:** VAZIA (zero concessões de qualquer tipo no XML) porém **atribuída a 9 usuários** (incl. 3 Agente BDC/AVO). Hoje não concede NADA — os assignments são inócuos. Decidir: dar-lhe o conteúdo previsto (presence/Omni-Channel de ventas?) ou eliminar com os assignments. Não deixar como está.

## 🚨 Bypasses / privilégios sensíveis sem ExpirationDate
| PS | Assignee | Leitura |
|---|---|---|
| `PS_BypassLeadLifecycle` | **Santiago Pelaez (HUMANO)** — sem expiração | **RISCO REAL** — pôr ExpirationDate ou migrar ao integration user |
| `PS_Set_Audit_Fields` | **Diego Beltrão (HUMANO)** — sem expiração | Set Audit Fields deve ser temporal (pós-carga) — pôr data ou retirar |
| `PS_Lead_Dup_Bypass` | Automotive API — sem expiração | ACEITÁVEL por desenho (integration user permanente) — documentado como exceção |
| `PS_Bypass_Gates_Automacao` | Automotive API — sem expiração | ACEITÁVEL por desenho (HU-016) — documentado como exceção |

**Alerta análogo:** `PS_Api` (ApiEnabled + Modify/View All em 6 objetos) está no Automotive API ✅ **e no Vitor Sandy (humano)** ⚠️ — retirar do humano.

## ⚠️ Session-based (HasActivationRequired)
Nenhum PS **local** com a flag ✓ (o alerta da spec para PS_Base_Sales_GrupoQ **não se aplica** — está `false` e compõe grupos normalmente). Os session-based existentes são todos de plataforma (C2C/Cloud Integration User) — corretos.

## 🔁 Sobreposições encontradas
| Par | Situação | Decisão sugerida |
|---|---|---|
| `MDGAprobadorLectura` × `PS_Data_Steward` | 100% dos objetos (Account/Contact) mas CRUD distinto (R vs RUD) | **manter ambos** — papéis diferentes (aprovador vs steward) |
| `HU010_Campos_SLA_Lead` × `PS_Lead_SLA_Fields` | mesmo tema (SLA de Lead), campos disjuntos | **consolidar** num único PS |
| `GQ_Lead_Repuestos_FLS` × `VendedorRepuestos` | mesma persona (repuestos), FLS | **absorver** no VendedorRepuestos |

## ✅ Saúde geral (o que está certo)
- `PS_Base_Sales_GrupoQ`: persona base em uso real e correto (gerentes, BDC/AVO, Vendedor de Repuestos, Automotive API).
- `VendedorRepuestos` + `SparePartsSupervisor` (custom permission **InvoiceCasualCustomer** = gate de facturación do ocasional, HU-014): desenho de personas de repuestos coerente. SparePartsSupervisor aguarda atribuição ao supervisor real.
- `PS_Data_Steward` com 0 assignments é **por desenho** (descrição explícita: atribuição é decisão de negócio MDM).
- Bypasses no integration user (Automotive API) seguem o desenho da HU-016.
- Falsas "vazias" salvas pelo parse profundo: `AccessDevOpsCenterNamedCredentials` (externalCredentialPrincipalAccesses) e `UseSalesManagementAgent` (agentAccesses) — concedem em tags não-óbvias.
- `NextGen_1bYWK…_Permissions`: auto-gerada pelo Agentforce (agente Sales_Concierge_GrupoQ) — não eliminar.

## Observação de método
Atribuições de PSs de FLS a **System Administrators** (`PS_Lead_SLA_Fields`, `GQ_Lead_Repuestos_FLS`) são redundantes — admin já enxerga tudo. O padrão sadio é atribuir às personas de negócio; sugerido corrigir na consolidação.
