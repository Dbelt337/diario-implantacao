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
- ✅ **DEPLOY 100% VERDE (05/08 23h13)**: 177 componentes — 158 cupos, 6 flows (Draft), CMDT 8 campos, 2 permissions, notification type; MaxNum__c removido via destructive. Restam: ativação dos flows na ordem (LogDemoActivity + ValidateDemoQuota → QuoteBeforeHandler → ReleaseExpiredDemoAssignments → telas), TODO-DAVI nos flows, permissions nos PS, FLS do CMDT, FHT
- **Estratégia de empacotamento (05/08)**: quase tudo é empacotável via retrieve→editar→deploy (flows, PS, FHT nos .object, BusinessHoursSettings se D9b). **Única exceção real: picklists standard T03** (Vehicle.Status / SerializedProduct.Status fora da lista de StandardValueSet) → passo manual do runbook. Fluxo: deploy do zip → Davi constrói flows → retrieve final consolidado versionado aqui = artefato de promoção QA/UAT/Prod
- ⚠️ Armadilha encontrada: package.xml do Davi veio com tags TRADUZIDAS pelo auto-translate (tipos/membros/nome) — XML copiado de tela traduzida não sobe; usar sempre o package.xml do zip
- **6 FLOWS CONSTRUÍDOS 05/08 (status Draft, no pacote)**: 2 subflows (ValidarCupo — recebe a contagem do caller; RegistrarTraza — Task padronizada), RT Quote guarda de venta (custom error + bypass; wire do campo Quote→unidade em A_TODO_SetUnidad), Scheduled liberar vencidas (D9a WEEKDAY; ATENÇÃO: scheduled flow só roda Once/Daily/Weekly — 'horário' do T10 não existe nativamente, corrida diária), 2 screen flows (gerência 4 ramas + encargado). TODOs-DAVI concentrados e documentados na description de cada flow
- ⚠️ **T03 executado com API names inconsistentes**: "En exhibicion" criado SEM acento vs existentes COM acento ("En demostración"). Flows usam os valores EXATOS criados; se renomearem, atualizar as fórmulas fx_Estado*. T12 (fin de ciclo) não construído — bloqueado pela D6 (campo de km)
- **DEPLOY v3.2 (05/08 ~23h40)**: 177 verdes de novo; ÚNICAS falhas = 2 Permission Sets ("Description: data value too large, max length=255") → descriptions encurtadas para ≤255 na v4. Lição: PS description tem limite 255.
- ✅ **RODADA 2 DE DESCRIBES RECEBIDA (05/08) — WIRE A FECHADO**: (1) QuoteLineItem: referências só CreatedBy/LastModifiedBy/Quote/PricebookEntry/OpportunityLineItem/Product2 — SEM lookup de unidade; (2) **Opportunity TEM `Vehiculo__c → Vehicle`** (custom já na org!) + OriginatingLeadId__c, OriginatingDigitalAdvisor__c, DiscountApprover__c; (3) Vehicle: referências só AssetId/CurrentOwnerId/VehicleDefinitionId/OdometerReadingUomId — sem lookup custom, sem campo de marca/sucursal. **Decisão: guarda de venda migrou de Quote para `OpportunityBeforeHandler`** (before-save Create+Update, entry Vehiculo__c not null, dispara só quando o link muda vs $Record__Prior, bypass BypassAllocationValidation, custom error se Vehicle.Status ∈ {En demostración, En exhibicion}). `ExecuteDemoRequest` agora grava `Vehiculo__c` na Opportunity de liberação (release atualiza Status ANTES de criar a Opp → guarda não bloqueia). QuoteBeforeHandler (Draft, órfão) removido do pacote + destructive_v2 para apagar da org.
- **DEPLOY v4: 2 flows VERDES (OpportunityBeforeHandler criado, ExecuteDemoRequest atualizado); PS falharam de novo: "Permission Read SerializedProduct depends on permission(s): Read Product2" → adicionado Product2 read nos 2 PS (v4.1); delta agora só com os 2 PS**
- v4.1 falhou de novo: "Permission Read Vehicle depends on Read Asset" → v4.2 fechou a CADEIA inteira preventivamente (Asset, Account, Contact, Product2, VehicleDefinition — todos read-only). **Lição Automotive Cloud: Vehicle→Asset→Account/Contact e SerializedProduct→Product2 são dependências de deploy de objectPermissions.**
- ✅✅ **PACOTE HU-046 100% NA ORG (05/08 23h56)**: os 2 PS criados (0PSWK000001DnlV4AS / 0PSWK000001DnlW4AS). Inventário completo deployado: CMDT + 158 cupos + 2 custom permissions + notification type + 6 flows (Draft) + 2 PS. `HU046_faltantes.zip` = fonte da verdade para promoção QA/UAT.
- **RESTA (runbook pós-deploy, maioria é clique de Setup do Davi)**: (0) ✅ FEITO 06/08: destructive_v2 aplicado, QuoteBeforeHandler apagado da org; (1) VERIFICAR se já existe flow before-save de Opportunity na org → se sim, MERGE do OpportunityBeforeHandler nele (convenção 1 handler/objeto); (2) atribuir PS aos usuários (Management→gerentes/director/VP; Execution→encargados de piso; BypassAllocationValidation→PS de integração/admin); (3) FHT em Vehicle + SerializedProduct (Status, Owner) — T13; (4) App Page "Vehículos Demo" (Manage Demo Vehicle, component visibility $Permission.RequestDemoVehicle) + App Page/tab do Execute Demo Request, tabs na app GrupoQ Ventas; (5) ativar flows na ordem: ValidateDemoQuota + LogDemoActivity → OpportunityBeforeHandler → ReleaseExpiredDemoAssignments → 2 telas; (6) mini-describe VehicleDefinition (wire B: marca) + confirmar se Location* do Vehicle carrega nome da sucursal; (7) dados: BranchCode C0xx, MaxDemoMileage (D6) → destrava T12; (8) grupos GRP_Sucursal_* faltam para GT/HN/NI/PA (rollout, wire floorManagerId); (9) Meli reescreve HU-046 no modelo Vehicle.Status ANTES do QA.
- **PACOTES v4 (05/08)**: `HU046_delta.zip` (só 4 componentes: 2 PS corrigidos + OpportunityBeforeHandler novo + ExecuteDemoRequest atualizado) + `HU046_destructive_v2.zip` (apaga QuoteBeforeHandler). Pacote completo `HU046_faltantes.zip` atualizado (idempotente). Resposta ao "preciso de tudo?": NÃO — os 177 verdes não precisam re-deploy; delta basta.
- **WIRE B AINDA ABERTO (marca/sucursal no ManageDemoVehicle)**: Vehicle não tem campo de marca/sucursal e não tem lookup custom. Única rota nativa: `VehicleDefinitionId → VehicleDefinition` (marca?) — falta 1 mini-describe de VehicleDefinition (fields + referências). Sucursal: candidatos são os campos Location* do Vehicle (rodada 1) — confirmar se carregam o NOME da sucursal do excel de cupos. Sem isso, marca/sucursal seguem digitadas na tela (funcional, mas com risco de digitação).
- **RODADA 3 DE DESCRIBES (06/08) — wire B esbarrou em DADOS, não em modelo**: (1) VehicleDefinition: SEM campo de marca (só Name, ModelCode, VariantName, BodyType, ProductId→Product2, GeoCountryId→GeoCountry; zero custom) → próxima parada da marca é o Product2 (Family ou campo custom) — script rodada 4 em deploy/scripts/describe_product2_marca.apex; (2) Vehicle.Location*: campos existem (LocationCity/State/Country/CountryCode...) mas nos 5 Vehicles reais só LocationCountry/CountryCode vêm preenchidos ("Costa Rica"/CR) — LocationCity NULA em todos; e os 5 são dados de TESTE (RPA/Prueba, todos com o MESMO VehicleDefinition 1PqWK0000000MoX0AU). CONCLUSÕES: País derivável já (LocationCountryCode = chave Country do CMDT); Sucursal NÃO derivável hoje — o dado não é carregado no Vehicle; decisão v1: manter marca/sucursal digitadas na tela (funcional) e fechar a derivação (wire B v2) quando a carga real de inventário definir onde marca/sucursal vivem (LocationCity? Location/T02? Product2?). Registrar como premissa de dados para HU-030/carga de veículos: LocationCity DEVE carregar o nome da sucursal igual ao excel de cupos.
- **RODADA 4 (06/08) — WIRE B TEM ROTA NATIVA COMPLETA**: (1) Product2 tem `Family` (picklist, ex. "Autos"), **`BusinessBrandId → BusinessBrand`** e `MakeName` (string) → **MARCA = Vehicle → VehicleDefinition.ProductId → Product2.BusinessBrandId → BusinessBrand.Name** (produtos se ligam à marca via BusinessBrand, confirmado pelo Diego); (2) **SUCURSAIS SÃO ACCOUNTS** (export do Diego, 28 contas): hierarquia ParentId de 4 níveis **GrupoQ Holding → país (GrupoQ Costa Rica) → sociedade (C101/C105!) → dealer** ("GrupoQ Ayarco", "GrupoQ La Uruca", "GrupoQ Lindora"...), com BusinessProfile por dealer (BusinessPartnerType = Sales Dealer) e picklist de nível (AccountLevel__c aparece nas suggestions) → **SUCURSAL da unidade = Vehicle.CurrentOwnerId → Account (dealer)**. As sociedades C101/C105 da HU-028/POC são o 3º nível da mesma hierarquia — estrutura unificada! PENDÊNCIA DO JOIN: nomes dos dealers ("GrupoQ La Uruca") ≠ BranchName do CMDT ("Uruca") → precisa de-para; pedir Copy(CSV) do export para gerar mapping e preencher BranchCode__c (com AccountNumber/código do dealer se existir, senão nome oficial da Account). Derivação automática nas telas = v2, quando inventário real tiver CurrentOwner/BusinessBrand populados (dados de teste estão vazios).
- **OpportunityBeforeHandler "não entrou" — causa real: rollbackOnError (06/08)**: Diego deploya sempre com rollback on error → no deploy v4 em que os 2 PS falharam, os componentSuccesses (2 flows) foram REVERTIDOS junto. ⚠️ LIÇÃO: num deploy com rollbackOnError=true, success:true por componente NÃO significa que persistiu — só o deploy 100% verde persiste. OpportunityBeforeHandler subiu de verdade via zip standalone (06/08 00h31, id 301WK00002VP22CYAT). Consequência: ExecuteDemoRequest atualizado (Vehiculo__c na Opportunity) TAMBÉM foi revertido naquele deploy → reenviado standalone `HU046_flow_execdemo.zip`.
- **Davi questionou a guarda na Opportunity (06/08, Teams)**: "na HU pede impedimento de seleção na Quote"; "não seria QuoteLineItem essa trigger?" — Diego respondeu "Sim" mas a resposta correta é NÃO: QLI só referencia Product2 (MODELO, não unidade/VIN) — describes provam que nem Quote nem QLI têm link com a unidade serializada; bloqueio de demo é POR UNIDADE. Posição correta: (1) guarda dura = OpportunityBeforeHandler via Vehiculo__c (único anchor nativo); (2) o "impedimento de seleção" da HU se resolve na ORIGEM = filtro do CBSF/busca de inventário para venda exclui Status demo/exh (Esc.10: visível mas não vendível) — UX melhor que erro depois; (3) QLI trigger só seria possível criando campo custom de unidade na QLI (contra o desenho zero-custom-field); (4) mais um ponto para a reescrita da HU pela Meli: o ponto de enforcement muda junto com o pivot para Vehicle.Status.
- **Validação vs doc oficial (06/08)**: docs Salesforce 403 no proxy; evidência empírica da própria org: Automotive Cloud instalado adiciona ManufacturingProgramId na Opportunity e NENHUM link standard de Vehicle em Opportunity/Quote/QLI → vínculo negócio↔unidade é decisão de implementação (padrão da indústria: lookup na Opportunity, VIN entra no desking) — Vehiculo__c do projeto é o desenho correto.
- **SEMÂNTICA DO Vehiculo__c CONFIRMADA (06/08, Where is this used?)**: FlexiPages GQ Opportunity Retail + Repuestos & PA, layouts (Opportunity Layout, Formato de Vehículo), report type OpportunitiesWithPreferredSeller e VALIDATION RULE **Opp_Retail_Vehiculo_Cotizacion** — Opp Retail exige Vehiculo__c para cotizar → campo = UNIDADE DO NEGÓCIO, preenchida ANTES da cotización (não é test drive/veículo de interesse). A guarda OpportunityBeforeHandler bloqueia ANTES da Quote existir → cobre o "impedimento de seleção na Quote" da HU por construção. O flow aparece na lista de referências (deploy confirmado). Pendente 1 clique: abrir a validation rule e confirmar fórmula/estágio.
- **REFINO DA GUARDA (06/08, queries do Diego)**: Description do Vehiculo__c (criado por Santiago Pelaez 03/07): "vehículo asociado a la oportunidad de Repuestos/PA. Poblado por la búsqueda de vehículo (VIN/Placa/Código/Modelo)" → o campo NASCEU para Repuestos/PA (veículo do cliente que recebe peças) e é usado TAMBÉM nas Opps Autos (dados: 2 RepuestosPA + 2 Autos, tudo teste apontando p/ "Prueba Demo"). Cenário legítimo: Opp Repuestos/PA vinculando unidade demo (acessórios para o carro demo) NÃO pode ser bloqueada → **OpportunityBeforeHandler v2: guarda restrita a RecordType.DeveloperName = GQOpportunitiesAutos** (venda de veículos). Zip reenviado. Extensão futura: se surgir RT de Usados, avaliar incluir.
- **VALIDATION RULE LIDA (06/08) — desenho 100% confirmado e alinhado**: `Opp_Retail_Vehiculo_Cotizacion` (HU-025 R1 B3.7, Santiago Pelaez): AND(RT=GQOpportunitiesAutos, NOT($Permission.Bypass_Gates_Automacao), OR(Cotización Confirmada sem OLI, **Reserva Confirmada com Vehiculo__c em branco**)). Aprendizados: (1) em Autos a cotización é NÍVEL MODELO (exige OpportunityLineItem) e a UNIDADE entra na **Reserva Confirmada** — exatamente o padrão indústria (quote modelo, VIN no desking); é aí que a guarda morde; (2) a VR usa o MESMO scoping por RT que a guarda v2 — consistente; (3) **a org já tem padrão de bypass: custom permission `Bypass_Gates_Automacao`** → OpportunityBeforeHandler v3: decisão de bypass agora aceita BypassAllocationValidation (demo-específico) OU Bypass_Gates_Automacao (padrão org) — quem já bypassa os gates da HU-025 bypassa o nosso também, sem novo setup de integração. Cadeia final para a HU (Meli): CBSF filtra seleção → guarda bloqueia link de unidade demo (RT Autos) → VR exige unidade na Reserva Confirmada.
- **Exposição das telas (respondido 05/08)**: App Page "Vehículos Demo" (App Builder) com componente Flow → Manage Demo Vehicle + component visibility `{!$Permission.RequestDemoVehicle}`; 2ª App Page/tab para Execute Demo Request; Quick Action tipo Flow no Vehicle fica para v2 (junto com CBSF/T01). Personas: Manage = gerente de sucursal/marca, director, VP (PS_Demo_Vehicle_Management); Execute = encargado de piso (PS_Demo_Vehicle_Execution).

### Balanço de DESENVOLVIMENTO da HU-046 (06/08) — TUDO CONSTRUÍDO
- ✅ Construído e NA ORG: CMDT DemoCapacityConfig (8 campos) + 158 cupos, 2 custom permissions, notification type, 2 PS (com cadeia de dependências), 6 flows, destructives aplicados (MaxNum__c, QuoteBeforeHandler).
- ⏳ Na org mas em versão anterior (zips na mão do Diego, é só subir): OpportunityBeforeHandler v3 (RT Autos + bypass Bypass_Gates_Automacao) e ExecuteDemoRequest (Vehiculo__c) — revertidos pelo rollbackOnError.
- 🔒 NÃO construído POR DESIGN (bloqueado por dados/decisão, não por dev): T12 fin de ciclo (espera D6: km máximo + campo odômetro), wire B v2 derivação marca/sucursal (espera carga real de inventário + códigos SAP), rollout GT/HN/NI/PA.
- O resto do runbook é clique de Setup/ativação (Davi), não desenvolvimento.

### Estado de fechamento da HU-046 (06/08, fim do dia)
- **Acabamento pré-validação (06/08)**: TODO-DAVI removidos dos LABELS visíveis da tela ManageDemoVehicle (5 fieldText: marca, sucursal, VIN, asesor, owner — agora com dica de formato p/ o usuário; as notas de evolução v2 continuam na description do flow). Zip standalone `HU046_flow_manage.zip`. REGRA: nota de dev vai na description, nunca no fieldText.
- **Planilhas de dados ENVIADAS AO CLIENTE pelo Diego** (mapeo cupos×cuentas + códigos SAP de centros). QUANDO O CLIENTE RESPONDER: preencher BranchCode__c dos 158 cupos + regerar CMDT + fechar o de-para → **a HU termina** (restam cliques de Setup do runbook + execução do teste).
- **Roteiro de teste unitário em TEXTO**: `hu046/ROTEIRO_TESTE_UNITARIO.md` — 6 etapas (~75 min): 0 pré-condições (subir 2 zips, ativar na ordem, dados DEMO-TEST, 4 usuários), 1 guarda OBH primeiro (7 verificações), 2 ciclo feliz solicitar→designar→liberar→Opp com Vehiculo__c, 3 limites (cupo cheio/sem cupo/VIN errado/asignar-cancelar), 4 scheduled via Debug + permissões, 5 regressão HU-025+Repuestos (não pular). Avisos: Debug de tela faz DML real; rollback mode p/ handler; acentos literais; prod sobe inativo; limpar DEMO-TEST ao final.

### Plan de pruebas HU-046 (06/08) — `hu046/GrupoQ_HU046_Plan_de_Pruebas.xlsx`
- 36 casos em 9 suítes: PRE (setup), MDV (tela gerência, 8), EDR (tela encargado, 6), OBH (guarda Opportunity, 9 — incl. RT Repuestos isento, bypass x2, não-redisparo, liberação não bloqueada), SCH (scheduled WEEKDAY, 3), LOG (traza), PSV (permissões 3), REG (regressão VR HU-025 + fluxo Repuestos, 3), FHT.
- Hoja Preparación: dados DEMO-TEST-001..004 (4 status), CMDT TEST MaxDemo=1 p/ cupo lleno, usuários U1 gerente/U2 encargado/U3 sem PS/U4 bypass; guia de como testar flow sem Apex (Debug de tela executa DML REAL; record-triggered com rollback mode; scheduled via Debug); ordem de ativação; nota de release (deploy ativo em prod exige flow test coverage 75% — default é inativo).
- Critério de saída: 36 PASA (ou defeito documentado) ANTES de liberar para validação do cliente/QA. Gerador: `hu046/scripts/gerar_plan_pruebas.py`.

### Planilhas cliente geradas (06/08) — `hu046/`
- `GrupoQ_HU046_Mapeo_Cupos_x_Cuentas.xlsx` (ES, 4 hojas: Instrucciones, 5 Preguntas clave, Mapeo CR+NI 40 filas com SÍ/NO+Corrección, 8 Cuentas sin cupo) — responde item #10 da tabela.
- `GrupoQ_HU046_Codigos_SAP_Centros.xlsx` (ES, 2 hojas: Instrucciones, 22 dealers com coluna amarela "Código SAP del centro" + fila ejemplo) — responde item #11; código vai para AccountNumber + BranchCode__c.
- Gerador versionado: `hu046/scripts/gerar_planilhas_cliente.py` (OOXML à mão; openpyxl/pip indisponíveis).

### Pendências HU-046 consolidadas com owner (06/08)

| # | Pendência | Owner | Depende de |
|---|---|---|---|
| 1 | Subir `HU046_flow_opphandler.zip` **v3** (guarda RT Autos + bypass Bypass_Gates_Automacao) | Davi/Diego | — |
| 2 | Confirmar deploy do `HU046_flow_execdemo.zip` (ExecuteDemoRequest c/ Vehiculo__c — revertido no rollback) | Davi | — |
| 3 | Verificar se já existe outro before-save de Opportunity → merge (1 handler/objeto) | Davi | — |
| 4 | Atribuir PS (Management→gerentes/director/VP; Execution→encargados; bypass→integração) | Davi | — |
| 5 | FHT Vehicle + SerializedProduct (Status/Owner) — T13 | Davi | — |
| 6 | 2 App Pages + tabs (Manage c/ visibility $Permission.RequestDemoVehicle; Execute) — T06 | Davi | — |
| 7 | CBSF: filtro da busca de VENDA excluir Status demo/exh — T01/T02 | Davi | — |
| 8 | TODO-DAVI telas: floorManagerId via GroupMembers, lookups de User, VIN→CBSF (v2) | Davi | — |
| 9 | Ativar flows na ordem: subflows → handler → scheduled → telas | Davi | #1-#8 |
| 10 | De-para cupos×Accounts: GWM Liberia, Terrazas, NI Managua, contas C105 sem cupo, Flotas/Usados fora | GrupoQ (Isabella/Andrea) | CSV enviado |
| 11 | Código SAP do centro → AccountNumber das contas dealer; eu preencho BranchCode__c dos 158 e regero CMDT | GrupoQ → eu | #10 |
| 12 | MaxDemoMileage (valores por política) + campo do odômetro → eu construo T12 (fin de ciclo) | GrupoQ → eu | D6 |
| 13 | Wire B v2 (derivar marca via BusinessBrand e sucursal via CurrentOwnerId nas telas) | eu | carga real de inventário (premissa: Vehicle.CurrentOwnerId = Account dealer) |
| 14 | Rollout GT/HN/NI/PA: Accounts dealer + grupos GRP_Sucursal_* + membros | Admin/rollout | — |
| 15 | Reescrever HU-046: pivot Vehicle.Status + cadeia de enforcement (CBSF→guarda→VR Reserva Confirmada) + Repuestos/PA isento | Meli | evidências prontas no STATUS |
| 16 | Data fix: espaço duplo em "GrupoQ Active Motors  Managua" | Admin GQ | — |
| 17 | Congelar API names de picklist ("En exhibicion" sem acento); se renomear, atualizar fórmulas dos flows | Davi/Meli | decisão |

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
