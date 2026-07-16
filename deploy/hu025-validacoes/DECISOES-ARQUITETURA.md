# Log de decisões de arquitetura (Nativo / GAP / Dependência)

Rubrica: ver PRINCIPIOS-ANALISE.md. Veredito: ✅ Nativo · ⚠️ Parcial · ❌ GAP · 🔌 Dependência.

---

## HU-025 — Conversão Lead→Opp (produto + vendedor)
✅ **RESOLVIDA.** Transformação nativa (ObjectHierarchyRelationship) cria
OpportunityLineItem e OpportunityPreferredSeller na conversão. Ver
NOTAS.md e HANDOFF-PROXIMOS-AMBIENTES.md.

## HU-042 — Cenários de cotação
| # | Cenário | Veredito | Base |
|---|---|---|---|
| 1 | Múltiplas unidades da mesma marca | ✅ Nativo | Vários line items numa cotação |
| 2 | Enviar cotação por WhatsApp | ✅ Nativo | Digital Engagement (licença confirmada); link do Quote PDF ou documento no canal Messaging |
| 3 | Anexar ficha técnica + enviar junto | ✅ Nativo | Files + Quote PDF por e-mail/WhatsApp. GAP só se exigirem PDF único mesclado (doc-gen) |
| 4 | Cotação multimarca (Chevrolet + Hyundai) | ✅ Nativo | Price Book é por **país/sociedade**, contém todas as marcas → cabem na mesma cotação. Limite: não misturar produtos de **países diferentes** (books diferentes) |

## HU-044 — Criação da cotação com stock
✅ Fluxo correto. **OmniScript (Standard Runtime)** como container; Integration
Procedure → MuleSoft → SAP nos passos de disponibilidade/preço. Decidir usar o
objeto **Quote nativo** (recomendado, para enviar ao cliente). Passos de
SAP/preço (H7) 🔌 dependência — montar shell nativo agora, ligar integração
quando o contrato sair.

## HU-030 — Repuestos / PA (peças)
| # | Ponto | Veredito | Base |
|---|---|---|---|
| 1 | Integração catálogo montadora | 🔌 Dependência | MuleSoft Accelerator for SAP (Product/Availability). Sprint 3 sem integração: modelo + catálogo seed + busca sobre cache |
| 2 | Resolução VIN→peças | ❌/🔌 GAP de dado | Compatibilidade é dado OEM. VIN→VehicleDefinition nativo; VehicleDefinition→peça via tabela de compatibilidade carregada |
| 3 | Modelo de dados do veículo | ✅ Nativo | **Vehicle + Asset + AssetAccountParticipant**; Asset.VehicleId + participante → Person Account mostra VINs. Falta **carregar** os dados |
| 4 | Visibilidade cross-sociedade x segurança | ✅ Nativo (padrão) | **Inventário read-only visibilidade ampla** (OWD Public Read) OU query real-time SAP; comercial segue seguro por sociedade |
| 5 | Determinação do preço | ✅/🔌 | **PA → Price Book nativo**; **Repuestos → callout real-time SAP** (dinâmico). Price Book padrão só p/ PA |
| 6 | Disponibilidade informativa x transacional | ✅ Confirmado | Identificação = read-only via MuleSoft; validação transacional = real-time no fechamento (decisão Felipe) |
| 7 | Sincronização e modo degradado | 🔌 Dependência | Cache no SF: materiais/preços de referência/disponibilidade básica (diário) + real-time só no commit. SAP fora → cache com flag e bloqueia só o commit |

## HU-039 — Criação/extensão de material (master data SAP)
| # | Ponto | Veredito | Base |
|---|---|---|---|
| 1 | Automático vs solicitação | 🔌/⚠️ | Automático via integração se regra determinística; senão solicitação + aprovação. Depende da **governança de master data** do GrupoQ |
| 2 | Modelagem (Case vs objeto custom) | ✅ Nativo | **Case + Record Type "Solicitação de Material" + Entitlements/Milestones** (SLA, fila, auditoria nativos). Objeto custom só se muitos campos estruturados |
| 3 | Usuários sem licença SF (inventário/almoxarifado) | ✅ (padrão integração) | Atuam **no SAP**; SF cria a solicitação e o status volta automático via MuleSoft (**closed-loop**), fecha o Case |

## Transversais
- **Assinatura digital:** ❌ **fora do nativo.** Requer **DocuSign** ou **Adobe
  Acrobat Sign** (add-on pago) para e-signature legal; ou elemento **Signature
  do OmniScript** para aceite simples (sem valor legal/auditoria). Item separado.
- **Inventário/estoque (todas as HUs):** 🔌 MuleSoft/SAP. Padrão: cache diário
  (status básico) + validação real-time no fechamento. Reusar aceleradores Mule.
- **Preço por sociedade/país:** ✅ Price Book por sociedade (multimoeda). C101
  Costa Rica montado; futuros HN/GT/SV mesma lógica.
