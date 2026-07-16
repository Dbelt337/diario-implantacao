# Próximos passos — Estruturação do catálogo e carga de veículos

Base: ESTRUTURA-CATALOGO.md (modelo de 2 eixos) + COBERTURA-NATIVA.md +
DECISOES-ARQUITETURA.md. Ordem recomendada:

## Fase 0 — Validar o estado atual (AGORA)
- [ ] Rodar `VALIDACAO-ESTADO.soql` (Inspector/Workbench) — contagens e amostras.
- [ ] Rodar `DESCRIBE-vehicle.apex` (Anonymous Apex) — campos reais de Vehicle e
      VehicleDefinition (obrigatórios + lookups) para montar a carga.
- [ ] Registrar o resultado: o que já existe (Product2, Price Book C101) vs
      o que falta (VehicleDefinition/Vehicle = provavelmente 0).

## Fase 1 — Confirmar features nativas (rubrica #4)
- [ ] Product Catalog / Product Category / Product Attribute habilitados?
      (se as queries do bloco 3 do .soql erram, a feature não está ligada).
- [ ] Location / ProductItem / SerializedProduct disponíveis (inventário nativo)?
- [ ] Cilindrada: `VehicleDefinition.EngineCubicCapacity` / Product Attribute
      nativo cobre? (decide se `Cilindrada__c` custom é necessário).

## Fase 2 — Carregar VehicleDefinition (definições / catálogo de veículos)
Ordem: **VehicleDefinition primeiro** (gera os Ids), **depois Vehicle**.
- [ ] Preparar CSV de VehicleDefinition com os campos do describe. Mínimos
      esperados: `Name` (obrigatório) + specs (Make/Model/Year, BodyType,
      EngineCubicCapacity, TransmissionType, FuelType…) + **`GeoCountryId`**
      (país — chave do catálogo por país).
- [ ] Carregar via Data Loader / Inspector (import).
- [ ] Relacionar VehicleDefinition ↔ `Product2` e ↔ `BusinessBrand`
      (marca) conforme o modelo.

## Fase 3 — Carregar Vehicle (unidades)
- [ ] CSV de Vehicle referenciando `VehicleDefinitionId`. Campos-chave:
      `Name`, `VehicleIdentificationNumber` (VIN),
      `VehicleRegistrationNumber` (placa), `ConditionType` (New/Used),
      `AssetId` (se ligar a Asset), `VehicleDefinitionId`.
- [ ] Usados: `ConditionType = Used` + valores de mercado
      (AverageMarketValue/MarketPrice) — carga individual por VIN.
- [ ] Relacionar veículo ↔ cliente via `AssetAccountParticipant`
      (Stakeholder Role = Customer) quando aplicável.

## Fase 4 — Estruturar o catálogo por linha (eixo Produto)
- [ ] Criar `Product Catalog` por linha (Autos Novos, Motos, Repuestos, PA…).
- [ ] Criar `Product Category` dentro de cada (SUV/Sedan/Pickup; Filtros/Frenos…).
- [ ] Associar `Product2` às categorias (`ProductCategoryProduct`).
- [ ] Atributos (cilindrada, cor, tração) via `Product Attribute`.

## Fase 5 — Eixo comercial (Price Books)
- [ ] Criar/organizar Price Books por **sociedade × tipo de venda**
      (C101-Retail, C101-Fleet, C101-Motos, C101-PA…), multimoeda.
- [ ] Frotas: reusar catálogo de Autos com o Price Book de frota (não duplicar).
- [ ] Repuestos: preço dinâmico via SAP (não Price Book estático).

## Fase 6 — Compatibilidade de peças (Repuestos/PA)
- [ ] Definir a tabela de compatibilidade `VehicleDefinition` ↔ peça
      (dado OEM). Objeto custom até a integração do catálogo do fabricante.
- [ ] Busca por descrição/marca-modelo/VIN com refino por categoria
      (SOSL + ProductCategory) — ver cenários de busca HU-030.

## Dependências externas (marcar como bloqueio, não travar o resto)
- Catálogo OEM / compatibilidade viva → MuleSoft.
- Estoque em tempo real / preço Repuestos → SAP (MuleSoft; cache diário + real-time no fechamento).
- Crédito → CrediQ/FSC. Docs → SharePoint.

## Pendências a confirmar com o cliente
- Autos Usados entram nesta versão?
- Definição de "BIN" (busca de peças).
- Governança master data (auto-criar vs solicitação — HU-039).
