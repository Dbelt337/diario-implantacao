# Catálogos comerciais — nomes propostos e cadastro no Vlocity CMT (US QUAL-01 "Tetra-pé")

**Data:** 26/08/2026 · **Origem:** Produtos_SalesForce_2.xlsx (abas B2BB2G, B2C, Joel) + Works_B2C_Catalogo.xlsx (abas Catálogo, B2C) — lidas na íntegra.
**Contexto:** pedido prioritário do Davi; US QUAL-01 (W-000056) "Qualificação de catálogo de ofertas comerciais via contexto de elegibilidade (Tetra-pé)" — bloqueada em P-19 (domínios de qualificação com o Joel) e P-17 (solução IBGE), mas a própria US registra: **"estrutura de catálogos/Rule Sets pode iniciar"**.

## 1. O que as planilhas dizem (leitura integral)

Ofertas mapeadas e seus metadados comerciais (aba Joel, que é a visão refinada):

| Oferta | Segmentos | Tipo cliente | Canais | Cidade |
|---|---|---|---|---|
| Smart Firewall (modelos Forti/Huawei/Hillstone/Sophos + VDOM; licença Advanced/Premium; prazo 12–60m; WITO) | B2S/B2B/B2G/B2W | PJ | STORE, TELESALES, FIELD_SALES, ECOMMERCE | N/A |
| Smart Wi-Fi (fabricante Ubiquiti/Huawei/Ruckus; nível Lite/Advanced/Premium; ambiente; prazo; WITO) | B2B/B2G/B2S/B2W (componentes também B2C) | PJ | os 4 | ALL |
| Internet Home e MPE Urbana (GPON/rádio/satélite; 500M–1G; SVA/Serviços Digitais Aya) | B2C/B2S | PF/PJ | os 4 | ALL (por IBGE) |
| Smart Internet Basic | B2B/B2G/B2W | PJ | os 4 | ALL (por IBGE) |
| Smart Internet PME (semidedicado; NOC opcional) | B2C/B2S/B2B/B2G/B2W | PF/PJ | os 4 | ALL |
| Smart Internet Corporativa (porta primária/secundária; 2M–10G; AntiDDoS; NOC Bronze/Prata/Ouro; Fail-Over) | B2B/B2G/B2W/B2C/B2S | PJ/PF | os 4 | ALL |
| Smart PBX (ramais SIP 4–1024; módulos E1/FXS/FXO/GSM; bastidor) | B2B/B2G (aba B2BB2G) | PJ | — | — |
| Streaming (Plataforma; licença Playhub Avançado/Top/Prime; combo com Internet Home Urbana) | B2C | PF | Todos | 0 |

**Tetra-pé = as 4 colunas de qualificação presentes em todas as ofertas: Canal de Vendas · Mercado/Segmento · Tipo de Cliente (PF/PJ) · Município (código IBGE).** É o contexto de elegibilidade da US QUAL-01.

## 2. Proposta de catálogos (por família de produto)

Decisão de desenho (native-first): **catálogo = família/frente de produto; segmento/canal/cidade NÃO viram catálogos** — viram **regras de qualificação (context rules)** aplicadas sobre os catálogos. Duplicar catálogo por segmento (ex.: "Internet B2C", "Internet B2B") multiplica manutenção e é exatamente o que o motor de elegibilidade existe para evitar.

| Code (proposto) | Nome | Ofertas (das planilhas) |
|---|---|---|
| `CAT_INTERNET` | Internet | Internet Home e MPE Urbana, Smart Internet Basic, Smart Internet PME, Smart Internet Corporativa |
| `CAT_SEGURANCA` | Segurança | Smart Firewall (+ Suporte Firewall WITO) |
| `CAT_WIFI` | Wi-Fi | Smart Wi-Fi (+ Suporte Wifi WITO) |
| `CAT_VOZ` | Voz | Smart PBX |
| `CAT_STREAMING` | Streaming | Streaming (Playhub) |
| `CAT_SVA` | Serviços Digitais / SVA | Pacotes SVA Básico/Prime, Serviços Digitais (Aya Bancah/Books/Audiolivro) |

Opcional para navegação por frente (hierarquia de catálogos pai→filho, suportada nativamente): `CAT_VAREJO` (filhos: Internet, Streaming, SVA, Wi-Fi) e `CAT_EMPRESAS` (filhos: Internet, Segurança, Wi-Fi, Voz). TV: reservar `CAT_TV` (citada como exemplo pelo negócio; sem oferta nas planilhas ainda).

Convenção de código: prefixo `CAT_`, sem acento, maiúsculas — o Code é a chave usada pelas APIs (`getOffers` por catalogCode) e pelos DataPacks.

## 3. Como cadastrar (Vlocity Product Console — sem objeto custom)

Objetos do pacote: `vlocity_cmt__Catalog__c` (catálogo; hierarquia via catálogo-pai) e `vlocity_cmt__CatalogProductRelationship__c` (junção catálogo ↔ produto/promoção; matching key `CatalogId__c` + `Product2Id__c`).

1. App Launcher → **Vlocity Product Console** → Dashboard → seção **Product Management → Catalogs** → **New Catalog**.
2. Preencher: **Name** (ex.: Internet), **Code** (`CAT_INTERNET`), descrição, datas de vigência, **Active**. Para hierarquia, criar primeiro os pais (`CAT_VAREJO`/`CAT_EMPRESAS`) e nos filhos apontar o parent catalog.
3. Abrir o catálogo → facet **Products**: adicionar as ofertas (cria os registros de `CatalogProductRelationship__c`). Promoções idem, no facet de promoções.
4. Repetir por catálogo da tabela acima.
5. **Versionamento/CI**: exportar como DataPack (Catalog) no vlocity_build para o repositório — mesmo tratamento dos demais metadados de EPC (alinha com EPC-09, compilação/integridade).

## 4. Tetra-pé = Context Rules (qualificação dos catálogos)

Caminho documentado (Trailhead oficial Industries CPQ Context Rules + guia CME "Defining Context Eligibility Rules"):

1. **Context Dimensions** (Product Console → Dashboard → Rules → Context Dimension) — uma por pé: Canal de Vendas, Segmento de Mercado, Tipo de Cliente (PF/PJ), Município IBGE. (Conferir antes as dimensões que o pacote CMT já traz de fábrica — ex.: Account/market segment — e reaproveitar.)
2. **Context Mapping/Scope** — mapear cada dimensão à fonte do dado: campos de Account/Opportunity/Order (ex.: segmento da conta, canal do usuário/loja, `Cod. Cidade` IBGE do endereço de instalação — dependência P-17).
3. **Entity Filters / Rule Conditions** — condições por valor (ex.: Segmento IN B2B,B2G,B2W; TipoCliente = PJ; IBGE IN cobertura).
4. **Rule Set** tipo **Qualification** — agrupa as condições; um rule set por combinação relevante do Tetra-pé.
5. **Anexar o rule set** ao catálogo, à oferta (produto) ou à promoção — produtos não qualificados caem na aba Disqualified do CPQ Cart e somem do `getOffers` (Digital Commerce) para aquele contexto.
6. Testar com contas de segmentos diferentes: mesma vitrine (`CAT_INTERNET`), resultados diferentes por contexto.

Dependências registradas na US: P-19 (domínios de qualificação — fechar com o Joel a lista de valores por pé) e P-17 (fonte do código IBGE no endereço). **Nada disso bloqueia o passo 3 (criar catálogos) nem o esqueleto dos rule sets.**

## 4a. DECISÃO (26/08): fonte de verdade = aba Joel

Joel confirmou que trabalhou apenas na guia "Joel" → abas B2BB2G e B2C são rascunho anterior, obsoletas. Efeitos:
- **Licença Firewall = Advanced/Premium** (Basic/Advanced descartado) + prazo 12–60m (default 36).
- **Modelagem por atributo direto** (picklists) vence a estrutura Oferta→Serviço→Componente→Opção — alinhada à prática EPC (atributo > SKU, hierarquia ≤4 níveis).
- Prontas para vincular: Smart Firewall, Smart Wi-Fi, Internet Home/MPE Urbana, Smart Internet Basic, Corporativa, PME → `CAT_SEGURANCA`, `CAT_WIFI`, `CAT_INTERNET`.
- **Pendentes de retrabalho pelo Joel (sem fonte de verdade)**: Smart PBX (`CAT_VOZ`), Streaming/Playhub (`CAT_STREAMING`), ofertas de suporte WITO (exclusão deliberada P-02 — decidir se entram na Onda 1), Tipo de Porta/Fail-Over/Bastidor da Corporativa (confirmar se descarte foi intencional), SVA/Serviços Digitais B2B ("a refinar" na própria guia Joel).
- Registrar em ata junto com o P-08 (hierarquia 35.3).

## 5. Famílias de produto (Object Types) — o que precisa

"Família" no EPC = **hierarquia de Object Types** (`vlocity_cmt__ObjectClass__c`) sob Product2, com **herança dinâmica de atributos** por nível e layouts por tipo (EPC-04); **Product Specifications** ligam-se a um único tipo e herdam tudo (EPC-05); `Product2.Family` (picklist padrão Sales Cloud) espelha as famílias para relatórios/forecast.

Ordem de cadastro: (1) ratificar hierarquia 35.3 em ata — P-08; (2) Attribute Categories (EPC-01); (3) Object Types no Product Console (raiz por família: Internet, Segurança, Wi-Fi, Voz, Streaming, SVA — 1:1 com os codes CAT_*), subtipos aninhados; (4) atributos por nível (comum no pai, específico no subtipo; trocar o tipo de um produto depois dessincroniza atributos — ratificar antes); (5) layouts por tipo; (6) Product Specs da Onda 1; (7) picklist `Product2.Family`; (8) DataPacks + compilação de atributos/batch (EPC-09).

Dependência: EPC-01 → EPC-04 → EPC-05 → catálogos + rule sets (QUAL-01) → EPC-09. Nomes de catálogos podem ser cadastrados já; a vinculação de produtos depende das famílias ratificadas.

Fontes adicionais: vlocitysfdc.com (Object Types; Product Specifications), howtosfdc.cloud (criação de Object Types), Apex Hours EPC/Best Practices.

### 5a. Governança por frente (decisão 26/08 — Joel B2B, Rodrigo B2C/B2S)

Ownership por frente vale no nível da **oferta**; **famílias e dicionário de atributos são únicos** e governados em conjunto (P-08/EPC-03). Evidências na própria guia Joel: Internet Home (B2C) e Basic (B2B) compartilham os mesmos atributos; Corporativa/PME atendem as duas frentes; "Pacote SVA (reaproveitado da Banda Larga)". Subtipo por característica técnica (Banda Larga × Dedicado), nunca por segmento — segmento é o pé 2 do Tetra-pé. Redistribuição das pendências: Smart PBX, SVA B2B e Fail-Over/Bastidor/Porta da Corporativa → **Joel**; Streaming/Playhub e SVA B2C/B2S → **Rodrigo** (entregar no template da guia Joel: oferta + atributos diretos + 4 colunas do Tetra-pé). Risco a evitar: cada frente criar seu dicionário → dois atributos "Banda", duas specs de Internet, carrinho e relatórios sem unificação.

## 6. Fontes

- Trailhead — *Meet Context Rules / Create a Qualification Context Rule / Deploy the Qualification Context Rule* (módulo industries-cpq-context-rules)
- Trailhead — *Work with Rules and Manage Catalog Data* (módulo industries-shared-catalog)
- Salesforce Developers (CME) — *Defining Context Eligibility Rules*; *Get Offers by Catalog API* (Digital Commerce); *Create Product Objects* (EPC REST)
- vlocity_build (GitHub vlocityinc) — matching keys de `CatalogProductRelationship__c` para DataPacks/CI
