# Dossiê de decisões — Catálogo EPC (Brasil TecPar / EVO)

**Última atualização:** 19/08/2026
**Fontes cruzadas:** Manual de Especificação Técnica v2.2 (normativo, decisões de 05/08) · Apostila Workshop v2.2 · US_modelo_refinos_v4 (SysMap, decisões de 14/08) · Planilha Produtos_SalesForce.xlsx (abas Joel e B2BB2G).

**Ordem de precedência quando houver conflito:** `decisoes_premissas_e_correcoes_v1.md` (não temos cópia) → Manual v2.2 → v4 refinos (mais recente que o manual: onde registrar decisão de 14/08, o v4 vale) → planilha (insumo AS-IS, nunca fonte normativa).

---

## 1. Decisões fechadas (parametrizar sem esperar ninguém)

| # | Decisão | Fonte citável |
|---|---|---|
| D1 | Prefixo de picklist é **`PL_`** (o `PKL_` no texto do v4 é typo) | Manual §38.6, §39.4 |
| D2 | Object Type: padrão **`OT_ + DOMÍNIO + CAMADA`** no campo Name (não existe campo Code); sufixo indica camada do catálogo (OFFER / PRODUCT_SPEC / CFS / RESOURCE), não os produtos associados. Não cortar para `INTERNET_HOME` | Manual §35.3; doc oficial Salesforce (Product Designer: só Name + Parent) |
| D3 | Hierarquia normativa de OT é a da **§35.3** (a §6.1 do mesmo manual é anterior e diverge — isso É a P-08); ratificar em ata da Onda 0, **antes** de criar subtipos (layout é herdado por cópia na criação) | Manual §35.3 vs §6.1; Trailhead (layout não propaga após criação) |
| D4 | **P-01:** NOC_TIER default = **BRONZE** (códigos em inglês BRONZE/SILVER/GOLD, rótulos PT). Joel marcou Prata — não prevalece | Manual §39.2, §35.4 |
| D5 | **P-05:** IPv4 = **atributo** ("child só se exigir linha SAP/lifecycle separado; atributo por padrão") | Manual §35.4; gabarito apostila cap. 43 Bloco B ex.4 |
| D6 | **P-06/P-15:** Fail-Over confirmado, tiers STANDARD/PROFESSIONAL/FULL, exige Porta Secundária via `RULE_FAILOVER_REQUIRES_SECONDARY` (declarativa, nunca código de tela). Diversidade de rota: fora de escopo nesta onda | Manual §39.2, §45.3, §37.3 apostila |
| D7 | **P-16:** resolução do Billing Material Profile na **Quote** (Decision Table/Expression Set, whitelist LC-04, sem Apex); agregação na camada de integração; **nunca no OM** | Manual §44.7, regra 65 do livro de regras |
| D8 | **P-17:** cidades IBGE via `GeographicCommercialPolicy` — objeto/Decision Table com vigência e status por registro (`EffectiveFrom/Until`, Draft/Active/Past, `GeographicPolicyVersion` persistida). Descarta custom metadata | Manual §37.2; matriz §29 GEO-001 |
| D9 | **P-18:** Group Promotion ID = **`CommercialGroupId`** (única chave de agrupamento comercial; Applied Promotion é registro histórico; `PromotionCode` vai por linha no contrato SAP) | Manual §17.4, BR-056, §21.2 |
| D10 | **PL_WIFI_AP_TYPE não deve ser criada.** O composto marca-tier-ambiente viola menor entidade (§3.1) e a EPC-08 o proíbe "em qualquer cenário". As 12 combinações viram matriz de ABP. **Achado da planilha:** as 12 combos são só Ubiquiti (6) + Huawei (6); Ruckus está como Marca mas não tem nenhuma combinação — o composto está incompleto na própria fonte | v4 EPC-08; Manual §3.1; planilha aba Joel R57–R73 |
| D11 | Ajuste promocional de bundle sempre em **linha faturável de preço estável** (Fone/SVA), nunca na Internet | BR-053; Manual §10.5, §11.1, Anexo A |
| D12 | Defaults confirmados: GPON, IPV4_FIXED (IPv4 válido e fixo), IPv6 NONE, Anti-DDoS inativo (STANDARD quando ativado), UPLOAD_PROFILE STANDARD, prazo 36 (se P-11 confirmar aplicação) | v4 EPC-02 + Manual §38.6/§39.1 |
| D13 | ServiceTag: gerada na criação da Quote Line via Flow/Integration Procedure (LC-01, sem Apex), formato `PREFIXO-sequencial`, única, imutável, nunca reutilizada, propagada por Field Mapper nos 4 sentidos | Manual §5.3.4, §17.5 |

## 2. Decisões por não-objeção (enviar "salvo objeção até [data], seguiremos com X")

| # | Proposta | Justificativa | Destinatário |
|---|---|---|---|
| N1 | **P-04 Wi-Fi → Plano A (B2BB2G):** `PL_WIFI_AP_CLASS` (AP na CPE, Home, Lite, Pro, HD, XG, Outdoor) + `PL_WIFI_VENDOR_WITO` (Unifi, Aruba, Cisco Airnet, Cisco Meraki, Ruckus) | Recomendado no v4; composto Joel proibido e incompleto (Ruckus sem combos) | Architecture Board / Davi |
| N2 | **P-03 Firewall → Plano A (atributo `EQUIPMENT_MODEL` + ABP)**, condicionado a material SAP único da locação | Recomendado no v4; 34+ children viola simplicidade (§3.3); critério do gabarito Anti-DDoS (cap. 44.3) | Architecture Board + Pricing |

## 3. Perguntas fechadas pendentes — QUEM RESPONDE O QUÊ

### Coisas do Joel (dono da planilha / produto)
| Pendência | Pergunta fechada a enviar |
|---|---|
| **P-13** | "A anotação NFE#1 na opção Upload Simétrico (B2BB2G) é nota de revisão ou default pretendido?" (o default STANDARD já está confirmado nos dois documentos — só falta o significado da anotação) |
| **P-19** | "Domínios de qualificação (canais, mercados/segmentos, tipos de cliente) — o envio formal por e-mail tinha prazo de segunda ao meio-dia, já vencido. Qual o status?" |
| **P-18** (residual) | Estratégia final do campo com o Magnum — mas a resposta técnica já existe: é o `CommercialGroupId` (D9). Ao Joel cabe só ratificar |
| Planilha | "As 12 combinações de Tipo Wi-Fi não cobrem a Ruckus (listada como Marca). Falta completar ou a Ruckus sai?" — só relevante se P-04 escolher Plano B |

### Coisas do Product Owner / Pricing / Engenharia (não são suas nem do Joel)
| Pendência | Pergunta fechada | Decisor |
|---|---|---|
| **P-07** | "Da grade AS-IS do §40, quais bandas entram ativas? E os 7 valores a R$ 682,10 (BW_20 a BW_40): consolidar, manter por contrato ou Past?" | Pricing |
| **P-10** | "Licenciamento Smart Firewall: Basic/Advanced com Basic default (B2BB2G) ou Advanced/Premium com Advanced default (Joel)?" | Product Owner |
| **P-11** | "As 3 variantes VDOM e o Prazo de Licenciamento (só na aba Joel) entram na Onda 1? O prazo 36 vale também para Wi-Fi?" | PO + Arquitetura |
| **P-12** | "Dos 13 meios de acesso da B2BB2G, quais entram ativos na Onda 1? (Joel lista 8)" | PO + Engenharia |
| **Nova-1** | "Banda Corp: default BW_100 (v4/Joel) ou sem default geral (Manual §39.1)?" | Product Owner |
| **Nova-2** | "PL_UPLOAD_PROFILE: o valor LITE (só no Manual §46.2) entra na Onda 1? v4 lista só Padrão/Plus/Simétrico/Double" | Product Owner |

### Coisas técnicas (Diego responde direto, sem depender de ninguém)
- Nomenclatura de OT e picklists (D1–D3), estrutura da carga, ordem de construção (§41.1).
- Mecânica de herança (atributos dinâmicos, layout por cópia) e por que fechar nomes antes dos subtipos.
- Batch jobs de compilação (`EPCProductAttribJSONBatchJob`, `EPCFixCompiledAttributeOverrideBatchJob`) — obrigatórios após atribuição de atributos em OT com produtos (crítico na org RadarDev, que tem legado).
- Arquitetura de billing consolidado (D7), IBGE (D8), ServiceTag/Field Mapper (D13).
- Por que o desconto vai na linha do Fone (D11) — mecânica, não política.

## 4. Erratas e bloqueadores a registrar com o Davi

1. **Errata BR-053:** o UC-03 do Manual e o cap. 24.3 da apostila dizem "desconto na Internet"; contradizem BR-053, §10.5, §11.1 e Anexo A (linha estável do Fone). Vale o BR-053.
2. **Bloqueador BR-058 (§46):** Smart Corp não vai a release sem especificação descritiva aprovada (Produto + Jurídico) dos valores de `NOC_TIER` — e também FAILOVER_TIER, ANTI_DDOS_PROFILE, UPLOAD_PROFILE, RACK_SIZE, SVA_TIER, DIGITAL_SERVICES_TIER. Abrir a frente antes do UAT.
3. **Conflito de datas:** Manual é de 05/08; v4 incorpora 14/08. Caso concreto: `ACCESS_TECHNOLOGY` — o Manual diz "derivado da serviceability", mas P-14 (decidida em 14/08) removeu a derivação automática da Onda 1: default no catálogo com override, preenchido pela engenharia. Parametrizar pelo v4.

## 5. Respostas prontas para desdobramentos prováveis do Davi

**"Por que não seguir a planilha do Joel, que é mais recente que o manual?"**
A planilha é insumo AS-IS, não documento normativo — o próprio Manual (§40) classifica a grade como "extrato AS-IS — sanitizar antes da importação — não carregar diretamente". A reconciliação oficial das duas visões é a tabela EPC-02 do v4, que incorpora as decisões de 14/08.

**"Quem aprova o Plano A do Wi-Fi?"**
Architecture Board (P-04). Estamos propondo por não-objeção porque é o desenho que o próprio documento de refinos recomenda; se houver objeção, os dois planos estão descritos na EPC-08 com trade-offs.

**"O que muda se escolhermos o Plano B (modelo Joel)?"**
Marca, tier e ambiente viram 3 atributos ortogonais + regra de compatibilidade; a matriz de ABP cresce e é preciso completar as combinações da Ruckus (hoje ausentes). O composto de 12 valores continua proibido mesmo no Plano B.

**"Por que Bronze se o Joel marcou Prata?"**
A hierarquia de decisão do Manual coloca a regra de negócio aprovada no documento acima de qualquer outra fonte, e o §39.2 é explícito: "NOC Premium é obrigatório e Bronze é o default". Mudar para Prata é decisão do PO (P-01), com impacto de preço — até lá, parametrizamos Bronze.

**"O que é o BR-058 na prática?"**
Cada valor de NOC_TIER (e dos demais tiers) precisa de ficha descritiva aprovada: `included_features`, `excluded_features`, `sla_commitments` (disponibilidade, tempo de resposta por severidade, reparo, janela), `operational_conditions`, `contractual_notes`. Sem isso a validação `PICKLIST_VALUE_SPECIFICATION_MISSING` bloqueia o release. É a resposta contratual à pergunta "o que o cliente está comprando".

**"Quando podemos começar a carga?"**
Já, na ordem do §41.1: (1) OTs base e layouts → (2) campos, atributos e picklists com valores fechados (D12) → (3) Specifications → (4) Offerings. Bloqueado até decisão: valores de banda Corp (P-07), licenciamento (P-10), meios de acesso ativos (P-12), Wi-Fi (P-04 se houver objeção). Após cada bloco de atribuição de atributos, rodar os batch jobs de compilação.

**"Qual o risco de renomear os OTs depois?"**
Layout é herdado por cópia no momento da criação do subtipo — mudanças no pai não propagam. Mudar parent após existirem descendentes é proibido sem ADR e plano de reconstrução (§35.3). Por isso a nomenclatura fecha na Onda 0.

---

## 6. Works criadas no Agile Accelerator (registro)

Backlog existente (19/08): W-000051 (EPC-01 Attribute Categories) · W-000052 (EPC-04 Object Types) · W-000053 (EPC-05 Product Specifications) · W-000054 (EPC-09 Batch jobs/integridade) · W-000055 (EPC-03 parcial, sem atributos WITO).

### US QUAL-01 (P) — Qualificação Tetra-pé (pedida pelo Davi em 19/08)

**Resposta dada sobre nomes de catálogo:** catálogo é por MERCADO, não por família nem por canal (Manual §9.1, antipadrão §28.3): `CAT_B2C_EVO, CAT_B2S_EVO, CAT_B2B_EVO, CAT_B2G_EVO, CAT_WHOLESALE_EVO`. Internet/TV/Streaming são **Categorias** de navegação dentro do catálogo (apostila §11.2). B2G fora do e-commerce, sem análise de crédito (`CREDIT_NOT_REQUIRED`).

**Escopo da work:** 5 catálogos + categorias por família + máx. 4 Rule Sets globais (QUAL_MERCADO, QUAL_CANAL, QUAL_TIPO_CLIENTE, QUAL_CIDADE) aplicados a Products e Promotions; cidade→zona via GeographicCommercialPolicy (P-17); preços B2C/B2B por Price Lists sem duplicar oferta. Bloqueio: domínios de valores aguardam P-19 (Joel). Não depende da EPC-02.

**ACs:** (1) captura dos 4 parâmetros; (2) filtro CityIBGECode→AvailabilityZone sem Oferta×Cidade; (3) máx. 4 Rule Sets globais; (4) qualificação antes, viabilidade só após escolha da oferta; (5) preço por Price List sem duplicação de produto.
