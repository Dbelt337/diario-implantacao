# US-025 H6 — Fix v2 dos flows de desconto (DevSales)

**Origem:** auditoria de 2026-07-14 (`auditoria_us025_report.md`) sobre os retrieves
`metadata_40.zip`/`metadata_41.zip` (idênticos). Corrige a falha intermitente relatada
pelo Santiago ("às vezes envia e às vezes não").

## O que muda em `Opp_AS_EvaluarDescuento` (v2)

| # | Defeito (auditoria) | Correção |
|---|---|---|
| 1 | D.6 — não re-avaliava ao mudar o % (`doesRequireRecordChangedToMeetCriteria=true`) | Entry agora roda a cada save com `ISNEW() OR ISCHANGED(DiscountRequested__c)` — re-valoriza sempre que o % muda e não re-entra nos próprios updates |
| 2 | D.7 — aprobador estampado DEPOIS da notificação, sem fault path | `Set_Aprobador` movido para ANTES da notificação; decisão `NotifType_OK` + `faultConnector` → Task `Alert_Notif`. Falha de notificação não bloqueia mais a aprovação |
| 3 | D.3 — matriz sem fila caía em `NoPermitido` | Nova decisão `Matrix_OK`: sem fila ⇒ `A_FailSafe` = `RequiereNivel1` (⇒ aprobador default + Task). Regra do Diego: "nunca sin aprobador = aprobado" |
| 4 | D.10 — re-solicitação nunca relançava a orquestração | `Estampar` agora LIMPA `DiscountApprover__c` antes de re-resolver; o `Set_Aprobador` seguinte cria a transição não-cumpre→cumpre que relança `Opp_RT_Discount_Approval` em TODA solicitação |
| 5 | D.2 — `TipoVenta` hardcoded "Autos" | Fórmula `fTipoVenta` derivada de `RecordType.DeveloperName` (Motos/Flotas/Mayorista/Repuestos; default Autos) |
| 6 | Fora-de-spec #3 — braço Nivel3/VP | REMOVIDO (`A_N3`, `R_N3`, `vMaxVP`, `vRolVP`): escada oficial = Asesor→GerVentas→GerMarca (msg do Diego, item 1). Acima de `MaxGerMarca` ⇒ `NoPermitido`. Tokens `VP_*` do CMDT ficam órfãos — depurar com Santiago |
| 7 | D.5 — flow sem versão ativa (retrieve `Obsolete`) | XML vai com `<status>Active</status>` — o deploy ativa a v2 |

## O que muda em `Opp_RT_Discount_Approval` (v2)

| # | Defeito | Correção |
|---|---|---|
| 8 | D.9 — entrada exigia `DiscountRequested__c >= 1.0` (avaliação dispara com `> 0`; descontos <1% ficavam presos) | Filtro alinhado para `GreaterThan 0` |

## Como aplicar (DevSales)

1. Zipar esta pasta (`package.xml` + `flows/`) — ou usar o `us025_h6_fix.zip` já gerado —
   e fazer deploy via Workbench (migration → deploy) ou
   `sf project deploy start --metadata-dir deploy/us025_h6_fix -o DevSales`.
2. O deploy cria novas versões e as ATIVA (status Active no XML). Conferir em Setup → Flows
   que `Opp_AS_EvaluarDescuento` ficou Active (hoje está sem versão ativa — o retrieve voltou `Obsolete`).
3. Pré-requisitos a conferir na org (o flow agora degrada com Task de alerta em vez de morrer,
   mas o ideal é existirem):
   - `CustomNotificationType` com DeveloperName `Opp_Discount_Approver`;
   - Filas do `Aprobador_Config__mdt` com `Username__c` válido para os tokens `GV_*`/`GM_*`;
   - Componente **Work Guide** na record page de Opportunity dos perfis aprovadores
     (é Approval Orchestration — o item chega pelo Work Guide/Approval Requests, não pelo Approval History).

## Roteiro de teste (5 min)

1. Opp com % dentro do teto ⇒ `Decision=Aprobado`, aprobador limpo, nada enviado.
2. Subir o % acima de `MaxSinAprobacion` ⇒ `RequiereNivel1`, aprobador estampado, work item aparece no Work Guide do aprobador.
3. **Re-teste da intermitência:** mudar o % de novo (mesmo nível) ⇒ NOVA solicitação deve chegar (antes não chegava — era o "às vezes não").
4. % entre 0 e 1 acima do teto ⇒ agora também lança aprovação (antes ficava preso no limiar de 1%).
5. Marca/sociedade sem fila na matriz ⇒ `RequiereNivel1` + aprobador default + Task de alerta.

## Pendências conhecidas (não incluídas neste fix — decidir antes de QA)

- **ID hardcoded do aprobador default** (`005WK00000MzRGSYA3`) permanece — não é portável
  para QA/PROD. Sugestão: fila `DEFAULT` no `Aprobador_Config__mdt`.
- **Sem passo pós-aprovação** (D.11): nada estampa Aprobado/Rechazado na Opp quando o
  aprobador decide. Adicionar step na orquestração (via builder, em DevSales primeiro).
- **Solicitações paralelas:** relançar com um work item ainda pendente cria um segundo item;
  avaliar recall automático ou guarda por status no entry.
- Tasks de alerta ficam com o usuário que editou a Opp (sem OwnerId) — definir dono (admin).
- Confirmar que a Decision Matrix tem filas para os demais `TipoVenta` (Motos/Flotas/…);
  enquanto não tiver, esses RTs caem no fail-safe (RequiereNivel1 + default), que é o
  comportamento acordado.
