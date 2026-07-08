# HU-010 — Handoff / Ponto de parada
> Última sessão: 2026-07-08 · sandbox `grupoq--devsales`. Solução implantada e validada na org.

## 1. Estado geral: ✅ RESOLVIDA e validada com dado real
Todos os requisitos da HU-010 estão entregues, declarativos (zero Apex). Falta apenas
**1 decisão de negócio em aberto** (ver §5) e itens operacionais de deploy em outros ambientes.

| Requisito | Como | Status |
|---|---|---|
| SLA 1º contato + data/hora | `SLADeadline__c` (existente) + escada | ✅ validado |
| Escada (recordatório −15 / supervisor / reasignación +10) | `Lead_SLA_Escalation` (scheduled paths) | ✅ **validado ao vivo** |
| "Gestión" válida | Task completada → `FechaPrimerContacto__c` | ✅ validado (ver §5: pode evoluir) |
| Cumpriu SLA | `CumplioSLA__c` (fórmula) | ✅ validado (calcula true/false certo) |
| Temperatura → Rating | `Lead_Score_Temperatura` (before-save + Einstein) | ✅ Active |
| **Priorización calientes** | **`acceptBy`→`TargetAcceptDateTime` na Route Work skills do `LeadRouting_OmniFlow`** | ✅ **validado ao vivo** |
| Sticky-agent por presença | `LeadRouting_OmniFlow` (afinidade owner+skill+online) | ✅ nativo (já existia) |

## 2. A grande correção desta sessão (priorización)
A abordagem original (flow `Lead_PSR_SecondaryPriority` record-triggered **after-save no PSR**)
**NÃO funciona** e foi **descartada**. Motivos comprovados na doc + org:
- PSR trava em `IsReadyForRouting=true` → não aceita `update`.
- Em queue-based, o PSR "doesn't invoke triggers".
- `RoutingPriority`/`SecondaryRoutingPriority` **não são inputs** da Route Work action.

**Solução final:** a priorización vive dentro do `LeadRouting_OmniFlow` (V11 na org):
- fórmula DateTime **`fAcceptBy`** = `CASE(TEXT(Rating), "Hot", CurrentDateTime+15/1440, "Warm", +60/1440, "Cold", +240/1440, +480/1440)`
- ligada ao input **`acceptBy`** (→ `TargetAcceptDateTime`) da ação skills-based `Rotear_Lead_Queue`.
- Prazo de aceitação mais cedo = roteado antes. **Só vale em `RoutingType=SkillsBased`** (queue-based ignora).
- ⚠️ O nome do input em metadata é **`acceptBy`** (os chutes `routingPriority` e `targetAcceptDateTime` foram REJEITADOS no Check Only).

## 3. Evidência de validação (2026-07-08, sandbox)
- **Priorización:** 2 leads skills-based. Hot: `CreatedDate 00:52:18 → TargetAcceptDateTime 01:07:18` (+15min). Cold: `00:51:58 → 04:51:57` (+240min). Hot com prazo mais cedo. ✓
- **Escada SLA:** reasignación disparou — `LastReminderDate__c 01:29:50` (−15), `TransferDate__c 01:55:01` (+10), `SLAReassignCount__c=1`, `ReassignReason__c=SLA_Primera_Atencion`, `Owner→Leads_CR_Offline`, `Rating→Hot`. ✓
- **T1 primeiro contato:** Task completada → `FechaPrimerContacto__c 11:41:01` carimbou; `CumplioSLA__c=false` correto (contato 11:41 > deadline 01:43). ✓

## 4. Deploy (ordem) + config pós-deploy
1. Campos + PS (Check Only + Rollback): `Lead.FechaPrimerContacto__c` (DateTime, único armazenado), `Lead.CumplioSLA__c` (fórmula), PS `HU010_Campos_SLA_Lead`.
   - Fórmula CumplioSLA: `AND(NOT(ISBLANK(FechaPrimerContacto__c)), NOT(ISBLANK(SLADeadline__c)), FechaPrimerContacto__c <= SLADeadline__c)`.
2. Flows: `Lead_SLA_Escalation`, `Lead_AT_PrimerContacto`, `Lead_Score_Temperatura`.
3. `LeadRouting_OmniFlow` (nova versão com `acceptBy`/`fAcceptBy`) — pacote em `deploy/hu010-priority-omni/`.
4. Destructive: apaga `Lead_PSR_SecondaryPriority` (**desativar no Setup antes** — flow ativo não deleta).

Pós-deploy: atribuir PS aos usuários; ativar os flows; **desativar** `Lead_PSR_SecondaryPriority`;
confirmar dependências (`Lead_BS_SetSLADeadline`, filas `Queue_Vendedores_XX`, skills, CMT `Default_Bandeja.SLAMinutes__c`).
Pré-condição de roteamento: o lead só entra no Omni com `Brand__c` (Marca) **E** `CompanyCode__c` preenchidos (`Lead_TriggerOmniRouting`).

## 5. ⏳ EM ABERTO — decisão do PO (Diego Beltrão)
**Pergunta:** carimbar `FechaPrimerContacto__c` **sem exigir Task**, porque há 2 canais de criação:
- **Accesor online** (roteado) → contato vem depois → Task/status faz sentido.
- **Vendedor de piso** → contato já aconteceu na criação → Task é fricção redundante.

A HU-010 **não obrigou** a Task; o relatório (`RELATORIO_SLA_HU010.md` §B1) já previu a alternativa
("gatilho na transição a 'En contacto'") e diz que "a definição de gestión válida é decisão do Beltrão".

**Opções propostas (aguardando escolha):**
- **(A) Híbrido (recomendado):** piso carimba na criação (por canal); online por 1ª Task completada OU transição p/ "En contacto".
- **(B) Só transição de status** nos 2 canais — zero fricção, mais burlável.
- **(C) Sempre na criação** — simples, mas no online mede criação, não contato.
- **(D) Manter só Task** (atual).

**Falta saber:** como distinguir os 2 canais (LeadSource? RecordType? quem cria? checkbox?).
Diego ia verificar e retornar. Implementação provável: manter `Lead_AT_PrimerContacto` (Task) + adicionar
carimbo na criação/status no domínio Lead, sem tocar no que já foi validado.

## 6. Artefatos no repo (branch `claude/nifty-dijkstra-AcXrv`)
- `deploy/hu010-priority-omni/` — flow corrigido (V11) + package.xml + destructiveChanges + zip.
- `deploy/hu010-final/MANIFESTO_HU010.md` — manifesto de deploy + plano de teste (atualizado, T4 corrigido/validado).
- `deploy/hu010-final/HANDOFF_HU010.md` — este arquivo.

## 7. Itens operacionais pendentes
- [ ] Desativar `Lead_PSR_SecondaryPriority` no Setup (sandbox) + rodar destructive.
- [ ] (opcional) Ver `CumplioSLA__c=true` com contato dentro do prazo (lead fresco + Task no SLA).
- [ ] Promover para outros ambientes na ordem do §4.
- [ ] Decidir §5 (primeiro contato sem Task) e implementar.
