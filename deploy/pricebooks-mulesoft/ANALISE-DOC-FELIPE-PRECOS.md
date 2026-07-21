# Análise — Doc Felipe Pajon "Proceso de Precios GrupoQ/CrediQ actual hacia Salesforce"

Doc do arquiteto Salesforce (Felipe Pajon). Analisa como a operação atual de preços
se traduz ao standard do Salesforce. Cruzado com as restrições do GrupoQ.

## Restrições confirmadas do GrupoQ (rubrica)
- **Catálogo STANDARD, sem EPC** (Enterprise Product Catalog).
- **Sem Revenue Cloud / CPQ** (não contratado).
- **Apenas OmniStudio Standard Runtime** (a validar contra BRE — ver alerta abaixo).
- MuleSoft já contratado.

## 1. As 3 alternativas do Felipe
| Alt | Onde calcula | Papel do MuleSoft | Prós | Contras |
|---|---|---|---|---|
| **1 (recomendada, short-term)** | **OmniStudio** (Decision Matrices / Expression Sets) | Sincroniza materiais+inventário do SAP → SF Core (assíncrono, lotes/eventos) | Latência zero na tela (dado já no SF); time comercial ajusta preços/descontos nas matrizes | Risco de desfase de inventário (sync programado, não 100% real-time) |
| **2** | **MuleSoft** (consulta real-time ao SAP) | Calcula e expõe; OmniStudio invoca em tempo real | Consistência (nunca vende sem stock); sem duplicar lógica; **API única omnicanal** (Core + B2C Commerce) | Latência/rede por clique; maior volume de API calls (precisa cache no Mule) |
| **3** | **Revenue Cloud (CPQ/Billing)** | Alimenta o motor | Nível empresarial; rastreabilidade | **Requer licença Revenue Cloud (não contratada)** + complexidade alta |

**Recomendação Felipe:** **Alt 1** (menor fricção, usa o já contratado). **Alt 2**
ganha valor quando há outros sistemas transacionais/faturamento fora do Salesforce
(unifica a lógica de preço numa só camada de integração, exposta a qualquer consumidor).

## 2. ⚠️ ALERTA — licenciamento do motor (BRE) — validar ANTES
A Alt 1 depende de **Expression Sets + Decision Matrices**, que são **Business Rules
Engine (BRE)**. O escopo declarado é **"apenas OmniStudio Standard Runtime"**
(OmniScript, IP, DataRaptor, FlexCards). **Confirmar se BRE/Expression Sets/Decision
Matrices estão habilitados na org/licença.**
- **Se SIM** → seguir a Alt 1 do Felipe (motor declarativo, sem Apex).
- **Se NÃO** → o motor recomendado não é construível como está. Plano B: cálculo em
  **Integration Procedure + DataRaptor + fórmulas** (mais pesado/manual) OU ir de
  **Alt 2** (cálculo no MuleSoft, Salesforce só consome).
- **Este é o item #1 a fechar na agenda.**

## 3. Fontes de dados — DOIS sistemas (não esquecer nenhum)
- **SAP ERP** → **materiais + inventário** (master data e estoque).
- **QRM** (sistema de preços atual do cliente) → **variáveis de preço**: preço de
  lista (USD/local), preço mínimo, preço exonerado, gastos (matrícula, entrega),
  **% imposto de primeira matrícula** (por país, ex.: El Salvador), **cashback**
  (com vigência por data), pacotes, **llaves de promoção** ("¿Mostrar en sitio
  web?", "Aplica descuento").
- **Salesforce/OmniStudio** → calcula o **preço final** = preço base + gastos +
  impostos − cashback, com **conversão de moeda** (USD → local).

> A confirmar na agenda: o **preço de lista base** vem do **SAP** ou do **QRM**?
> (SAP é fonte de materiais/inventário; QRM parece ser a fonte dos preços/gastos.)

## 4. Mapeamento QRM/SAP → Salesforce standard (confirma catálogo sem EPC)
| Conceito atual | Objeto Salesforce | Nota |
|---|---|---|
| Marca, Modelo, Versão, Ano | **Product2** ou **VehicleDefinition** | características físicas = **campos custom** (sem EPC) |
| Preço de Lista (USD/local) | **PricebookEntry** | multimoeda nativa |
| Preço Mínimo / Exonerado | **campos custom no PricebookEntry** | margem de negociação do assessor |
| Gastos / Cashback / Pacotes | campos no preço, ou produtos "gasto/serviço", ou **Calculation Matrix** | separar "Preço do Veículo" de "Gastos Locais" |

**Best practice do doc:** separar **"Preço do Veículo"** dos **"Gastos Locais"**
(matrícula, impostos por país, entrega) em objetos/registros separados → facilita
carga massiva sem alterar o preço base.

## 5. Motor de cálculo (Alt 1) — OmniStudio
- **Expression Sets** = o "cérebro": pega o preço base da versão/modelo e aplica
  condicionalmente % imposto, soma de gastos, subtração de cashback (se promo
  ativa e vigente por data).
- **Integration Procedures** = recebem os parâmetros da versão, invocam o Expression
  Set, fazem conversão de moeda, devolvem o resultado. Declarativo, sem Apex.
- **API-First:** os mesmos IPs podem ser expostos como **REST API** → consumidos
  pela web de marca / e-commerce (preço real-time, mesmo ponto de manutenção).

## 6. Carga massiva das matrizes de preço (do QRM → Salesforce)
Opções do doc:
1. MuleSoft (API-Led) → Experience API → IP → Decision Matrix (real-time).
2. **CSV nativo** (recomendado p/ negócio): baixar template da matriz, preencher
   colunas de entrada (País/Marca/Modelo/Versão) e saída (%Imposto/Gastos/Cashback),
   subir → nova versão da matriz.
3. Integração automatizada (DataRaptor/API) → bulk insert em **CalculationMatrixRow**
   / **ExpressionSetMatrixCell** (se as variáveis mudam muito e vivem no SAP).
4. Edição manual direta (ajustes cirúrgicos) na interface tipo planilha.

## 7. Aprovações (Visto Bueno do Diretor) — nativo
- **Approval Process + Flow**: gatilho detecta preço novo OU **Preço Mínimo/Lista
  reduzido** (via `$Record__Prior`); **bloqueia o registro** em aprovação; aprovação
  **multicanal** (SF / e-mail / Slack-Teams); **bypass** se só sobe preço ou muda
  gastos.
- **Field History Tracking** nos campos-chave de preço (auditoria: quem/quando/valor
  anterior).

## 8. Perguntas para a agenda (atualizadas com o doc)
1. **BRE/Expression Sets/Decision Matrices estão licenciados?** (define Alt 1 vs plano B/Alt 2)
2. Alt 1 vs Alt 2 — decisão de arquitetura (há sistemas de faturamento fora do SF que justifiquem Alt 2 / API única?).
3. **Preço de lista base vem do SAP ou do QRM?** Fronteira exata SAP × QRM.
4. Chave de match material (SAP) ↔ Product2/VehicleDefinition (ProductCode/material).
5. Cadência do sync SAP (inventário): lote diário + real-time no fechamento (decisão Felipe Pajon) — confirmar gatilho.
6. Migração das matrizes QRM → Decision Matrices: CSV, DataRaptor ou MuleSoft?
7. Modelagem "Preço do Veículo" × "Gastos Locais" (objetos/campos separados).
8. Repuestos segue callout real-time SAP; PA segue Price Book (do modelo anterior) — confirmar que continua.
9. Multimoeda por país (CRC/HNL/GTQ/USD) + conversão USD→local no IP.

## 9. Dados a levar/pedir na reunião (inventário)
**Do SAP (via MuleSoft):** material master (marca, modelo, versão, ano, código de
material/ProductCode, características físicas, moeda) + inventário (estoque por
ubicação/sucursal, estado).
**Do QRM:** preço de lista (USD/local), preço mínimo, preço exonerado, gastos
(matrícula/entrega), % imposto primeira matrícula por país, cashback (vigência),
pacotes, llaves de promoção. + a estrutura do arquivo de carga massiva atual do QRM
(colunas exatas) para desenhar as Decision Matrices.
