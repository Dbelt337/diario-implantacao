# Regra canônica — sucursal física é o grão do hand-off (HU-009)

**Fontes:** Sociedades_Marcas_Sucursales_1_1.xlsx (rede física, 36 pontos) × Sucursales_QRM_3.xlsx (registro QRM/SAP, 596 linhas). Tabela resolvida em `sucursales_canonicas.csv`.

## As três coisas que a palavra "sucursal" significa (e não podem se misturar)
| Universo | Grão | Qtde | Serve para |
|---|---|---|---|
| **Rede física** (planilha Sociedades_Marcas_Sucursales) | o prédio onde o cliente entra | 36 (23 com VENTAS) | **hand-off HU-009**: `Event.Sucursal__c` + Public Group + List View |
| **QRM/SAP** (Sucursales_QRM_3) | Sociedad + Centro SAP + Almacén | 596 (inclui revendedores terceiros, GOLLO, Autopits, usados, flotas) | integração/faturamento — **NUNCA** vira grupo nem código de hand-off |
| **ServiceTerritory** (org) | agenda do Scheduler | o que foi cadastrado | Test Drive (Parte D); deve carregar o código canônico |

A mesma Uruca aparece no QRM como C101/C011/1200 (autos), C105/C311/1200 (Active Motors), C817 (usados) e C211/1260 (Autopits) — 1 lugar físico, N registros SAP. Por isso **Almacén SAP não identifica sucursal** (1200 repete entre sociedades) e o QRM não pode ser a fonte do cadastro de sucursales no Salesforce.

## Decisões (arquitetura)
1. **Código canônico Salesforce-owned**: `<PAIS>_<MNEMONICO>` (ex.: `SV_AUTOSUR`, `GT_ZONA9`) — estável, sem acento/espaço, cabe em `Event.Sucursal__c` Text(20) e no DeveloperName `GRP_Sucursal_<codigo>`. País segue `pais_sociedade.md` (PA = Panamá; a colisão mnemônica com "PA = Piezas y Accesorios" do Industry é aceita — contextos disjuntos).
2. **Só sucursales com VENTAS ganham Public Group** (23). Taller/bodega puras não participam do hand-off. Autopits é rede de serviço, não sucursal de venda.
3. **Piloto Parte B: `SV_AUTOSUR` + `SV_SANTAELENA`** — mesmas país (limita raio), ambas 3S e bodega principal, cobrem o cenário completo ventas+taller+repuestos.
4. O mapa sucursal↔(sociedad, centro, almacén) fica como dado de referência para integração; **não** dirige sharing.
5. ServiceTerritory deve carregar o código canônico (Name ou campo), para o flow espelho do Test Drive (Parte D) resolver `Event.Sucursal__c` a partir do território.

## Verificação pendente no org (Inspector)
```sql
SELECT Id, Name, IsActive, ParentTerritory.Name, OperatingHours.Name FROM ServiceTerritory ORDER BY Name
```
Se o cadastro feito seguiu o QRM (596 linhas / grão SAP), está no grão errado para o hand-off — corrigir para a rede física antes de criar grupos.

## Alinhamento com a integração (payload dos canais digitais)
O contrato de entrada de leads já usa o mnemônico da sucursal no `preferredSellers.dealerCode`: `C101-URUCA-HYUNDAI` = sociedad + **mnemônico da sucursal** + marca. O código canônico `<PAIS>_<MNEMONICO>` desta tabela usa o MESMO mnemônico do segmento central do dealerCode (URUCA → CR_URUCA). Regra: ao cadastrar novas sucursales, o mnemônico deve coincidir com o usado no dealerCode da integração.

## Quem preenche ChannelCode (decisão)
- `Lead.ChannelCode__c`: a integração dos canais digitais (payload `channelCode`, ex. WEB_MARCA). Lead criado manualmente por vendedor: fica em branco (= não originado por canal digital; não se inventa proveniência).
- `Opportunity.ChannelCode__c`: Lead Conversion Mapping nativo na conversão. Nenhum usuário ou flow escreve nele.
- Opp criada sem Lead (mostrador): em branco — correto.
