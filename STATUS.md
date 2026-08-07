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
- **CORREÇÃO DO CAMPO VIN (07/08, apontada pelo Diego)**: o VIN do Vehicle vive no campo standard **`VehicleIdentificationNumber`**, NÃO no Name (eu tinha assumido Name=VIN sem describe completo). E a HU pede busca por **nome E VIN** → telas corrigidas (commit 5cfd10c): Get Records com filterLogic OR (VehicleIdentificationNumber = input OU Name = input), label "VIN o nombre de la unidad", validação estrita de 17 chars REMOVIDA (impediria busca por nome). Mapping SAP corrigido: VLCVEHICLE-VIN → VehicleIdentificationNumber (chave de upsert); Vehicle.Name = descritivo (definir na carga). D2/HU-045 "VIN unique" refere-se presumivelmente a VehicleIdentificationNumber — confirmar unicidade no describe.
- **Exposição das telas (respondido 05/08)**: App Page "Vehículos Demo" (App Builder) com componente Flow → Manage Demo Vehicle + component visibility `{!$Permission.RequestDemoVehicle}`; 2ª App Page/tab para Execute Demo Request; Quick Action tipo Flow no Vehicle fica para v2 (junto com CBSF/T01). Personas: Manage = gerente de sucursal/marca, director, VP (PS_Demo_Vehicle_Management); Execute = encargado de piso (PS_Demo_Vehicle_Execution).

### Balanço de DESENVOLVIMENTO da HU-046 (06/08) — TUDO CONSTRUÍDO
- ✅ Construído e NA ORG: CMDT DemoCapacityConfig (8 campos) + 158 cupos, 2 custom permissions, notification type, 2 PS (com cadeia de dependências), 6 flows, destructives aplicados (MaxNum__c, QuoteBeforeHandler).
- ⏳ Na org mas em versão anterior (zips na mão do Diego, é só subir): OpportunityBeforeHandler v3 (RT Autos + bypass Bypass_Gates_Automacao) e ExecuteDemoRequest (Vehiculo__c) — revertidos pelo rollbackOnError.
- 🔒 NÃO construído POR DESIGN (bloqueado por dados/decisão, não por dev): T12 fin de ciclo (espera D6: km máximo + campo odômetro), wire B v2 derivação marca/sucursal (espera carga real de inventário + códigos SAP), rollout GT/HN/NI/PA.
- O resto do runbook é clique de Setup/ativação (Davi), não desenvolvimento.

### Estado de fechamento da HU-046 (06/08, fim do dia)
- **TODO (5) RESOLVIDO (06/08)**: AdvisorId/PreviousOwnerId deixaram de ser texto (User Id digitado) → **DropdownBox com dynamic choice set `ActiveUserChoices`** (User, IsActive=true, ordenado por Name). Refino futuro se a lista crescer: filtrar por perfil/role de vendas ou sucursal. `HU046_flow_manage.zip` atualizado (labels limpos + dropdowns).
- **Acabamento pré-validação (06/08)**: TODO-DAVI removidos dos LABELS visíveis da tela ManageDemoVehicle (5 fieldText: marca, sucursal, VIN, asesor, owner — agora com dica de formato p/ o usuário; as notas de evolução v2 continuam na description do flow). Zip standalone `HU046_flow_manage.zip`. REGRA: nota de dev vai na description, nunca no fieldText.
- **Planilhas de dados ENVIADAS AO CLIENTE pelo Diego** (mapeo cupos×cuentas + códigos SAP de centros). QUANDO O CLIENTE RESPONDER: preencher BranchCode__c dos 158 cupos + regerar CMDT + fechar o de-para → **a HU termina** (restam cliques de Setup do runbook + execução do teste).
- **Roteiro de teste unitário em TEXTO**: `hu046/ROTEIRO_TESTE_UNITARIO.md` — 6 etapas (~75 min): 0 pré-condições (subir 2 zips, ativar na ordem, dados DEMO-TEST, 4 usuários), 1 guarda OBH primeiro (7 verificações), 2 ciclo feliz solicitar→designar→liberar→Opp com Vehiculo__c, 3 limites (cupo cheio/sem cupo/VIN errado/asignar-cancelar), 4 scheduled via Debug + permissões, 5 regressão HU-025+Repuestos (não pular). Avisos: Debug de tela faz DML real; rollback mode p/ handler; acentos literais; prod sobe inativo; limpar DEMO-TEST ao final.

### SESSÃO DE TESTE AO VIVO — visão de usuário (06/08, tarde) — REPASSE DETALHADO P/ DAVI
Tudo abaixo foi FEITO pelo Diego, clicando na org (sandbox DevSales). Este é o estado real pós-preparação:

**Preparação executada (checklist do que JÁ ESTÁ PRONTO na org):**
1. **Permission sets atribuídos**: `PS_Demo_Vehicle_Management` e `PS_Demo_Vehicle_Execution` → usuários Diego e Davi (Setup > Permission Sets > Manage Assignments).
2. **Flows de tela ATIVADOS**: `ManageDemoVehicle` e `ExecuteDemoRequest` estavam Draft pós-deploy (deploy nunca ativa) → ativados no Flow Builder. Os outros 4 (subflows ValidateDemoQuota/LogDemoActivity, OpportunityBeforeHandler, ReleaseExpiredDemoAssignments) já estavam Active.
3. **App Page "VehiculosDemo"** (tab Vehículos Demo): já existia com o flow ManageDemoVehicle; faltava a visibilidade → adicionado **component visibility filter** no componente do flow: `{!$Permission.RequestDemoVehicle}` = true (App Builder > clica no componente Flow > Set Component Visibility > Add Filter > Permission > RequestDemoVehicle > equals True). Salvo + ativado.
4. **App Page "Ejecutar Solicitudes Demo" CRIADA** (não existia): App Builder > New > App Page > 1 região > componente Flow = `ExecuteDemoRequest` > Save > **Activate** > tab própria ("Ejecutar Solicitudes Demo") visível nos apps. Criada 06/08 2:56PM.
5. **Registro de cupo TEST criado no CMDT** (o passo que faltava — a 1ª tentativa de teste falhou por isso): Setup > Custom Metadata Types > Demo Capacity Config > Manage Records > New:
   - Label/Name `TEST_TEST_Test` · Brand `TESTMARCA` · Branch Name `TestSucursal` · Country `CR` (planejado XX, ficou CR — SEM impacto: a chave Marca+Sucursal é única) · **Max Demo `2`** · Max Exhibition `0` · Branch Code vazio · Max Demo Mileage vazio. Criado 06/08 3:42PM.
   - **Por que MaxDemo=2 e não 1**: o `ValidateDemoQuota` ativo conta cupo **por Status do Vehicle globalmente** (wire B v1 — marca/sucursal ainda não derivadas do veículo). O vehicle "Prueba Demo" (VIN 1010) JÁ está "En demostración" na org e ocupa 1 vaga do contador. Com MaxDemo=2: Hilux entra como 2ª vaga e a 3ª solicitação dispara "cupo lleno" naturalmente.
6. **Veículos de teste = os RPA existentes** (não criamos novos): RPA Toyota Hilux (VIN10001), RPA Mazda CX-5 (VIN10002), RPA Chevrolet Onix (VIN10004, "En exhibicion"), Prueba Demo (VIN 1010, "En demostración"). Names intactos, VINs populados no campo `VehicleIdentificationNumber`.

**Descoberta no 1º teste → CAUSA RAIZ ENCONTRADA (06/08, ~17h50)**: "Unidad no encontrada" tanto por nome quanto por `VIN10001`. Diego abriu a versão ativa (Manage Demo Vehicle V2) no Builder e confirmou: o flow fazia **DUAS** consultas com o valor digitado e a decisão "Unit Found?" exigia as duas — (1) `SerializedProduct.SerialNumber = input` e (2) Vehicle. Os RPA não têm SerializedProduct → falha sempre, independente do campo de busca.
- **Decisão de ARQUITETURA (pergunta do Diego: "está certo consultar nesse objeto?")**: NÃO. SerializedProduct era resquício das premissas antigas da HU (pré-pivot para Vehicle.Status). Diego trouxe as páginas oficiais (Vehicle Inventory Resource Mapping + object reference Vehicle/SerializedProduct) e a leitura fecha com 3 evidências:
  1. No BOD VehicleInventory, SerializedProduct é perna OPCIONAL de estoque serializado por Location (pendurado em ProductItem, único campo mapeado = SerialNumber, Required No). A identidade da unidade no próprio mapping é `Vehicle.VehicleIdentificationNumber` (**unique + idLookup**) + `Vehicle.AssetId` (**unique**, 1:1) — e o serial no lado comercial já tem casa em `Asset.SerialNumber`.
  2. **Regra de acesso especial**: usar SerializedProduct exige "Manage Industries Visit" + **PSL Industries Visit** (exceto Field Service) → custo de licença por usuário para gerentes/encargados. `SerializedProduct.Status` é restricted (Available/Consumed/Damaged/Lost/Sent) — zero aderência a demo/exhibición (raiz do pivot para Vehicle.Status).
  3. O campo correto é **`Product2Id`** (obrigatório, não-nillable) — o apex com `ProductId` falhou ("Field does not exist"). Script correto (Product2Id via Asset.Product2Id + AssetId) registrado no chat caso um dia precisem do objeto; NÃO usar na HU-046.
  **Veredito**: HU-046 opera 100% sobre Vehicle — busca por VIN OU Name, estado em Vehicle.Status, asesor em Vehicle.OwnerId. SerializedProduct fora do desenho e fora do mapa de cargas SAP.
- **PATCH APLICADO no `ManageDemoVehicle` (commit desta sessão)**: (a) removido `GetSerializedUnit`; (b) tela Menu conecta direto no `GetVehicle` (busca dupla: `VehicleIdentificationNumber` OU `Name`, filterLogic OR); (c) decisão Unit Found só pelo Vehicle; (d) Assign/Revert de asesor agora gravam **`Vehicle.OwnerId`** (antes SerializedProduct.OwnerId); (e) description atualizada. `ExecuteDemoRequest` já era limpo (não usa SerializedProduct). Zip `HU046_flow_manage.zip` reconstruído; cópia em `HU046_faltantes/flows/` sincronizada.
- **Próximo passo do teste**: subir `HU046_flow_manage.zip` (Workbench, rollbackOnError ok — componente único) + `HU046_flow_execdemo.zip` (busca dupla), ATIVAR as novas versões no Builder, e refazer T1 com `VIN10001` (e depois com o nome, para validar a busca dupla). SEM dados artificiais de SerializedProduct.

**RESULTADO DO TESTE (06/08 noite) — CICLO PRINCIPAL PASSOU ✅**: T1 solicitar+cupo (notificação "1 de 2 en uso" no Davi), T2 execução Davi (Hilux → En demostración), asignación (Task dono=asesor), liberación (sininho + execução com D4). Consolidado em **`hu046/REPASSE_DAVI_TESTE.md`** (estado da org, 6 mudanças de desenho do dia, 5 testes passados, 7 testes restantes T5b-T11 com passos, limpeza, pendências, débitos UX). **3 fixes de runtime no caminho**: (1) floorManagerId vazio → dropdown obrigatório EncargadoPick (dono da Task + destinatário); (2) custom notification exige targetId → GetVehicle.Id; (3) NOVA DECISÃO DE DESENHO (Diego): "o veículo é do GrupoQ" → asignación excepcional 100% via Task do asesor, NENHUM OwnerId de Asset/Vehicle muda; cancelación fecha a Task aberta; aprendizado: **Vehicle não tem OwnerId** (dono vive no Asset). Dado sujo notado: Kia VIN10003 "En demostración" (origem desconhecida) → cupo global 3≥2, aproveitado como teste de cupo lleno (T7).

**Sequência de teste planejada (T1→T7):** T1 solicitar designación (VIN10001, TESTMARCA/TestSucursal, executor Davi) → T2 executar designación na tab Ejecutar (status vira "En demostración" + traza) → T3 repetir com VIN10002 até "cupo lleno" (3ª demo) → T4 guarda na Opportunity (RT Autos + Hilux em demo → erro; bypass OK) → T5 salvar Opp com CX-5 livre → T6 liberação (Opp Reserva Confirmada com Vehiculo__c) → T7 conferir trazas/notificações. Marcar resultados no Plan de Pruebas (36 casos).

**Limpeza obrigatória pós-teste**: restaurar Status dos RPA, deletar registro CMDT TEST_TEST_Test, deletar Opps de teste. Depois: subir zips da busca dupla e reativar.

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

## 3c. HU-045 — Auto Registro de Vehículo Usado (análise NOSSA, executor Santiago Pelaez)

- **AUTORIA**: a análise técnica é do Diego + Claude (sessão anterior, fechada sem querer em 05/08) — as Tarefas Técnicas v2 (22 tarefas, D1-D12, princípio native-first, saldo 1-3 campos custom) foram entregues por nós ao Santiago. A v3_1 é a evolução do Santiago em cima da nossa v2 (ajuste da integração SF-SAP do alta / T20-T21).
- **Estado (msg Santiago 06/08)**: T03/T04/T05/T06/T08/T14 + Platform Event T20 construídos e testados em DEV. Bloqueado para o T10 (screen flow de alta) por 4 definições que ele pediu a nós (as decisões são nossas — D4/D6/D8 vêm da nossa análise v2).
- **Achado do Santiago**: cadeia real de criação Product2 → VehicleDefinition → Asset → Vehicle (AssetId e VehicleDefinitionId nillable=false; confirma D8 master-detail). Catálogo tem 224 VD só de marcas NOVAS.
- **RESPOSTAS DADAS (06/08)**:
  1. **VD para usados = Op.2 (genérico)**: 1 VehicleDefinition "Used Vehicle" + 1 Product2 "Used Vehicle" compartilhados; marca/modelo/ano reais nos campos NATIVOS do Vehicle (Make/Model/ModelYear — D7). Nuance RN5: unidade ex-GQ (demo→usado, re-ingreso) MANTÉM a VD real (D2 atualiza o MESMO Vehicle) — o genérico é só para terceiros fora do catálogo. Evolução reversível p/ genérico-por-marca se relatório por marca de usados virar requisito (manteria cadeia BusinessBrand).
  2. **Appraisal**: ReferenceRecordId = Account do vendedor/consignante (capturada na tela; não CurrentOwnerId pós-transferência); unidade via AppraisalItem.ReferenceRecordId = Vehicle (RN3 ok). PurposeType: TESTAR alta de valor (1 clic, como D11) — se restricted, morre a Opção A do T01 e reforça D4=B. Reuso: buscar Appraisal vigente (ValidityEndDate>=hoje) via AppraisalItem→Vehicle; criar só se não existe (trade-in já vem do HU-036).
  3. **D4 = Opção B** (Vehicle.AcquisitionType): requisito literal GQ-CA-01-153 (list view não cruza objetos), tipo de aquisição é propriedade da UNIDADE (não do evento de avaliação), PurposeType possivelmente restricted. Valores: Compra directa/Trade-in/Consignacion.
  4. **D6 = campo CommissionRate (Percent)** recomendado — comissão de consignação é número de liquidação (calculável/reportável); SpecialTerms como complemento textual. Pergunta única p/ Meli: "¿la comisión se calcula/reporta o solo se registra?".
  5. **T09**: lista de almacenes por sociedad = dado do cliente (Location referenciada por Asset.LocationId) — pedir junto com as outras 2 planilhas na thread GrupoQ (sociedad, nombre, código SAP si existe).
- **DOCX DA HU-045 LIDO (06/08) — valida e FECHA as decisões**: (1) **D4 não é mais pendente**: RN2 diz literalmente "Tipo de adquisición (picklist): compra directa · trade-in · consignación" como dado DA FICHA DA UNIDADE + GQ-CA-01-153 pede base filtrável → Opção B decidida pelo próprio documento; (2) **D6 não é mais pendente**: RN4 diz literalmente "la comisión es un campo del contrato" (e critérios de aceitação repetem) → Contract.CommissionRate (Percent) decidido, SpecialTerms morre; nem precisa perguntar à Meli; (3) RN3 confirma o desenho do Appraisal: terceiros → ligado à PLACA (AppraisalItem.VehicleRegistrationNumber), ex-GQ → ao registro/VIN original (AppraisalItem→Vehicle); Esc.3 confirma reuso do avalúo do HU-036; (4) RN2: km no campo nativo Odometer (LastOdometerReading), NÃO vem do SAP; (5) Esc.6 corpo: "transición de estado con aprobación, nativa y consistente con HU-046" → T15 segue nosso padrão de gates.
- ⚠️ **BUG EDITORIAL na HU-045 para a Meli**: os TÍTULOS dos Escenarios 4-7 estão DESLOCADOS um passo dos corpos (Esc.4 título "consignación" mas corpo é demo→usados; Esc.5 título "venta" mas corpo é alta de contrato; Esc.6 título "vencimiento" mas corpo é venta gestionada; Esc.7 título "sociedad sin consignación" mas corpo é a alerta de 5 días). Corrigir antes do QA.
- **Open point registrado**: Guatemala ativos fijos — demo/exhibición contabilizada como ativo fijo: processo de reclassificação contábil SAP→inventário indefinido; perguntar ao GrupoQ.
- **VALIDAÇÃO ARQUITETURAL HU-045 (06/08, docs via search — páginas SF 403 no proxy)**: (1) core do Automotive Cloud NÃO traz flow pronto de alta de usados; o que existe nativo e JÁ REUSADO pela nossa análise: CBSF (busca/filtro, T17), família Appraisal/AppraisalItem ("Vehicle and Asset Appraisals" no Data Model Gallery, T12), Vehicle Console/Timeline; (2) existe pacote OPCIONAL "OmniStudio for Automotive Cloud" (help auto_omnistudio_package) com componentes pré-construídos documentados p/ appointment scheduling e menções a Appraisal Management — CHECK de 10 min antes do T10: Setup > Installed Packages (OmniStudio instalado?) — se a org não roda OmniStudio (toda automação GRPQM é Flow), adotar OmniStudio para 1 HU quebraria o padrão da org (2 frameworks de UI, licença, manutenção) → Screen Flow é a escolha certa; se o OmniScript de appraisal JÁ estiver instalado, avaliar reuso só do subflow T12; (3) release: org em v67 Summer '26, modelo Appraisal é o atual; nada nas notas recentes (verificável via snippets) entrega alta de usados pronta; (4) riscos apontados: máquina de estados única de Vehicle.Status entre HU-045/046 (En consignacion + valores demo — documento único p/ Meli), CurrencyIsoCode por sociedad em Contract/Appraisal, evento do T20 publicado só no PASSO FINAL do flow (ok D12).
- **INVENTÁRIO OmniProcess (06/08) — a org USA OmniStudio ativamente; corrigida suposição "tudo é Flow"**: o padrão real da org é HÍBRIDO — **OmniScript/IP para jornadas guiadas** e **Flow para automação de registro**. Ativos: família **GrupoQ** custom (CrearCotizacion OmniScript v2 ATIVO!, CustomerSearch IP, LeadDedup IP, LeadUpsert IP v6 — o "patrón anti-duplicado HU-039" da RN1 da HU-045 É o LeadDedup!), **GQAutoCloudScheduler** custom (test drive completo: DriverLicenseValidation, TestDriveAppointment, TestDriveModeSelection, HomeTestDriveAddress + GetEligibleDrivers IP), **AutomotiveScheduler** (conteúdo pré-construído do pacote AC presente: ScheduleTestDrive IP + TestDriveAppointment OmniScript ativos), ServiceAppointment (LocationSearch, TimeSlotSelection). **NENHUM componente de Appraisal** → T12 segue nosso (não há pré-construído a reusar).
- **DECISÃO T10 REVISADA (recomendação)**: manter **Flow** para o alta de usados — é operação interna de back-office (padrão dos irmãos HU-046), os subflows T12/T13 já são Flow, o publish do platform event (D12) é nativo de Flow, e o Santiago já tem 7 tarefas construídas nessa stack. PORÉM registrar a alternativa como decisão consciente com tech lead: o precedente de jornada guiada da org é OmniScript (CrearCotizacion) — se quiserem consistência de UX de jornadas, T10 em OmniScript é defensável (custo: redesenho + fronteira com os subflows). Reuso pontual a avaliar: CustomerSearch IP para localizar a Account do consignante.
- **Efeitos colaterais do achado em OUTRAS frentes**: (1) HU-028 RN-19 "LWC único" — verificar se a UX de pricing deve plugar no CrearCotizacion (OmniScript de cotización JÁ EXISTE e está ativo!); (2) HU-039 anti-dup = LeadDedup IP (evidência do padrão citado na RN1 da HU-045); (3) test drive da org é OmniStudio — se alguma HU futura tocar test drive, a stack é essa.
- Sinergia com HU-046: mesma malha (Vehicle.Status, Accounts dealer/sociedade, Bypass_Gates_Automacao, padrão de gates HU-025); T15 (baja al cerrar venta) usa o padrão do OpportunityBeforeHandler.

## 3e. Test Drive (Fit&Gap "Proceso de prueba de manejo") × HU-046 — interseções mapeadas (07/08)

- **A frente é a que estava com o Tiago** (GQAutoCloudScheduler OmniScripts + página Test Drive Authorization + Document Generation p/ consentimento) → item central do HANDOVER.
- Desenho do Fit&Gap: scheduler Flex Card standard do Automotive Cloud na Opportunity; flota demo = veículos marcados "Demo"/"Prueba de Manejo"; anti-overbooking por chassi via calendário; termos de responsabilidade via Document Generation (2 templates/país, sem e-signature no escopo); pipeline: test drive como etapa da Opp. Fora de SF (ERP/DMS): combustível/manutenção, seguros/claims, multas (log exportado), depreciação.
- **INTERSEÇÕES COM HU-046 (para o mapa de estados da Meli)**: (1) a designação demo da HU-046 é a PORTA DE ENTRADA da flota agendável do scheduler — vocabulário precisa casar: Fit&Gap fala "Demo"/"Prueba de Manejo"/"Available", org tem "En demostración" — confirmar qual Status o flex card filtra; (2) "Available" em tempo real: manutenção muda o Status manualmente/via oficina ("En reparación" existe na org) — MAIS um ator na máquina de estados do Vehicle.Status; (3) ⚠️ GAP DETECTADO: a LIBERAÇÃO para venda (HU-046) de uma unidade demo com test drives FUTUROS agendados não checa/cancela os agendamentos — ExecuteDemoRequest v2 deveria ao menos avisar (Get de ServiceAppointments/agendamentos futuros do veículo) ou o processo prevê cancelamento manual. Levar à Meli junto com o mapa de estados.
## DATA FIX DA HIERARQUIA DE CONTAS (07/08) — CSVs gerados e enviados
- **Leitura corrigida do GROUP BY**: as 26 contas com Sociedad__c='C101' NÃO são a hierarquia (que está vazia no campo, exceto La Uruca Repuestos) — são contas de CLIENTES carimbadas; semântica confirmada: "sociedade da conta", usada nos clientes.
- `integracion/data/fix1_sociedad_accountnumber.csv` (28 linhas, Update por Id): Sociedad__c por ramo (C101 nos 10 dealers C101 + a própria sociedade; C105 nos 11 + sociedade; N105 Managua + sociedade; holding/países em branco) + AccountNumber das 3 sociedades. SUBSTITUI o CSV anterior de 3 linhas. ⚠️ células vazias de AccountNumber apagam o campo — hoje inócuo (tudo vazio), NÃO rodar depois que os códigos de centro do cliente forem carregados.
- `fix2_rename_managua.csv`: corrige o espaço duplo do nome.
- **AccountLevel__c ficou FORA do fix** — picklist com valores desconhecidos (vistos em uso: "Holding", "Subsidiary"); pendente: lista de valores do Object Manager → aí gero fix3 com o nível das 28 e o filtro do Flavio fecha.

## ESCOPO DE ROLLOUT (definido 07/08): **COSTA RICA PRIMEIRO**
- Onda atual = CR. GT/HN/NI/PA/SV = ondas futuras → os "gaps de rollout" (grupos GRP_Sucursal_*, Accounts dealer, cupos de outros países) NÃO bloqueiam a onda atual; viram checklist do kit-por-país.
- **CR está completo para a HU-046**: 8 grupos GRP_Sucursal_CR_*, 19 contas dealer (C101+C105), 30 linhas de cupo CR no CMDT, hierarquia completa.
- Prioridade nas planilhas do cliente: linhas CR do mapeo + códigos SAP dos centros CR primeiro (NI/demais podem vir depois).
- **Kit por país** (usar quando GT/HN/NI/PA/SV entrarem): Accounts país+sociedades+dealers (com AccountNumber/SAPCode), grupos GRP_Sucursal_{CC}_* + membros, cupos do país já no CMDT (deployados), PS assignments, valores de picklist se faltarem.

## 3f. HU-054 — Precio de Referencia (PRU) y Precio de Venta del Usado en la Cotización (draft lido 07/08)

- **3 valores não intercambiáveis (RN1)**: referência PRU/BlueBook (informativo, teto do avalúo) ≠ FinalAppraisalValue (HU-036) ≠ precio de venta da UNIDADE (único que cotiza).
- **DESENHO PROPOSTO (native-first)**: BLOCO A (tabela PRU por país, carga massiva+unitária, versionada) → **Decision Matrix** (CSV upload nativo + versões — mesmo mecanismo da POC/HU-028; lookup via Expression Set/BRE 27k seats) OU objeto custom se negócio exigir UI de registro; consumo no avalúo grava em `AppraisalItemProviderValuation` (standard, confirmado no Data Model Gallery). BLOCO B (precio de venta POR UNIDADE, histórico, massivo) → **`Asset.Price`** do par da unidade (candidato nativo; alternativa Vehicle.MarketPrice mas semântica = valor de mercado, não venda) + **FHT no campo** (histórico com autor/data nativo) + massivo pelo mecanismo de plantilla da HU-038; publicação web = platform event gateado pelo indicador (RN5) padrão RegisterUsedVehicleEvent__e. BLOCO C (aplicação na cotización) → price book técnico com PricebookEntry placeholder POR MOEDA (padrão HU-028) + flow de guided selling grava UnitPrice da QLI = precio de venta vigente ⇒ **congelamento nativo** (QLI copia valor, não referencia — RN11 de graça); moeda/tipo de cambio via multicurrency + campos fotografía (fecha/tasa) padrão HU-028; impostos tabela HU-038 + año do vehicle; gastos via RFC SAP on-line (RN13 = mesmo patrón de erro da HU-028: sem default, bloqueia); **redondeo por etapa** = a descoberta da POC (RN9/Esc.18: SAP 4 decimais internos, 2 na posição — homologar regra por sociedad+moeda).
- **Tensão a resolver com HU-045**: VD/Product2 genérico "Used Vehicle" (decisão HU-045) convive com o pricing por unidade SEM criar Product2 por unidade: QLI aponta o produto genérico e o flow sobrescreve UnitPrice da unidade (evita explosão de catálogo). Validar com Santiago.
- **Bloqueio de cotização sem preço (RN12/Esc.9)**: mesma malha de gates — validação/flow no guided selling + VR se necessário; consignación (Esc.19) depende da transição HU-045.
- Não acessível via proxy (403) — Diego abrir: Automotive Cloud Implementation/Admin guide (help.salesforce.com auto_cloud), Vehicle & Asset Appraisals data model page, sforce_api_objects_asset (campo Price), release notes recentes de Appraisals.
- Indústria: preço por UNIDADE (stock number) é o padrão dealer (vAuto/KBB Instant Cash Offer: reference book ≠ appraisal ≠ asking price); portal web consome preço do DMS/CRM por feed — nunca digitado no site.

## ESC.4-6 DA HU (asignación excepcional) IMPLEMENTADOS DE VERDADE (07/08)
- Diego trouxe o texto real dos cenários: a asignación excepcional é **EXCEÇÃO À GUARDA** — o asesor designado PODE gerenciar a venda da unidade demo/exh durante as 8h hábiles; os demais seguem bloqueados (Esc.4); vencimento libera exclusividade com traza (Esc.5); reasignación troca o asesor com traza (Esc.6).
- **Guarda v4 (`OpportunityBeforeHandler`)**: quando a unidade está demo/exh, antes de bloquear consulta Task "[Demo] Asignación" ABERTA da unidade com **OwnerId = $User.Id** → achou = permite (a Task é a credencial da janela); não achou = custom error. Vencimento (scheduled fecha a Task) ou cancelación re-armam o bloqueio sozinhos — zero campo novo, zero Apex.
- **Tela Asignar (Esc.6)**: asignar agora FECHA qualquer asignación aberta anterior da unidade antes de criar a nova (1 asignación ativa por vez; reasignación = swap trazado).
- **Traza na Opportunity (Esc.4 "exceção registrada na Opp")**: coberta indiretamente (Opp nasce/liga via Vehiculo__c + Task no Vehicle). Before-save não pode criar registros; se o QA exigir traza explícita NA Opp, opções: after-save no handler ou Task na Opp — decidir com a Meli na reescrita.
- **AMBIGUIDADE Esc.5 para o cliente/Meli**: "unidade fica livre para ser gerenciada por qualquer outro consultor" após vencimento — interpretamos como fim da EXCLUSIVIDADE (guarda volta a valer para todos; vender exige nova asignación ou liberación). A leitura alternativa (venda liberada geral após 8h) contradiria a liberación formal — confirmar.
- Zips atualizados: `HU046_flow_opphandler.zip` (v4) + `HU046_flow_manage.zip`. Teste novo no plano: asesor com Task aberta vincula unidade demo na Opp RT Autos → SALVA; outro user → bloqueado; fecha a Task → volta a bloquear.

## CÓDIGOS SAP RECEBIDOS (06/08 noite) — pendência #11 DESTRAVADA
- Cliente enviou `Sucursales_QRM_4.xlsx` (596 linhas, TODOS os países: C/G/H/N/P/S) + gravação "Sucursales activas" (Luis Chavarría 04/06). Versionado: `integracion/data/sucursales_qrm_completo.csv` (de-para mestre do rollout + almacén→Location).
- **DECISÃO VALIDADA PELO CLIENTE (áudio)**: sucursal/patio = **Centro+Almacén (WERKS+LGORT, ex. C0111200)** — "la llave que identifica el patio". Centro repete (C011 = todas C101); almacén repete entre sociedades (1200 em C101/C105/N105/N101). BranchCode__c e AccountNumber dealer = composto.
- **Nuances da gravação**: (1) interface de reserva SAP pedirá SÓ o centro (novos e usados) — payload Flavio = WERKS; (2) um patio serve 2 sucursais QRM (Lindora+SantaAna=C0111210; Uruca+Flotas=C0111200; ForlandCentral+ActiveCentral=C3111200) → **AccountNumber não é único** → chave de upsert de conta segue SourceSystemIdentifier/SAPCode__c (decisão pendente); (3) CR não vende mais motos → sucursais C105 motos (Autopits/GOLLO/Curacao) serão INATIVADAS, lista depurada vem da Vanessa; (4) marcas sociedades "5": Forland/Chery/GWM/Arcfox/GAC.
- **EXECUTADO**: 37/40 cupos CR+NI com BranchCode__c preenchido (`deploy/HU046_cmdt_branchcodes.zip`, join via data_mapping por conta); `integracion/data/fix4_accountnumber_centros.csv` (21 contas dealer, Id+AccountNumber composto — NÃO rerodar fix1 depois). 3 cupos sem código + 4 perguntas ao cliente em `hu046/PERGUNTAS_CLIENTE_CODIGOS.md` (Forland PZ C211×C311; GWM Liberia; NI marcas×sociedades; Uruca Usados C817 sem almacén).
- **DECISÃO 07/08 (pergunta do Diego "precisamos mesmo do código no AccountNumber?")**: com escopo CR-only — (1) HU-046 v1 NÃO depende de código na Account (cupo casa por marca/sucursal digitadas vs CMDT); (2) fix4 recomendado mesmo assim (2 min, só dado, prepara wire B v2 = derivação por CurrentOwnerId e resolução de contas nas cargas); (3) **SAPCode__c External ID ADIADO** — 22 contas CR não justificam campo custom, MuleSoft resolve por cross-reference; e o composto não é único entre contas (patios compartilhados) → nunca seria chave de upsert sozinho. AccountNumber = código visível p/ humanos, nunca chave de integração.

## 3d. CONVENÇÃO TRANSVERSAL: código SAP nas Accounts (decidida 06-07/08)

- **`Account.AccountNumber` = código SAP do nível**: sociedade (3º nível) = código de sociedad (C101/C105/N105); dealer (4º nível) = código SAP do CENTRO. Chave nativa e filtrável, sobrevive a sandbox→prod (Id não!). Consulta padrão: `SELECT Id FROM Account WHERE AccountNumber = 'C101'`.
- ⚠️ **CORREÇÃO 07/08 (Diego): AccountNumber NÃO é indexado por default.** Irrelevante hoje (dezenas de contas GrupoQ), mas a tabela Account vai crescer com CLIENTES (potencialmente centenas de milhares na região) → filtro não-indexado vira full scan. **Evolução recomendada para a chave de integração**: campo custom `SAPCode__c` (Text, **External ID**, Unique) na Account — External ID é indexado automaticamente E habilita UPSERT por chave externa no MuleSoft (sem query-then-update). É o caso de uso clássico que justifica campo custom; levar como decisão de arquitetura (vale para Account e para o padrão geral de chaves SAP). AccountNumber segue como código visível ao usuário.
- **Filtro "listar só sociedades" (pergunta do Flavio 07/08)**: candidato natural = `AccountLevel__c` (campo custom já existente na Account, visto nas suggestions do Inspector) — CONFIRMAR valores do picklist; se marcar o nível (Holding/País/Sociedad/Dealer), o filtro é `WHERE AccountLevel__c = 'Sociedad'`. Fallbacks: `AccountNumber IN :códigosDoLote` (Mule bind) ou posição na hierarquia (Parent.Parent = Holding e tem filhos) — frágeis; o nível explícito é o desenho certo.
- **Estado**: ⏳ 3 sociedades = preencher JÁ (códigos conhecidos, edição manual — Diego); ⏳ 22 dealers = quando o GrupoQ devolver `GrupoQ_HU046_Codigos_SAP_Centros.xlsx`; na mesma leva eu preencho BranchCode__c dos 158 cupos + regero CMDT (fecha wire B do join por código).
- **Quem consome**: HU-046 (cupo da unidade via CurrentOwner→AccountNumber), HU-045 T10 (Asset.AccountId da sociedade), MuleSoft (resolver conta pelo CompanyCode/centro do payload SAP), Flavio/estoque (Id C101 confirmado: 001WK00002EjOWaYAN — mas a chave oficial é AccountNumber, nunca Id fixo).
- ⚠️ **CORREÇÃO 07/08 (describe completo da Account)**: `Sociedad__c` EXISTE (Text Area 255, label "Sociedad") — o erro do Flavio era FLS do usuário dele, não inexistência. Text Area 255 É filtrável em SOQL. PENDENTE: semântica/população (provavelmente atributo nas contas de CLIENTE, não nas contas-sociedade) — query de verificação enviada. Item novo: dar FLS de Sociedad__c ao usuário de integração.
- **Describe completo da Account (07/08) — campos relevantes ao mapping SAP**: `AccountLevel__c` (Picklist "Nivel de Cuenta" — valores pendentes), `AccountNumber` (Text 40), **`SourceSystemIdentifier` (Text 85, standard "Source System ID")** — casa com Vehicle.SourceSystemIdentifier do T18/HU-045: CONVENÇÃO cross-objeto candidata para a chave SAP (semântica certa, standard; porém NÃO indexado/external-id → para upsert por chave e índice, segue valendo o custom External ID OU pedir índice custom ao suporte SF), `Country__c` (Picklist País), `CustomerCodeRPA__c` (Text Area 255 "Codigo Cliente" — provável KUNNR dos clientes RPA; Text Area NÃO pode ser External ID), `CurrencyCode__c`, `TaxID__c`, Person Accounts habilitadas (clientes = person account; hierarquia = business).
- **Premissa de carga SAP formalizada (07/08, pergunta do Alisson)**: a carga de veículos vinda do SAP DEVE preencher `Vehicle.CurrentOwnerId` — em estoque = Account do DEALER/sucursal (resolvida via código do centro → AccountNumber, esta convenção); na venda, a propriedade transfere para a Account do cliente (histórico via AssetAccountParticipant + par Asset). Doc oficial: Vehicle.CurrentOwnerId = "the account that currently owns the vehicle" (developer guide, sforce_api_objects_vehicle). Sem essa coluna na carga, o wire B da HU-046 (cupo por sucursal) e o modelo de posse da HU-045 não funcionam.
- Pendente de data fix junto: espaço duplo em "GrupoQ Active Motors  Managua" (rename ao editar as contas).

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
