# Consulta Lista Negra — OmniScript + IP (mock)

Action no **Lead** que abre um modal, captura **documento** e **nome** do cliente,
chama um **serviço externo de lista negra** (via Integration Procedure) e marca no
Lead que a consulta foi feita e que o cliente **não tem restrição para venda**.

> Status atual: **serviço externo simulado (mock)**. A IP sempre devolve "sem
> restrição". Trocar pelo serviço real depois (ver seção *Plugar o serviço real*).

## Arquitetura

```
Lead (record page) ─ Action "Consultar Lista Negra"
   │
   └─▶ OmniScript  LeadListaNegra/Check
          ├─ Step "Dados do Cliente" (modal)
          │     LeadId   ← ContextId (Set Values, oculto)
          │     Documento ← pre-fill do Lead (DataRaptor Extract) + editável
          │     Nome      ← pre-fill do Lead + editável
          │
          ├─ Integration Procedure Action ─▶ IP  LeadListaNegra/Check
          │     SimulaServico (Set Values)   → mock: temRestricao=false
          │     DefineStatus  (Set Values)   → statusListaNegra, dataConsulta
          │     GravaLead (DataRaptor Load)  → DRLeadListaNegraUpdate (upsert Lead)
          │           Lead.ListaNegraStatus__c       = 'OK - Sem Restricao'
          │           Lead.ListaNegraDataConsulta__c = NOW()
          │     Resposta (Response Action)   → { status, statusListaNegra, mensagem }
          │
          └─ Step "Resultado" → "Cliente liberado, sem restrição para venda"
```

## Conteúdo do pacote (deployável)

| Arquivo | O quê |
|---|---|
| `objects/Lead.object` | 2 campos novos: `ListaNegraStatus__c` (picklist), `ListaNegraDataConsulta__c` (DateTime) |
| `omniDataTransforms/DRLeadListaNegraUpdate_1.rpt` | Data Mapper Load: upsert no Lead por Id |
| `omniIntegrationProcedures/LeadListaNegra_Check_English_1.oip` | IP de consulta (mock) |
| `omniScripts/LeadListaNegra_CheckUI_English_1.os` | OmniScript da UI (Type=LeadListaNegra, SubType=**CheckUI**) |
| `package.xml` | Manifesto MDAPI (API 66.0) |

> **OmniScript no pacote (best-effort).** O `.os` é metadata hand-authored e a doc
> oficial está bloqueada (403) neste build, então **deploye em CHECK-ONLY primeiro**
> (Workbench → Single Package + Rollback On Error). Após deployar, abra UMA vez no
> Designer: re-selecione a IP `LeadListaNegra_Check` no elemento `ChamaListaNegra`
> e **Active** (a ativação gera o LWC que aparece no dropdown da Action). O passo a
> passo manual abaixo continua válido como fallback caso o `.os` não importe limpo.
> O SubType é **CheckUI** (e não `Check`) de propósito: IP e OmniScript dividem o
> objeto `OmniProcess`, então o `uniqueName` precisa ser distinto.

## Deploy

```bash
sf project deploy start --metadata-dir deploy/ip-lista-negra --target-org DevSales
# ou Workbench → Migration → Deploy (zipar a pasta)
```

Depois de deployar:
1. Abra a **IP** no OmniStudio Designer → no elemento **GravaLead**, **re-selecione**
   o bundle `DRLeadListaNegraUpdate` no dropdown (colar JSON não faz o bind).
2. Confira os **Set Values** (`SimulaServico`, `DefineStatus`). Se `dataConsulta`
   aparecer como texto `=NOW()`, marque o valor como **Formula** no Designer.
3. **Active** a IP.

## OmniScript — passo a passo no Designer

**OmniStudio → OmniScripts → New**
- Type: `LeadListaNegra` · SubType: `Check` · Language: `English`
- (assim a IP `LeadListaNegra/Check` e o OmniScript ficam no mesmo namespace lógico)

### 1) Step "Dados do Cliente"
- Adicione um **Step** (label: "Dados do Cliente").
- Dentro do Step:
  - **Set Values** `SetLeadId` → cria `leadId` = `%ContextId%`
    (na página do Lead o OmniScript recebe o Id do registro em `ContextId`).
  - **Text** `documento` (label "Documento") — obrigatório.
  - **Text** `nome` (label "Nome").

### 2) (Opcional) Pré-preencher do Lead
- **DataRaptor Extract Action** no início (antes do Step ou em PreSave):
  - DataRaptor Extract `DRLeadGetForListaNegra` (criar no Designer):
    Extract `Lead` WHERE `Id = leadId` → `Name`→`nome`, `NationalId__c`→`documento`.
  - Mapeie a saída para os campos `nome` / `documento` do Step (default values).
- Se quiser começar simples, pule este passo: o usuário digita documento/nome.

### 3) Integration Procedure Action `ChamaListaNegra`
- Type: **Integration Procedure Action**.
- Integration Procedure: `LeadListaNegra/Check`.
- **Input Parameters** (Send): `leadId`, `documento`, `nome`
  (passe os elementos do Step com o mesmo nome).
- **Response**: deixe gravar a resposta no data JSON (ex.: node `consulta`).

### 4) Step "Resultado"
- **Text Block** / **Messaging** mostrando:
  - "Consulta realizada: **%consulta:statusListaNegra%**"
  - "%consulta:mensagem%"
- Botão **Concluir** (Done) fecha o modal.

### 5) Ativar e publicar
- **Activate** o OmniScript (gera o LWC `cf...` correspondente).

## Action no Lead

Duas opções:

**A) Quick Action (modal) — recomendado**
1. Após ativar o OmniScript, o Designer expõe ele como um Lightning Web Component.
2. Setup → Object Manager → **Lead** → **Buttons, Links, and Actions** → **New Action**
   - Action Type: **Lightning Web Component**
   - LWC: o componente gerado do OmniScript (`...leadListaNegraCheck...`)
   - Label: "Consultar Lista Negra"
3. Adicione a Action ao **Page Layout** / **Highlights Panel** do Lead.
   O `ContextId` é injetado automaticamente com o Id do Lead.

**B) Embutir no record page**
- Lightning App Builder → página do Lead → arraste o componente **OmniScript**
  → selecione `LeadListaNegra/Check`. (Fica sempre visível, não em modal.)

## Plugar o serviço real (sair do mock)

Na IP `LeadListaNegra/Check`:
1. Crie um **Named Credential** para a API de lista negra (URL + auth).
2. Troque o elemento **SimulaServico** (Set Values) por um **HTTP Action**:
   - Method/URL conforme o serviço; use o Named Credential.
   - Request: mapeie `documento` e `nome`.
   - Response: leia o flag de restrição do payload para `servico:temRestricao`
     e a mensagem para `servico:mensagem`.
3. Em **DefineStatus**, troque o literal por uma **Formula** ou **Conditional Block**:
   - `statusListaNegra = IF(%servico:temRestricao% == "true", "Com Restricao", "OK - Sem Restricao")`
4. (Opcional) Na resposta, devolva `temRestricao` para o OmniScript decidir a
   mensagem/cor do Step "Resultado".
