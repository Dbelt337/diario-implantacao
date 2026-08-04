# Estrutura de contas GrupoQ na DevSales (capturada em 04/08/2026)

Fonte: query SOQL executada por Diego no Workbench (Account WHERE Name LIKE '%Grupo Q%' / '%GrupoQ%').
Todas com record type `BusinessAccount`, campo `Type` vazio.

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

- Hierarquia (`ParentId`) das contas — a query não trouxe; capturar para confirmar
  holding → sociedade → sucursal.
- Campo External Id com o código da sociedade (existe? qual API name?).
- Objeto `Seller` (Automotive Cloud): Diego lembra que as contas foram marcadas como
  "sales dealer" fora do objeto Account — provável registro Seller por conta
  (SellerType = Dealer). Query enviada, aguardando resultado.
- Assets / Vehicles / AssetAccountParticipant existentes (queries 2–4 enviadas em
  04/08, aguardando resultado).
