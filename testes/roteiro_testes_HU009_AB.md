# Roteiro de Testes — HU-009 Partes A+B (Hand-off Digital → Sucursal)

**Org:** DevSales · **Data:** 11/07/2026 · **Flow sob teste:** `Event_AfterSave_ShareBranchHandOff` (ativo)
**Antes de começar (pré-requisitos):**
- [ ] `BranchCode__c` e `VisitStatus__c` no layout do Event; os 4 campos no layout da Opportunity
- [ ] **Owner** marcado no Set History Tracking da Opportunity
- [ ] Pelo menos 1 usuária de teste no grupo `GRP_Sucursal_SV_AUTOSUR` (a "Recepcionista"), que **não** tenha acesso prévio à Opp de teste (não pode ser admin, não pode ser a Owner, sem View All)
- [ ] Uma Opportunity de teste cujo Owner é o "Asesor Digital" (pode ser você)

Anota o Id da Opp de teste: `006________________`

---

## T1 — Share + estampa (caminho feliz)
1. Na Opp de teste, criar um **Event** (New Event) com `Sucursal (BranchCode__c)` = `SV_AUTOSUR`, Related To = a Opp.
2. **Esperado na Opp** (recarrega a página):
   - `Estado Hand-Off (HandOffStatus__c)` = **Pendiente Recepción**
   - `Asesor Digital Originador` = o Owner atual da Opp
   - `Fecha de Hand-Off` = **vazia** (só a Parte C preenche)
3. Query de conferência do share:
```sql
SELECT UserOrGroup.Name, OpportunityAccessLevel, RowCause FROM OpportunityShare WHERE OpportunityId = '<ID_OPP>' AND RowCause = 'Manual'
```
   **Esperado:** 1 linha — `Sucursal Autopista Sur (SV)` / `Read` / `Manual`.

## T2 — Recepcionista enxerga a Opp
1. Login As na usuária Recepcionista (membro do grupo).
2. Abrir a Opp pelo Id (ou por list view).
   **Esperado:** ela **vê** a Opp (read-only). Antes do T1 ela não via.

## T3 — Cleanup nativo no troca de Owner (o coração da Parte B)
1. Trocar o Owner da Opp para outro usuário (simulando o Recibir Cliente manual).
2. Rodar de novo a query do T1.
   **Esperado:** **0 linhas** — o share Manual morreu sozinho com a troca de Owner. Nenhum flow de limpeza envolvido: é comportamento nativo.
3. `HandOffStatus__c` continua `Pendiente Recepción` e o Asesor Originador continua o original (a Parte C é quem muda o status para Recibido).

## T4 — Imutabilidade do Asesor Originador
1. Na mesma Opp (Owner já trocado no T3), criar **outro** Event com `BranchCode__c = SV_SANTAELENA`.
2. **Esperado:**
   - `Asesor Digital Originador` **não muda** (continua o Owner original do T1 — protege a comissão)
   - Novo share criado, agora com o grupo de Santa Elena (query T1 → 1 linha nova)

## T5 — Código de sucursal inexistente (resiliência)
1. Criar Event em outra Opp com `BranchCode__c = XX_TESTE`.
2. **Esperado:**
   - Nenhum share (query T1 → 0 linhas)
   - **Task de log** na Opp: assunto "HU-009: branch public group missing…" com `GRP_Sucursal_XX_TESTE` na descrição
   - `HandOffStatus__c` = Pendiente Recepción mesmo assim (o estado operativo é real)

## T6 — Atividade que não é de Opportunity
1. Criar Event relacionado a uma **Account** (Related To = conta) com `BranchCode__c = SV_AUTOSUR`.
2. **Esperado:** nada acontece (sem share, sem Task, sem erro). O flow sai no primeiro gate.

## T7 — Preencher a sucursal DEPOIS (caminho de update)
1. Criar Event na Opp **sem** `BranchCode__c`.
   **Esperado:** nada acontece.
2. Editar o Event e preencher `BranchCode__c = SV_AUTOSUR`.
   **Esperado:** flow dispara agora — share + estampa como no T1 (gatilho é "passou a atender o critério").

## T8 — Origem pelo LeadSource (decisão final: sem ChannelCode)
1. Criar um Lead manual escolhendo `Lead Source = Facebook` (+ Industry = Autos, obrigatórios).
   **Esperado:** salva normal; vendedor escolhe de lista, nunca digita origem.
2. *(Registro para o go-live da integração: middleware mapeará o `channelCode` do payload para um valor do LeadSource — ex. WEB_MARCA → "Página web de la marca". Validation rule de catálogo para criações via API fica como pendência da integração.)*

## T9 — Conversão carrega a origem nativamente
1. Converter o Lead do T8.
2. Na Opp convertida:
```sql
SELECT LeadSource, RecordType.DeveloperName, StageName FROM Opportunity WHERE Id = '<ID_OPP_CONVERTIDA>'
```
   **Esperado:** `LeadSource = Facebook` (cópia nativa, sem mapping). *(Bônus: RecordType `GQOpportunitiesAutos` estampado pelo Opp_BS_EstampaRT do US-025.)*

## T10 — Rastro de auditoria
1. Na Opp do T1/T3, abrir o related list **Opportunity Field History**.
   **Esperado:** entradas de `Estado Hand-Off` (→ Pendiente Recepción) e de **Owner** (troca do T3), com data/hora e autor.

---

## Registro de resultados
| Teste | OK? | Observação |
|---|---|---|
| T1 share + estampa | ✅ | share Sucursal Uruca (CR)/Read/Manual criado |
| T2 visibilidade recepcionista | ⏳ | condicionado ao OWD Private (conferir Sharing Settings) |
| T3 cleanup nativo | ✅ | Owner→Santiago: share sumiu sozinho |
| T4 imutabilidade asesor | ✅ | debug entrou no braço "already stamped" |
| T5 grupo inexistente → log | ✅ | Task "branch group missing" (foi o diagnóstico do T1) |
| T6 atividade não-Opp | | |
| T7 update tardio | | |
| T8 origem via LeadSource | | |
| T9 conversão LeadSource nativa | | |
| T10 field history | | |

**Critério de aceite da Parte B:** T1, T2, T3 e T4 verdes (os demais são robustez/governança). Qualquer vermelho: copiar o erro/estado e me mandar.


---
## Parte C — Recibir Cliente (validada 11/07)
Quick action + screen flow `Opportunity_Screen_ReceiveCustomer` (System Mode Without Sharing): executada na Opp de teste → Owner transferido, `HandOffStatus=Recibido`, `HandOffDate=2026-07-11T01:14:48Z`. Pendente: teste do Escenario 10 (Opp sem Event) e visita marcada Atendida.
