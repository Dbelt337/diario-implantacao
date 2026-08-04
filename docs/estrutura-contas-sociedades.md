# Estrutura de contas GrupoQ na DevSales (capturada em 04/08/2026)

Fonte: query SOQL executada por Diego no Workbench (Account WHERE Name LIKE '%Grupo Q%' / '%GrupoQ%').
Todas com record type `BusinessAccount`, campo `Type` vazio.

## Modelo confirmado por Diego (04/08/2026)

Ramificação por `Account.ParentId` em 4 níveis: **holding → país → sociedade → dealer**.
Cada dealer tem um registro de **BusinessProfile** com `BusinessPartnerType = Sales Dealer`
(é aqui que a classificação de dealer vive — não no Account).

## Hierarquia confirmada por query com ParentId (04/08/2026)

- Nível 1 Holding: GrupoQ Holding
- Nível 2 País: GrupoQ Costa Rica, GrupoQ Nicaragua
- Nível 3 Sociedade: C101 e C105 (CR), N105 (NI)
- Nível 4 Dealer:
  - C101: Ayarco, Guapiles, La Uruca, Liberia, Lindora, Perez Zeledon, San Carlos,
    Uruca Flotas, Uruca Usados
  - C105: Active Motors (Paseo Las Flores, SABANA, Sucursal Central), Forland
    (Guapiles, La Uruca Sucursal Central, Liberia, Perez Zeledon, San Carlos),
    Terrazas Lindora, Vehiculos La Uruca, Ventas Guapiles
  - N105: Active Motors Managua

Anomalia corrigida em 04/08/2026 (Apex anônimo, log 07LWK00000QO2rK2AT):
- "GrupoQ La Uruca Repuestos" reparenteada do dealer GrupoQ La Uruca para a
  sociedade C101 — padronizada no nível 4 com Uruca Usados/Flotas.
- Country__c (obrigatório universal, estava vazio em TODA a estrutura GrupoQ)
  preenchido em 27 contas: ramo Costa Rica = CR, ramo Nicaragua = NI, padrão
  ISO-2 já usado na org (CR 1276 registros, SV 1, NI 1).
- Pendente: Country__c da GrupoQ Holding (provável SV, aguardando confirmação).
- Alerta dado ao time de integração: antes da correção, qualquer update nessas
  contas falhava com REQUIRED_FIELD_MISSING [Country__c].

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

## Escopo venta guiada por record type (decisao Diego, 04/08/2026)

Record types reais (query 04/08): Lead GQLeads{Autos,Motos,Flotas,Usados,RepuestosPA};
Opportunity GQOpportunities{Autos,Motos,Flotas,Mayorista,Usados,RepuestosPA}.

- R1: Autos e Motos (nuevo), Usados (usado), Repuestos & P/A (repuestos).
- FLOTAS: adiado para Release 2 — fica comentado no roteador do ventaGuiadaModal.
- MAYORISTA: experiencia a definir com negocio (sem mapeamento ate decisao).
- Tipos nao mapeados abrem o modal com mensagem "disponible en una proxima version"
  (nunca cair silenciosamente na experiencia de nuevo).
- Roteador migra de contains no label para mapa por DeveloperName (deterministico,
  imune a traducao de labels).
