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
| 2 | **Native-first (sem custom objects):** Price book FOB (PricebookEntry) + 3 Decision Matrices (FN, MK, TC — linhas via CSV, sem objeto-fonte) | ⏳ próxima sessão |
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

### Respostas da Isabella (thread Teams, 05/08 18h51) — mudam o modelo

- A lista é **só um exemplo**: o mestre tem as sociedades **C101 e C105** → parâmetros (FN, marcas, origens) são **por sociedade**; Decision Tables ganham a chave `Sociedad`
- **"O preço é apenas um, mas os custos variam de centro para centro"** → preço público por sociedade (não varia por centro); centro segmenta custo/disponibilidade — refinar leitura do contrato HU-028
- **Taxa atualizada todos os dias** → confirma câmbio diário da HU; paridade tem que ser na mesma fecha
- Zero duplicados: confirmado pelo cliente
- **"Los orígenes varían por marca"** — ofereceram a **tabla Marca/Origen/Sociedad** → é a fonte da Decision Table de FN. ACEITAR
- Notas (%FN) e marcas da lista: válidas para C101

### Respostas finais da Isabella (thread 05/08 ~19h) — TODAS as perguntas respondidas

- ✅ **Q = ZPRT confirmado**: "o preço é aquele da coluna Q, que deve ser refletido e será enviado para a Salesforce"
- ✅ **Mark-up é por MARCA + FAMÍLIA da peça** (ex.: Isuzu/Manutenção 122%, Isuzu/Freio 146%) — os 73 valores da lista são combinações marca×família. A coluna que falta na lista é a **família**
- ✅ **Lista é ÚNICA e em USD**; converte-se à moeda local com o **fator de câmbio do dia** (atualizado diariamente) → conversão de saída no fim do waterfall; confirma RN-09
- ✅ **CONTROL AM/FM (FOB 0)**: "cenário real, erro — criação incompleta; deve ser ESCALADO para ser criado corretamente" → valida o estado "sin precio" (RN-21) e o caminho de escalamiento; ótimo caso de teste real
- ✅ **TRANSEJE (margem −12%)**: questão de decimais exibidos (MK real 4,687%) E **margens negativas são legítimas**: "temos apenas um preço, mas os custos variam de centro para centro" — mandou o print do código em todos os centros (preço único 4.702,77; custo real varia por centro: 4.228–5.808, algumas margens negativas)
- 📏 **Escala revelada: o master de materiais da região tem ~150 MIL materiais** → dimensiona HU-030 (sync catálogo), reforça o "não replicar preço" e o argumento da chamada multi-material
- ⏳ Isabella está montando a **tabla Marca/Origen/Sociedad** ("trabalho no quadro e passo")

### Pendências restantes com o GrupoQ (POC)

- [ ] Receber a **tabla Marca/Origen/Sociedad** (em produção pela Isabella)
- [ ] **Família de cada um dos 3 materiais** da POC + tabela marca×família → %MK (a regra real do mark-up; para a POC dá para chavear MK por material, mas o modelo fiel é Sociedad+Marca+Família)
- [ ] **Fecha exata** da lista (tasa 452,51 é de que dia?) — implícito que é "do dia", falta a data
- [ ] Parâmetros da **C105** — fora da POC, dimensiona a escala

### Implicações no desenho (registradas 05/08)

- Decision Matrix `POC_MK` idealmente chaveada por **Sociedad + Marca + Família** (regra real); fallback POC: por material
- Waterfall ganha etapa final opcional: **conversão USD → moeda local pelo câmbio do dia** (a lista é única em USD)
- Margem negativa por centro é cenário legítimo → relevante para HU-065 (pisos/aprovações de desconto) e para não "corrigir" margens no Salesforce
- 150k materiais na região → volumetria para HU-030/HU-119 e justificativa estrutural da chamada multi-material

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

**⚠️ MUDANÇA DE DESENHO 05/08 (HU-046):** print provou que `SerializedProduct.Status` é picklist de SISTEMA — página do campo SEM seção de valores/botão New → "Allocated" NÃO pode ser criado. Pivô aplicado nos flows: máquina de estados única em `Vehicle.Status` (En demostración / En exhibicion / Demo venta — valores já criados pelo Diego); janela 8h = SP.OwnerId + Task aberta "[Demo] Asignación" como marcador; guarda de venta checa Vehicle.Status. Alternativa descartada por ora: campo custom no SP. **Meli precisa saber: a redação da HU muda de novo** (não é SP.Status+Allocated). Pacote reescrito 100% na convenção GRPQM (metadata EN, flows sem prefixo de projeto: ValidateDemoQuota, LogDemoActivity, QuoteBeforeHandler, ReleaseExpiredDemoAssignments, ManageDemoVehicle, ExecuteDemoRequest; textos de usuário ES).

**Ajuste documental pendente:** reescrever RN-54 (aviso por integração, não "fuera del sistema") + cenário da notificação de ida.

**Dúvidas do cliente já respondidas por chat (05/08):** cotización por correo/WhatsApp → história de comunicações (WhatsApp = Digital Engagement, licença à parte); N códigos em 1 cotización → 1 registro por material, UX agrupa; SLA por estado → parametrizar junto com escalamiento.

---

## 3b. HU-046 — Auto Demo/Exhibición (frente do Davi, 05/08)

- **Tarefas v2 sólidas** (planilha no Teams): zero objeto custom, zero campo custom, zero Apex novo (com D9a); CBSF nativo + Vehicle Transfer + 2 screen flows + 2 subflows + CMDT de cupos + custom error em Quote
- **Dúvida do Davi (AllocationStatus) — RESOLVIDA 05/08 (log de describe como evidência)**: `updateable=false / createable=false`, valores Allocated/Deallocated ativos → campo **system-managed**, não gravável por usuário/Flow/Apex; não é permission. **D1/T03 confirmadas**: usar `SerializedProduct.Status` + valor "Allocated" (label Asignado). Meli deve trocar AllocationStatus→Status em ~10 pontos da HU antes do QA e citar API name completo (há 2 campos com valor Allocated agora). Premissa "sale de QuantityAvailable" cai junto; bloqueio garantido pela regra de cotização (T11)
- **Pacote deploy CONSOLIDADO 05/08 (v2)**: `deploy/HU046_faltantes/` — CMDT com 8 campos + **158 registros reais de cupos** (excel 202606 DEMOEXH recebido: CR/GT/HN/NI/PA/SV, 15 marcas, 1.067 demo + 823 exh; open point 1 FECHADO), 2 custom permissions (RequestDemoVehicle + BypassAllocationValidation), notification type. Pendente de dados: mapeo nome→código de sucursal (excel traz nomes) e MaxDemoMileage (open point 4). Fora do pacote por desenho: picklists T03 (UI), FHT T13 (UI), BusinessHours (D9b apenas), flows/CBSF (build do Davi)
- Pós-deploy manual: valores de picklist standard (T03), permission nos PS de gerência, FLS do CMDT
- **Estratégia de empacotamento (05/08)**: quase tudo é empacotável via retrieve→editar→deploy (flows, PS, FHT nos .object, BusinessHoursSettings se D9b). **Única exceção real: picklists standard T03** (Vehicle.Status / SerializedProduct.Status fora da lista de StandardValueSet) → passo manual do runbook. Fluxo: deploy do zip → Davi constrói flows → retrieve final consolidado versionado aqui = artefato de promoção QA/UAT/Prod
- ⚠️ Armadilha encontrada: package.xml do Davi veio com tags TRADUZIDAS pelo auto-translate (tipos/membros/nome) — XML copiado de tela traduzida não sobe; usar sempre o package.xml do zip
- **6 FLOWS CONSTRUÍDOS 05/08 (status Draft, no pacote)**: 2 subflows (ValidarCupo — recebe a contagem do caller; RegistrarTraza — Task padronizada), RT Quote guarda de venta (custom error + bypass; wire do campo Quote→unidade em A_TODO_SetUnidad), Scheduled liberar vencidas (D9a WEEKDAY; ATENÇÃO: scheduled flow só roda Once/Daily/Weekly — 'horário' do T10 não existe nativamente, corrida diária), 2 screen flows (gerência 4 ramas + encargado). TODOs-DAVI concentrados e documentados na description de cada flow
- ⚠️ **T03 executado com API names inconsistentes**: "En exhibicion" criado SEM acento vs existentes COM acento ("En demostración"). Flows usam os valores EXATOS criados; se renomearem, atualizar as fórmulas fx_Estado*. T12 (fin de ciclo) não construído — bloqueado pela D6 (campo de km)

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
2. **Fase 2 (native-first, decidido 05/08 — sem custom objects):**
   - Price book "POC FOB Repuestos" (Pricebook2 standard) + PricebookEntry USD dos 3 materiais (FOB como list price; Product2 dos 3 materiais se ainda não existirem)
   - **Decision Matrix** `POC_FN` (entradas Sociedad+Marca/Origen → %FN; 4 linhas via CSV), `POC_MK` (Sociedad+Material → %MK; 3 linhas), `POC_TC` (Sociedad+Moneda → tasa; 1 linha) — Decision Matrices guardam as linhas nelas mesmas, sem objeto-fonte (≠ Decision Tables, que leem de um objeto)
   - Argumento de governança: a própria RN-10 nomeia "Expression Sets + Decision Matrices" como caminho de escala — a POC nativa testa exatamente o mecanismo previsto
3. Cobrar GrupoQ: perguntas da seção 1 (fecha, grupo fábrica, outlier) e confirmação do template v2 na thread
4. Melisa: entregar versão limpa da HU-028 (oferecida) e RN-54 nova da HU-039
