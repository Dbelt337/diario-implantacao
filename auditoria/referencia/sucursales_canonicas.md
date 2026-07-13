# Regra canônica — sucursal física é o grão do hand-off (HU-009)

**Fontes:** Sociedades_Marcas_Sucursales_1_1.xlsx (rede física, 36 pontos) × Sucursales_QRM_3.xlsx (registro QRM/SAP, 596 linhas). Tabela resolvida em `sucursales_canonicas.csv`.

## As três coisas que a palavra "sucursal" significa (e não podem se misturar)
| Universo | Grão | Qtde | Serve para |
|---|---|---|---|
| **Rede física** (planilha Sociedades_Marcas_Sucursales) | o prédio onde o cliente entra | 36 (23 com VENTAS) | **hand-off HU-009**: `Event.BranchCode__c` + Public Group + List View |
| **QRM/SAP** (Sucursales_QRM_3) | Sociedad + Centro SAP + Almacén | 596 (inclui revendedores terceiros, GOLLO, Autopits, usados, flotas) | integração/faturamento — **NUNCA** vira grupo nem código de hand-off |
| **ServiceTerritory** (org) | agenda do Scheduler | o que foi cadastrado | Test Drive (Parte D); deve carregar o código canônico |

A mesma Uruca aparece no QRM como C101/C011/1200 (autos), C105/C311/1200 (Active Motors), C817 (usados) e C211/1260 (Autopits) — 1 lugar físico, N registros SAP. Por isso **Almacén SAP não identifica sucursal** (1200 repete entre sociedades) e o QRM não pode ser a fonte do cadastro de sucursales no Salesforce.

## Decisões (arquitetura)
1. **Código canônico Salesforce-owned**: `<PAIS>_<MNEMONICO>` (ex.: `SV_AUTOSUR`, `GT_ZONA9`) — estável, sem acento/espaço, cabe em `Event.BranchCode__c` Text(20) e no DeveloperName `GRP_Sucursal_<codigo>`. País segue `pais_sociedade.md` (PA = Panamá; a colisão mnemônica com "PA = Piezas y Accesorios" do Industry é aceita — contextos disjuntos).
2. **Só sucursales com VENTAS ganham Public Group** (23). Taller/bodega puras não participam do hand-off. Autopits é rede de serviço, não sucursal de venda.
3. **Piloto Parte B: `SV_AUTOSUR` + `SV_SANTAELENA`** — mesmas país (limita raio), ambas 3S e bodega principal, cobrem o cenário completo ventas+taller+repuestos.
4. O mapa sucursal↔(sociedad, centro, almacén) fica como dado de referência para integração; **não** dirige sharing.
5. ServiceTerritory deve carregar o código canônico (Name ou campo), para o flow espelho do Test Drive (Parte D) resolver `Event.BranchCode__c` a partir do território.

## Verificação pendente no org (Inspector)
```sql
SELECT Id, Name, IsActive, ParentTerritory.Name, OperatingHours.Name FROM ServiceTerritory ORDER BY Name
```
Se o cadastro feito seguiu o QRM (596 linhas / grão SAP), está no grão errado para o hand-off — corrigir para a rede física antes de criar grupos.

## Alinhamento com a integração (payload dos canais digitais)
O contrato de entrada de leads já usa o mnemônico da sucursal no `preferredSellers.dealerCode`: `C101-URUCA-HYUNDAI` = sociedad + **mnemônico da sucursal** + marca. O código canônico `<PAIS>_<MNEMONICO>` desta tabela usa o MESMO mnemônico do segmento central do dealerCode (URUCA → CR_URUCA). Regra: ao cadastrar novas sucursales, o mnemônico deve coincidir com o usado no dealerCode da integração.

## Origem do lead (decisão FINAL 11/07 — LeadSource único)
`ChannelCode__c` foi **eliminado** (Lead e Opportunity, decisão do arquiteto): o campo nativo **LeadSource** é a única fonte de origem.
- Vendedor (criação manual): escolhe o LeadSource na tela (Publicidad/Facebook/Instagram/Tiktok/Página web GrupoQ/Página web de la marca/...).
- Sistemas (API): o middleware mapeia o `channelCode` do payload para um valor do LeadSource (ex. WEB_MARCA → "Página web de la marca"). O catálogo canônico É a lista de valores do LeadSource.
- Conversão: LeadSource copia para Opportunity.LeadSource NATIVAMENTE — zero mapping manual.
- Trade-off aceito: picklist standard não é restringível — API pode gravar string fora da lista. Pendência para o go-live da integração: validation rule no Lead restringindo LeadSource ao catálogo em criações via API.
- O GVS `ChannelCode` ficou órfão → remover (destructive).

## Escopo CR (decisão 11/07 — piloto atende só Costa Rica)
A planilha física subestima CR (só Uruca com VENTAS); o registro QRM mostra a rede de vendas real da C101. **Fonte para CR = QRM**: 8 sucursales de ventas — CR_URUCA, CR_LIBERIA, CR_SANCARLOS, CR_LINDORA, CR_AYARCO, CR_SANTAANA, CR_GUAPILES, CR_PEREZZELEDON (mnemônicos = segmento do dealerCode, ex. C101-URUCA-HYUNDAI). "Uruca Usados" e "Uruca Flotas" são CANAIS dentro do prédio da Uruca — não são sucursales separadas (grão físico). A picklist Event.BranchCode__c e os grupos GRP_Sucursal_* cobrem só esses 8 até o rollout dos demais países; os 2 grupos SV do piloto original ficam criados para o futuro.

## Achado OWD (11/07)
Opportunity OWD interno na DevSales = **Public Read Only** → o share da Parte B é redundante NESTA sandbox (todos leem tudo); T2 passa trivialmente. O desenho da HU-009 pressupõe **Private** (produção). Decisão: NÃO mudar o OWD na sandbox compartilhada; validar T2 na org QA/UAT com OWD espelhando produção. O flow já está correto para Private.

## Role hierarchy DevSales (levantada 11/07) — implicações
A hierarquia v16 JÁ EXISTE na DevSales: Holding → CEO → GQ_Ventas → GQ_Ger_Regional_CA → {GQ_Dir_Marca_Regional → Ger_Marca×6 + GQ_Dir_Ventas_Online → Ger_VentasOnline×6 → AVO×6} + GQ_Ger_Pais_CR → 7 sucursales (Ger_Suc/Op/Sup_PDV) + ramo Usados (Ger/Op/Valuador).
- **CR = 7 sucursales nas roles, não 8**: "Santa Ana Comercial" e "Lindora" compartilham centro/almacén C011/1210 (QRM) — mesmo ponto físico. Ação pendente (confirmar com negócio): desativar valor `CR_SANTAANA` da picklist BranchCode e apagar `GRP_Sucursal_CR_SANTAANA`. Canonical CR passa a 7.
- Role lixo a remover: `dbeltCuentapersonalCliente` (teste, pendurada no CEO).
- QA está no modelo antigo (Asesor GQ {país} etc.) — migração = deploy additive da árvore GQ_* (metadado Role, gerável do export DevSales) + re-role dos usuários.
- Mnemônicos: roles usam CamelCase (LaUruca); grupos usam UPPER (URUCA) — namespaces distintos, padronizar no rollout dos demais países.

## Modelo de visibilidade fase 1 CR (aplicado 11/07)
- OWD DevSales: Lead Private ✅ · Opportunity Private ✅ · Account Public Read/Write (decisão pendente de apertar p/ Read Only). QA: Opportunity/Account Private ✅, Lead ReadWriteTransfer ❌ (virar Private).
- Roles v16: QA fase 1 CR encaixada (6 AVOs → GQ_AVO_CR, 2 sup → GQ_Ger_VentasOnline_CR). Roles velhas AsesorGQ_CR/SupervisorGQ_CR vazias = faxina futura.
- PS_Api com View/Modify All em humano (Vitor Sandy) nas DUAS orgs → remover assignment (igual decisão da auditoria de PSs DevSales).
- Prova do modelo: teste triplo (asesor não vê peer / gerente vê time / outro país não vê nada) — executar pós-recálculo em ambas.
