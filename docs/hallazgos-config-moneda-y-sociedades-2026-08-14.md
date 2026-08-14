# Achados na configuração de moeda e sociedades, DEV Sales, 14/08

Origem: execução de `check-metadata-moneda.apex` e
`check-accountaccountrelation-hu017.apex` em `GrupoQ`, `00DWK000005VFeD2AW`,
instância USA772S, sandbox.

Rodados para responder duas coisas: se o `CountryCurrency__mdt` proposto pelo
time financeiro duplica algo que já existe, e se as premissas da RN-05 da
HU-017 sobre `AccountAccountRelation` se sustentam. Responderam as duas, e
apareceram quatro problemas que ninguém tinha perguntado.

---

## 1. GRAVE. Três moedas da configuração não existem na org

Só existem **duas moedas ativas**: USD, corporativa, e CRC com taxa 510,204.

O `Sociedad_Config__mdt` referencia três que não estão lá:

| Sociedades | `Currency_Code__c` | Existe na org |
|---|---|---|
| G101, G105 | GTQ | **Não** |
| H101, H105 | HNL | **Não** |
| N101, N105 | NIO | **Não** |
| C101, C105 | CRC | Sim |
| P101, P103, P105, S101, S105, S206 | USD | Sim |

O `Lead_BS_DeriveSociedad` atribui `CurrencyIsoCode` a partir desse campo.
**O primeiro lead de Guatemala, Honduras ou Nicarágua vai falhar**, porque não
se pode gravar uma moeda que não está ativa na org.

Isso não aparece hoje porque não há nenhum registro nessas moedas, o que é o
item 4. Está esperando o primeiro caso real.

Duas saídas, e a escolha não é técnica: ativar as três moedas em Manage
Currencies com as taxas, ou decidir que os seis países operam em USD e corrigir
a configuração. A segunda tem relação direta com o item 3.

---

## 2. O `CountryCurrency__mdt` já existe, então a duplicidade já é real

Não é uma proposta a avaliar, **já está deployado nesta org**, com
`AllowedCurrencies__c` e `CountryName__c`.

Convivendo com `Sociedad_Config__mdt.Currency_Code__c`, que tem 14 registros e é
o que o flow de Lead já usa. São duas fontes para o mesmo significado, que é
exatamente o que a decisão de governança de 14/08 proíbe.

E a granularidade do novo é a errada: país não representa Costa Rica com C101 e
C105, nem El Salvador com S101, S105 e S206.

**Recomendação:** aposentar o `CountryCurrency__mdt` e mover o
`AllowedCurrencies__c` para o `Sociedad_Config__mdt`, ao lado do
`Currency_Code__c` que já está lá. Um deriva o default, o outro valida o
conjunto permitido, e os dois passam a viver no mesmo lugar com a granularidade
certa. A validation rule proposta pelo time financeiro continua funcionando, só
troca o `CASE` de país para sociedade.

O contexto mais amplo: há **quatro** Custom Metadata carregando país ou
sociedade, `Sociedad_Config__mdt`, `CountryCurrency__mdt`,
`Brand_Sociedad_Map__mdt` e `Lead_Routing_Config__mdt`, mais três que usam
`Sociedad__c` como texto solto, `Aprobador_Config__mdt`, `Lead_SLA_Config__mdt`
e `SensitiveDataApprover__mdt`. O código da sociedade está repetido como texto
livre em sete lugares sem integridade referencial nenhuma.

---

## 3. Costa Rica está em CRC e a RN6 da HU-038 diz USD

`C101` e `C105` têm `Currency_Code__c = CRC`. A RN6 da HU-038 diz textualmente
que na Costa Rica os preços se administram e se exibem em dólares e não se
exibem em colones.

Não é divergência de opinião, é contradição entre a configuração no ar e uma
regra escrita. E o custo de resolver não é o mesmo nos dois sentidos: se a RN6
prevalecer, não é editar dois registros de metadado, é converter os dados do
item 4.

Isso também derruba a peça 1 da proposta do time financeiro como está escrita,
"vendedor CR = CRC". Se a RN6 valer, o default para Costa Rica é USD.

---

## 4. Os dados estão quase todos em colones

| Objeto | CRC | USD |
|---|---|---|
| Opportunity | 653 | 0 |
| Lead | 3674 | 1 |
| Quote | 89 | 0 |

Nenhum registro em nenhuma outra moeda, o que confirma que os seis países ainda
não foram exercitados de verdade e que o problema do item 1 continua latente.

E como a moeda de uma `PricebookEntry` se define ao criar e não se edita,
publicar em USD o que hoje está em CRC significa **criar** as entradas em USD,
não converter as existentes.

---

## 5. São 14 sociedades, não 12

A lista completa do `Sociedad_Config__mdt`:

C101, C105, G101, **G105**, H101, H105, N101, N105, **P101**, P103, P105, S101,
S105, S206.

Os trabalhos de HU-038 vinham usando doze. Faltavam **G105 e P101**. O número
de listas oficiais de preço muda junto, e vale corrigir com o Flavio antes que
doze vire premissa de construção.

### 5bis. Dois registros com prefixo de fila copiado do vizinho

| Sociedade | `Default_Queue_Prefix__c` | Deveria ser |
|---|---|---|
| G105 | `Leads_G101` | `Leads_G105` |
| P103 | `Leads_P105` | `Leads_P103` |

São justamente os dois registros criados depois, os de bloco de Id diferente.
Lead de G105 cai na fila de G101 e lead de P103 cai na de P105. Erro de cópia,
correção de dois campos, mas silencioso enquanto ninguém olhar.

---

## 6. HU-017, as três premissas da RN-05 se confirmam

| Premissa | Resultado |
|---|---|
| `AccountAccountRelation` existe e é personalizável | Sim, `personalizable=true`, criável e consultável |
| Histórico de campos próprio | Sim, `AccountAccountRelationHistory` existe |
| Compartilhamento por registro | Sim, `AccountAccountRelationShare` existe |

Também existem `AccountAccountRelationFeed`, `PartyRoleRelation`,
`AccountContactRelation` e `InternalOrganizationUnit`. A RN-05 e a RN-35 podem
ser escritas como estão, e a resposta à Melisa vai sem ressalva.

Dois detalhes que valem para quem for construir:

- **Zero campos personalizados e zero registros hoje.** Os cinco dados locais da
  RN-05, área de vendas, canal, devedor SAP, Grupo de Clientes e indicador de
  sociedade de origem, são todos campos a criar. Ninguém começou;
- O objeto **não tem campo próprio de tipo de relação**. Os campos padrão são
  `AccountId`, `RelatedAccountId`, `StartDate`, `EndDate` e `IsActive`. O papel
  vive no `PartyRoleRelation`, que é exatamente o que a RN-05 já descreve.

---

## Ordem sugerida

1. Item 1, decidir se ativa GTQ, HNL e NIO ou se tudo vai a USD. É o único que
   quebra sozinho;
2. Item 3, levar a contradição de Costa Rica para quem decide, com o número do
   item 4 na mão;
3. Item 5bis, corrigir os dois prefixos de fila, custa dois campos;
4. Item 5, corrigir o número de sociedades com o Flavio;
5. Item 2, consolidar os dois Custom Metadata de moeda em um só.
