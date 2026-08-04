# Estrutura de contas GrupoQ na DevSales (capturada em 04/08/2026)

Fonte: query SOQL executada por Diego no Workbench (Account WHERE Name LIKE '%Grupo Q%' / '%GrupoQ%').
Todas com record type `BusinessAccount`, campo `Type` vazio.

## Modelo confirmado por Diego (04/08/2026)

Ramificação por `Account.ParentId` em 4 níveis: **holding → país → sociedade → dealer**.
Cada dealer tem um registro de **BusinessProfile** com `BusinessPartnerType = Sales Dealer`
(é aqui que a classificação de dealer vive — não no Account).

## Níveis identificados pelo nome

**Holding**
- GrupoQ Holding (001WK00002EjOWYYA3)

**Sociedades (país / company code)**
- GrupoQ Costa Rica (001WK00002EjOWZYA3)
- GrupoQ Costa Rica C101 (001WK00002EjOWaYAN) — código de sociedade C101 (mesmo código do pricebook "C101 CR" analisado em 04/08)
- GrupoQ Costa Rica C105 (001WK00002EjOWbYAN)
- GrupoQ Nicaragua (001WK00002LhiS5YAJ)
- GrupoQ Nicaragua N105 (001WK00002Lhj1ZYAR)

**Sucursais / filiais (CR)**
- GrupoQ La Uruca, GrupoQ Lindora, GrupoQ Terrazas Lindora, GrupoQ Liberia, GrupoQ Guapiles, GrupoQ San Carlos, GrupoQ Perez Zeledon, GrupoQ Ayarco, GrupoQ Vehiculos La Uruca, GrupoQ Ventas Guapiles

**Por marca**
- GrupoQ Forland: La Uruca Sucursal Central, Guapiles, Liberia, Perez Zeledon, San Carlos
- GrupoQ Active Motors: Managua, Paseo Las Flores, SABANA, Sucursal Central

**Por área de negócio**
- GrupoQ Uruca Usados, GrupoQ Uruca Flotas, GrupoQ La Uruca Repuestos

**Dados de teste (limpar antes de UAT)**
- Cliente TEST GrupoQ, Teste GrupoQ, 8x "Test GrupoQ Postman" (duplicadas geradas por testes de API)

## Decisão de arquitetura relacionada (thread Humberto/Diego Braz, 04/08/2026)

- Asset de veículo em estoque: `Asset.AccountId` = conta da sociedade dona do estoque
  (resolução pelo código da sociedade que vem do SAP — usar External Id na conta).
- `AssetAccountParticipant` não é criado na carga de inventário; entra na venda/entrega,
  quando o Asset transfere para a conta do cliente e a sociedade permanece vinculada
  como vendedora.
- Etapas de propriedade: estoque GrupoQ → dealer → cliente (Diego Braz), refletidas na
  troca de `Asset.AccountId` + participantes.

## Pendências de captura

- Campo External Id com o código da sociedade (existe? qual API name?) — necessário
  para o Mule resolver a conta na carga de inventário sem depender do nome.
- Assets / Vehicles / AssetAccountParticipant existentes (queries enviadas em
  04/08, aguardando resultado).
- Confirmar API names exatos do BusinessProfile usado (objeto e campo
  BusinessPartnerType) para referência em automações e relatórios.
