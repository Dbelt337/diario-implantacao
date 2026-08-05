# Diário de Implantação — GrupoQ · Automotive Cloud

**Última atualização:** 05/08/2026 · **Frente ativa:** HU-028 (Pricing Repuestos & PA) + HU-039 (Criação de Materiais) + POC Simulador de Preços

## Quem é quem

- **Diego (eu)** — analista/arquiteto funcional; analista executor da POC de pricing
- **Melisa Vallejo** — responsável pelas HUs (documentos e respostas aos comentários do cliente)
- **GrupoQ (cliente):** Isabella Hernandez e Andrea Garcia (funcional), Jorge Almendarez (integração/SAP), IT GQ
- Sandbox de trabalho: **DevSales** (`grupoq--devsales.sandbox`)

---

## 1. POC Simulador de Preços (GQ-PV-02-060 / RN-10 da HU-028)

**Objetivo:** provar o waterfall FOB → factor de nacionalización → mark-up no Salesforce Pricing, com paridade contra o cálculo oficial do SAP. Critério de saída: desvio = 0, validado com Finanzas.

### Status das fases

| Fase | Descrição | Status |
|---|---|---|
| 0 | Acessos + feature ligada (Pricing Settings On, Waterfall + Persistence On, tab Pricing Procedures acessível) | ✅ 05/08 |
| 1 | Dados reais do GrupoQ | ✅ 05/08 — lista com 2.207 materiais recebida |
| 2 | Custom objects + 3 Decision Tables (FN por origem, MK, tasa) com dados reais | ⏳ próxima sessão |
| 3 | Context Definition (estender SalesTransactionContext) | ⏳ |
| 4 | Pricing Procedure no builder (clonar Pricing Recipe, montar waterfall **com arredondamento por etapa**) | ⏳ |
| 5 | Simulação (botão Simulate) + prints do waterfall dos 3 materiais | ⏳ |
| 6 | Validação de paridade com Finanzas (planilha pronta) | ⏳ |

### Licenças confirmadas (prints em 05/08)

- **Salesforce Pricing Design Time: 1 seat** e **Run Time: 1 seat** (0 usados, exp. 02/2031) → suficiente para a POC; **escala é via BRE** (27.131 seats Designer + Runtime, 0 usados; 270k chamadas/mês)
- Pendente Fase 0: atribuir as duas PSLs + permission sets ao usuário do Diego
- Cuidado anotado: "Price Waterfall for API Responses" = On é config de POC; **desligar antes de produção** (aviso do próprio help sobre transações grandes)
- Nunca habilitar "Price Tracking History Min/Max" sem decisão (irreversível)

### A descoberta-chave: fórmula real com ARREDONDAMENTO POR ETAPA

Verificada contra as 2.207 linhas da lista real (2.206 exatas):

```
FOB_usd = FOB / tasa                       # se FOB em CRC; tasa única da lista: 452,51
N = arred2(FOB_usd × %FN/100)              # FN por origem: JP/TH 55,51 | KR 50 | MX 42,61
P = arred2((FOB_usd + N) × %MK/100)        # MK por material (73 valores, 88%–234% + 1 outlier 4,69%)
Precio (ZPRT?) = FOB_usd + N + P           # coluna "Precio Calculado", em USD
```

Sem arredondar por etapa, 702 linhas desviam centavos → **o pricing procedure PRECISA arredondar em cada elemento**, senão a paridade nunca fecha.

### Materiais selecionados (planilha `poc-pricing/POC_Materiales_Seleccionados.xlsx`)

1. `0-09809150-0` — Manguera ISUZU (JP/USD, caso típico) → 10,75
2. `00647-26175` — Rol Hyundai (KR/USD, segundo factor) → 133,11
3. `000000000013540923` — Filtro Chevrolet (MX, **FOB em CRC**, testa conversão) → 152,13

### Perguntas pendentes com o GrupoQ (POC)

- [ ] **Fecha de precio** da lista (de quando é a tasa 452,51?)
- [ ] **Grupo/jerarquía de fábrica** que determina o %MK (a lista traz MK por material; a RN-02 diz que vem do grupo — falta a coluna)
- [ ] Confirmar que "Precio Calculado" (USD) = **ZPRT** devolvido pelo `Get_Price_ZGQREF`
- [ ] Outlier `000000000023828034` (TRANSEJE CVT): MK 4,687% e **utilidade −12%** — intencional ou erro de cadastro?
- [ ] Material `000000000086308322` (CONTROL AM/FM): FOB 0, sem moeda — lixo de dados? (bom caso de teste "sin precio" da RN-21)
- [ ] FN do TH = 55,51 (igual JP): factor é por país de origem ou por marca/rota?

> A lista original do GrupoQ **não está neste repo** (preços, custos reais e margens = dado sensível). Fonte: thread Teams "HU-028 Pricing REP Y PA", 05/08/2026. Re-análise: `poc-pricing/scripts/analisar_lista_grupoq.py`.

---

## 2. HU-028 — Pricing Repuestos & PA (REV-BA)

**Desenho técnico fechado** (doc `arquitetura/Arquitectura_HU028_HU039.docx`): preço nunca replicado, resolvido online via RFC `Get_Price_ZGQREF` (MuleSoft), LWC único (RN-19), congelamento por fecha de precio em campos da linha, price book técnico com entries placeholder (gotcha PricebookEntry), org multicurrency.

**Pendências documentais (Melisa aguarda retorno — já respondido por chat em 05/08):**
- RN-10 e RN-22 corretas na substância; limpar: fragmento órfão pós-RN-10, texto velho do GQ-PV-02-060 na seção de IDs (cita serviço SAP e seção "Fuera del alcance" inexistente), frase "es un servicio distinto" na RN-18, bullet antigo duplicado no ALCANCE
- Redução ~25-30% sem perda de escopo: remover duplicatas literais (RN-12 2x, dois "Escenario 8", Escenario 7 sem "Entonces", passos 1 e 6 do Flujo duplicados) + fusões RN-03+11+20, RN-04+05+08, RN-09+17, Escenarios 10-12 (atualizar refs cruzadas)
- Contrato do serviço ok; ajustar: KUMU em linha própria (é subtotal, não desconto), padronizar "precio neto" vs "precio final", incluir Marca na entrada opcional (ou tirar do passo 1)
- [ ] **Jorge Almendarez**: confirmar que o RFC atende preço dinâmico REP **e** listas PA na mesma chamada

**Oferecido e não iniciado:** versão limpa consolidada do docx da HU-028.

---

## 3. HU-039 — Solicitud de Creación de Material (V3)

**Desenho fechado** (diagrama `arquitetura/HU-039_flujo.svg/png`, embutido no docx):
- Solicitud = **Product2 nativo** (Record Types Original/Comodín, IsActive=false); mesmo registro vira material; código de parte/comodín em campo próprio; `ProductCode` reservado ao MATNR (SAP = System of Record)
- **Estados simplificados: Pendiente → Material Creado / Rechazado** (elimina "En revisión"); RN-40 sai (pedido Isabella 05/08)
- **Ida:** Platform Event → MuleSoft → worklist SAP (cliente NÃO quer e-mail; pediu integração — decidido 05/08)
- **Volta:** callback estendido com tipo de evento (`creado` + MATNR | `rechazado` + motivo), upsert por External ID
- Caminho automático do Tempo 1: função Z existente **`ZHYB_OBM_PRECIO_VTA_NO_MAESTRO`** (cria material da tabla Z de fabricantes + preço estimado; prefixo HYB sugere origem Hybris → provavelmente já RFC)
- PA sem mudança (aprovação Catman → Director → VP no Salesforce)

**Perguntas para a call de arquitetos / IT GQ:**
- [ ] `ZHYB_OBM_PRECIO_VTA_NO_MAESTRO` é RFC-habilitada? Assinatura? Cria por sociedade/centro?
- [ ] Onde a notificação de ida aterrissa no SAP: tabla Z + transação, workflow, ou **SAP MDG** (GrupoQ tem?)
- [ ] MATNR: numeração externa (= código de parte) ou interna?
- [ ] Código Comodín: quem cunha e qual convenção de formato?
- [ ] Frequência/backoff de reintentos + mecanismo e SLA de escalamiento (HU-119)
- [ ] Performance HU-028: 3s com 20 materiais; reconsulta multi-material ao trocar moeda

**Ajuste documental pendente:** reescrever RN-54 (aviso por integração, não "fuera del sistema") + cenário da notificação de ida.

**Dúvidas do cliente já respondidas por chat (05/08):** cotización por correo/WhatsApp → história de comunicações (WhatsApp = Digital Engagement, licença à parte); N códigos em 1 cotización → 1 registro por material, UX agrupa; SLA por estado → parametrizar junto com escalamiento.

---

## 4. Inventário de artefatos deste repo

| Caminho | Conteúdo |
|---|---|
| `arquitetura/Arquitectura_HU028_HU039.docx` | Doc de arquitetura (ES) para a call — resumo, camadas, perguntas, referências |
| `arquitetura/HU-039_flujo.svg` / `.png` | Diagrama do fluxo HU-039 (Salesforce \| MuleSoft \| SAP, dois tempos) |
| `poc-pricing/POC_Materiales_Seleccionados.xlsx` | 3 materiais reais + aba de paridade pré-preenchida |
| `poc-pricing/POC_Pricing_Datos_y_Paridad.xlsx` | Template vazio v2 (fórmula "Resultado" corrigida) |
| `poc-pricing/scripts/analisar_lista_grupoq.py` | Reproduz o mapeamento/validação da lista do GrupoQ |
| `poc-pricing/scripts/gerar_template_paridade.py` | Gera o template xlsx (OOXML à mão — ambiente sem openpyxl) |
| `deploy/` | (sessão de abril) Flow `Buscar_Lead_GrupoQ_FA` pronto para deploy |

## 5. Próxima sessão — por onde retomar

1. Atribuir PSLs de Pricing ao usuário (sobra da Fase 0)
2. **Fase 2**: criar `POC_FactorNacionalizacion__c`, `POC_MarkupMaterial__c`, `POC_TipoCambio__c` no Object Manager + carregar valores reais (FN: JP/TH 55,51 · KR 50 · MX 42,61; MK: 193/206/189; tasa 452,51) + Decision Tables usage type Pricing
3. Cobrar GrupoQ: perguntas da seção 1 (fecha, grupo fábrica, outlier) e confirmação do template v2 na thread
4. Melisa: entregar versão limpa da HU-028 (oferecida) e RN-54 nova da HU-039
