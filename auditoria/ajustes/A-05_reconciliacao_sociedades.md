# A-05 — Reconciliação de sociedades (GVS x CMT x canônica) — NÃO EXECUTADO

## Estado observado (evidência bloco 4)
- **GVS (via User.Sociedad__c), ativos ≈ 13:** C101, C105, H101, H105, S101, S105, S206, N101, N105, G101, G105, P105, **P101**. Falta **P103** e os 4 `-PROV`.
- **CMT (Sociedad_Config__mdt) ≈ 14:** os 13 canônicos não-PROV + **P101**. Falta os 4 `-PROV`.
- **Canônica (17):** C101, C105, C106-PROV, H101, H105, H106-PROV, S101, S105, S106-PROV, S206, N101, N105, N106-PROV, G101, G105, P103, P105.

## Divergências
1. `P101` existe em GVS e CMT, mas **não** na canônica.
2. `P103` (canônico) existe no CMT mas **não** no GVS.
3. Os 4 `-PROV` faltam em ambos (pendência conhecida — SAP Active Motors, A-10).

## Decisão necessária
**P101 é erro de digitação de P103, ou é uma sociedade real de Panamá?**

> **Default adotado: Cenário A** (reversível, pendente de confirmação com Juan Carlos Mora / SAP).

### Cenário A — P101 é erro de P103 (mais provável dada a canônica PA = {P103, P105})
- GVS: renomear/substituir `P101` por `P103` (ou desativar P101 e ativar P103).
- CMT: renomear o registro `P101` para `P103` (ajustar DeveloperName/valores).
- Resultado: GVS e CMT ficam com {…, P103, P105}, alinhados à canônica.

### Cenário B — P101 é sociedade real
- Atualizar a **lista canônica** (documento e `referencia/sociedades_canonicas.csv`) para incluir P101.
- Garantir P103 também presente em GVS (hoje falta).
- Confirmar com Juan Carlos Mora / origem SAP antes de propagar.

## Passos comuns (após a decisão)
1. Retrieve do GVS para edição local:
   `sf project retrieve start -o <alias> -m "GlobalValueSet:GVS_Sociedad"`
2. Editar `globalValueSets/GVS_Sociedad.globalValueSet-meta.xml` (ajustar customValue).
3. Ajustar os registros de `Sociedad_Config__mdt` (via Setup > Custom Metadata Types ou deploy).
4. Adicionar os 4 `-PROV` quando o SAP final estiver definido (A-10).
5. Re-rodar o bloco 4 da auditoria e confirmar matriz 100% alinhada.

> Meta final: canônica == GVS == CMT (mesmos 17 códigos, mesma grafia).
