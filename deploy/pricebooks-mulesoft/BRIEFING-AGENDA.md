# Briefing — Agenda de refinamento de Price Books com MuleSoft

Consolida o que o projeto já decidiu sobre price books + integração SAP/MuleSoft,
e lista o que a agenda precisa fechar. Fontes: ESTRUTURA-CATALOGO.md,
DECISOES-ARQUITETURA.md, COBERTURA-NATIVA.md, PROXIMOS-PASSOS.md,
Opp_BS_EstampaPricebook.flow.

## 1. O que já está decidido / no projeto

### Modelo de 2 eixos (não misturar)
- **Produto ("o que é"):** Product Catalog -> Category -> Product2 (+ Business
  Brand, Vehicle Definition, Product Attribute). Produto e UM so.
- **Comercial ("como se precifica"):** Price Book por sociedade/pais x tipo de
  venda. Frotas NAO tem catalogo proprio — reusam Autos com Price Book de frota.

### Precificacao por linha (a fronteira estatico x dinamico)
| Linha | Preco | Mecanismo |
|---|---|---|
| Autos Novos | Price Book Retail por sociedade | Nativo (estatico) |
| Autos Usados | Individual por VIN (Asset/Vehicle: MarketPrice) | Nativo, nao e lista |
| Motos | Price Book Motos por sociedade | Nativo (estatico) |
| Frotas | Price Book Fleet (reusa catalogo Autos) | Nativo (estatico) |
| PA (Accesorios) | Price Book PA | Nativo (estatico) |
| **Repuestos** | **Callout real-time ao SAP** | **Dinamico (nao Price Book)** |

### Estado atual dos Price Books
- **1 book por sociedade (6 books)**, multimoeda. C101 verificado: PBEs ativas em
  CRC.
- Stamping: `Opp_BS_EstampaPricebook` (before-save Opp, banda 11) carimba
  `Pricebook2Id` no create pela **sociedade** — casa pelo **prefixo do NOME** do
  book com `CompanyCode__c` (ex.: "C101 - Vehiculos y Motos (CR)"). So age se
  `Pricebook2Id` vazio (respeita escolha manual). SUPOSTO A VALIDAR: `CompanyCode__c`
  = prefixo exato do nome do book.
- Multimoeda: cada pais na sua moeda (CRC, HNL, GTQ, USD).

### Inventario e master data (contexto SAP/MuleSoft ja decidido)
- Inventario NATIVO: Location + ProductItem + SerializedProduct. Sync SAP via
  MuleSoft (Vehicle Inventory BOD).
- Disponibilidade: status basico cacheado 1x/dia + **validacao exata real-time no
  fechamento** (decisao Felipe Pajon).
- HU-039 (material master): material e criado/estendido no **SAP**; o SF cria a
  solicitacao e o status volta automatico via MuleSoft (**closed-loop**).
- H7 (SAP/preco) adiado: montar o **shell nativo agora**, ligar a integracao depois.

## 2. O que a agenda com MuleSoft precisa FECHAR

1. **Fronteira estatico x dinamico (confirmar):** Autos/Motos/Frotas/PA = Price
   Book; Repuestos = callout SAP. **PA e 100% estatico ou tambem sincroniza preco
   do SAP?**
2. **SAP -> PricebookEntry (para os estaticos):** o SAP e master do preco de
   Autos/Motos/PA? Como o Price Book do SF e atualizado — **batch diario (upsert de
   PBE via MuleSoft)** ou manutencao manual no SF? Qual a **chave de match**
   (material / SKU / ProductCode / VehicleDefinition)?
3. **Contrato do callout Repuestos (dinamico):** request/response, chave (material),
   moeda, e **modo degradado** (SAP fora -> cache com flag, bloqueia so o commit).
   Reusar MuleSoft Accelerator for SAP.
4. **Granularidade dos Price Books:** hoje e **1 por sociedade**; o modelo de 2
   eixos preve **sociedade x tipo** (Retail/Fleet/Motos/PA). **Decidir** — afeta o
   stamping (Opp_BS_EstampaPricebook) E o feed do SAP.
5. **Multimoeda / multi-pais:** books por pais na moeda local; como o MuleSoft
   entrega os feeds por sociedade (C101 agora; HN/GT/SV/NI/PA no futuro).
6. **Cadencia de sync:** o que fica no **cache diario** (materiais, precos de
   referencia, disponibilidade basica) vs o que e **real-time no commit**; qual o
   gatilho do real-time.
7. **Governanca de master data (HU-039):** fluxo de criacao/extensao de material e
   retorno do preco (closed-loop), e quem e master de cada campo.

## 3. Proximos passos (do PROXIMOS-PASSOS.md, fases 4-6)
- **Fase 4 — Catalogo (eixo produto):** criar Product Catalog por linha, Categories,
  associar Product2, atributos (cilindrada/cor/tracao) via Product Attribute.
- **Fase 5 — Price Books (eixo comercial):** organizar por sociedade x tipo,
  multimoeda; frotas reusam Autos; Repuestos fica fora do Price Book (dinamico SAP).
- **Fase 6 — Compatibilidade de pecas (Repuestos/PA):** tabela VehicleDefinition <->
  peca (dado OEM; custom ate a integracao do catalogo do fabricante via MuleSoft).
- **Estrategia:** montar o shell nativo agora (catalogo + books seed + stamping) e
  **ligar a integracao SAP depois** — sem travar o resto.

## 4. Riscos / pontos de atencao para a reuniao
- **Divergencia de granularidade:** o flow de stamping assume 1 book/sociedade; se
  a decisao for varios books por sociedade (por tipo), o stamping precisa mudar
  (nao so por CompanyCode__c, mas por tipo de venda / Record Type).
- **Match key SAP<->Salesforce:** definir a chave unica (ProductCode/material) e cedo,
  porque tanto o sync de PBE quanto o callout de Repuestos dependem dela.
- **Modo degradado:** confirmar a regra de negocio quando SAP esta fora (cache +
  flag; bloquear so o commit, nao a cotacao).

## Docs oficiais base
- Manage Products in Automotive Cloud, Product2 fields, VehicleDefinition,
  Automotive Cloud Data Model (links em ESTRUTURA-CATALOGO.md).
- MuleSoft Accelerator for SAP (Product / Availability / Order).
