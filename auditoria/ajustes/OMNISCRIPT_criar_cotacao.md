# OmniScript "Criar Cotação" — GrupoQ (OmniStudio standard, sem Vlocity/CPQ)

Botão que, a partir de um registro de contexto (**Account** ou **Opportunity**), **cria uma
Cotação**. É a v1 mínima ("por enquanto, apenas isso"); depois evolui (linhas de produto, preço, etc.).

> **Cenário confirmado:** GrupoQ tem **OmniStudio** (Designer standard — o diálogo "New Omniscript"
> da referência), **sem o pacote Vlocity e sem CPQ**. Logo:
> - "Cotação" = objeto **nativo `Quote`** do Salesforce (não o cart/quote do Vlocity CPQ).
> - A construção é no **Designer** (não é DataPack Vlocity). O `SalesQuote.json` enviado é só
>   **referência conceitual** do padrão "omni pai com filhos" (lá era um Integration Procedure
>   `B2B_SalesQuote` com Conditional Blocks + DataRaptors + Remote Actions filhos).

## 1. Diálogo "New Omniscript" — o que preencher
| Campo | Valor sugerido | Observação |
|---|---|---|
| **Name** | `GrupoQ Criar Cotação` | rótulo de exibição |
| **Type** | `GrupoQ` | categoria (agrupa os OmniScripts do GrupoQ) |
| **Sub Type** | `CriarCotacao` | ação específica |
| **Language** | `Portuguese` (ou o idioma do org) | Type/SubType/Language formam a chave única |
| **Description** | `Identifica Account/Opportunity e cria Quote nativa (v1).` | |

Chave do OmniScript resultante: **`GrupoQ/CriarCotacao/Portuguese`** (é assim que ele é
referenciado na Action de lançamento e por outros processos).

## 2. Arquitetura "pai → filhos" (equivalente nativo ao exemplo)
```
OmniScript  GrupoQ/CriarCotacao            (o "pai" — o botão)
├─ Set Values           SetContext         detecta o tipo pelo prefixo do Id de contexto
├─ Conditional Block    CB_Opportunity     (prefixo = 006)
│   └─ DataRaptor Extract  DRe_Opp          lê AccountId/Pricebook2Id da Opp; oppId = ContextId
├─ Conditional Block    CB_Account         (prefixo = 001)
│   └─ Integration Procedure  IP_ResolveOpp resolve/cria a Opp da conta -> retorna oppId
├─ Integration Procedure Action  IP_CriarCotacao   grava o Quote (filho headless) -> QuoteId
└─ Navigate Action      NavToQuote         abre a Cotação criada
```
O "pai com filhos" nativo = o **OmniScript** com seus elementos (Steps/Blocks/Actions), e um ou
mais **Integration Procedures filhos** headless que fazem o DML. Não usamos nada de CPQ.

## 3. Detecção de contexto (Account vs Opportunity)
Ao adicionar o OmniScript como **Action de um record page**, o Designer injeta `ContextId`
(o Id do registro) no data JSON. Para saber o tipo, use o **prefixo do Id**:
- Element **Set Values `SetContext`**, campo `objTipo` = fórmula `LEFT(%ContextId%, 3)`
  - `001` → Account  ·  `006` → Opportunity
- Os **Conditional Blocks** usam `objTipo` como condição (`= 001` / `= 006`).

(Alternativa: passar `objectApiName` como parâmetro na Action de lançamento, se preferir explícito.)

## 4. Criar o Quote sem CPQ — a Integration Procedure filha `IP_CriarCotacao`
`Quote` nativo exige **`OpportunityId`**. Por isso:
- Contexto **Opportunity** → cria `Quote` direto (OpportunityId = ContextId).
- Contexto **Account** → precisa de uma Opp: usa a **Opp aberta mais recente** da conta; se não
  houver, cria uma **Opp mínima** (regra da v1 — ajustável).

A gravação do Quote é um **DataRaptor Post (Load)** OU uma Remote Action Apex dentro do IP filho.
Mapeamento mínimo do DataRaptor Post → `Quote`:
| Campo Quote | Origem | Obrigatório |
|---|---|---|
| `OpportunityId` | oppId resolvido | **sim** |
| `Name` | `"Cotação " + hoje` | sim |
| `Status` | `Draft` | (default) |
| `Pricebook2Id` | Pricebook da Opp ou Standard ativo | só se for ter linhas |
| `ExpirationDate` | hoje + 30 | não |

> `Quote.AccountId` é derivado da Opportunity automaticamente — não precisa setar.

**A lógica exata já está validável** no script dry-run `criar_cotacao.apex` (mesma resolução
Account/Opportunity + insert do Quote). Rode-o antes de montar o IP, para confirmar campos/regras
no org. Confirme também que **Quotes está habilitado** (Setup → Quotes Settings) com
`describe_quote.apex` (se `Quote` vier AUSENTE, habilite antes).

## 5. Lançar o "botão" (a Action no registro)
1. Ative o OmniScript (**Activate** no Designer).
2. Em **Object Manager → Account → Buttons, Links, and Actions → New Action**, tipo
   *OmniScript*, aponte para `GrupoQ/CriarCotacao/Portuguese` (ou use o LWC gerado na
   Lightning Page). Repita para **Opportunity**.
3. Adicione a Action ao layout/record page. O `ContextId` chega sozinho.

## 6. Passo a passo de construção (Designer)
1. **New Omniscript** com os valores da seção 1 → Save.
2. Arraste **Set Values** `SetContext` → adicione `objTipo = LEFT(%ContextId%,3)`.
3. **Conditional Block** `CB_Opportunity` (mostra se `objTipo = 006`):
   - **DataRaptor Extract** `DRe_Opp` (filtro Id = `%ContextId%`) → devolve `AccountId`,`Pricebook2Id`.
   - **Set Values**: `oppId = %ContextId%`.
4. **Conditional Block** `CB_Account` (mostra se `objTipo = 001`):
   - **Integration Procedure Action** `IP_ResolveOpp` (input `accountId = %ContextId%`) → `oppId`.
5. **Integration Procedure Action** `IP_CriarCotacao` (input `oppId`) → `quoteId`.
6. **Navigate Action** para abrir `%quoteId%`.
7. **Activate** e teste a partir de um registro real (valide antes com os `.apex`).

## 7. Artefatos deste pacote
- `describe_quote.apex` — read-only: confirma Quotes habilitado + campos obrigatórios de Quote/Opp.
- `criar_cotacao.apex` — **dry-run** da lógica do filho (identifica Account/Opp, cria Quote). É o
  espelho fiel do que o `IP_CriarCotacao` fará; sirva-se dele para validar no org antes de montar.

## 8. Decisões e pendências (v1)
- **"Cotação" = `Quote` nativo** (sem CPQ). Se GrupoQ modelar cotação em outro objeto (ex.: OMS /
  objeto custom), trocar o alvo do DataRaptor Post — o resto da estrutura permanece.
- **Account sem Opportunity**: a v1 cria uma Opp mínima (`CREATE_OPP_IF_MISSING`). Se o negócio
  exigir escolher/confirmar a Opp, adicionar um Step de UI antes do `IP_CriarCotacao`.
- **Idioma/labels**: ajustar `Language` e textos ao padrão do org (es-CR provável, dado Costa Rica).
- **Próxima evolução** (fora da v1): linhas de produto (`QuoteLineItem`), preço, sincronizar com a
  Opportunity (`Opportunity.SyncedQuoteId`), aprovação.
