# Entrega — Catálogo de Productos y Precios (DevSales) · 14/07/2026
**Arquiteto:** Diego Beltrão · **Escopo desta entrega: CATÁLOGO.** (Descontos = próxima fase. Fluxos de pedido: fora de escopo, ver nota final.)

## O que foi construído

**1. O modelo de catálogo — 100% sobre o standard da plataforma.**
Cada versão vendível de veículo é um **Produto** Salesforce, identificado pelo **código oficial do QRM/SAP (OCN + año)** — a mesma chave que a fábrica e o cotizador usam — e associado à sua **marca** pelo cadastro nativo de Business Brands do Automotive Cloud (23 marcas já registradas). Nenhum objeto novo e nenhum campo custom onde a plataforma já oferece o nativo — essa é a regra de governança adotada e aplicada.

**2. O modelo de preços — uma lista por sociedad, preços de negócio auditados.**
Duas listas de preços ativas: a **Standard** (preço de lista, exigência da plataforma) e a **C101 Costa Rica** (lista comercial). A estrutura já está preparada para o rollout: uma lista por sociedad (C105 motos pronta para ativar) e, no futuro, por país/moeda. Na lista comercial, cada versão carrega os **7 preços de negócio** que hoje vivem no QRM: Precio de Lista, Precio Mínimo Asesor, Precio Exonerado, Precio Exonerado Mínimo, Gastos, Monto de Cashback e Aplica Cashback — com acesso controlado por permission set.

**3. Auditoria nativa — o controle que a planilha nunca deu.**
Toda alteração de qualquer preço fica registrada automaticamente (**quem mudou, quando, valor anterior → novo**) pelo field history da plataforma. Isso substitui com vantagem o rastro de "solicitud/autoriza" que hoje vive dentro do QRM e elimina a necessidade de objetos ou planilhas de controle.

**4. A carga — o catálogo real da Costa Rica, completo, sem digitação.**
- **223 versões ativas** de 4 marcas: 113 Hyundai, 55 Chevrolet, 45 Isuzu, 10 Cadillac.
- **446 registros de preço** (lista + comercial), extraídos das **fontes oficiais** (Carga Masiva do QRM e Reporte de Precios CR).
- Carga executada por **pipeline programático com validação de integridade** — zero células digitadas à mão, zero preço no produto errado.
- Verificação final contra a fonte: amostras conferidas dígito a dígito com a planilha oficial do QRM.

**5. O contrato da integração ficou pronto de graça.**
O de-para **QRM → Salesforce validou 1:1**: as colunas da Carga Masiva do QRM correspondem exatamente aos campos implantados. O processo manual desta carga É a especificação do que o MuleSoft automatizará — planilha deixa de ser ferramenta de operação e passa a ser apenas legado de migração.

## O que o negócio ganha já
- Vendedor cotiza e o **preço certo aparece sozinho** — qualquer uma das 223 versões, do Grand i10 ao Escalade.
- **Preço tem dono e trilha**: mudou, ficou registrado.
- Base pronta para a fase de **Descontos**: os pisos por alçada (Precio Mínimo Asesor / Gerente de Venta / Gerente de Marca) já foram mapeados das fontes QRM, e a regra de aprovação vigente está documentada (preço novo ou redução → requer visto bueno; aumento → não requer).

## Fundamentação — modelo oficial do Automotive Cloud, dimensionado para o GrupoQ
A implementação segue o **Vehicle & Product Data Model do Salesforce Automotive Cloud** (Automotive Cloud Developer Guide) — todos os objetos citados foram verificados por describe na própria org:

| Camada | Objeto/mecanismo oficial | Papel no GrupoQ (6 países · 22 marcas · N sociedades) |
|---|---|---|
| **Marca** | `BusinessBrand` (objeto standard do Automotive Cloud, transversal a Sales/Loyalty) | Catálogo corporativo ÚNICO de marcas: as 22 marcas são cadastradas **uma vez** e valem para os 6 países — produto de qualquer país aponta para a mesma marca; relatório regional por marca sai nativo |
| **Produto/Versão** | `Product2` estendido pelo Automotive Cloud (`BusinessBrandId`, `MakeName`, `ModelName`, `VersionName`, `ManufacturerName` — campos standard) | 1 registro por versão comercial (OCN + año = ProductCode). O MESMO produto vendido em mais de um país continua sendo 1 registro — o que muda por país é o preço, nunca o produto |
| **Preço** | `Pricebook2`/`PricebookEntry` (pricing standard da plataforma — o Automotive Cloud não o substitui, o adota) | **1 lista comercial por sociedad** (C101, C105, S101, H101...): escala linear para todas as sociedades dos 6 países; os 7 preços de negócio são atributos da ENTRADA (produto×lista), então cada sociedad tem seus valores sem duplicar produto |
| **Moeda** | Multicurrency da plataforma (`CurrencyIsoCode` por registro) | Cada lista/entrada na moeda do seu país (CRC, USD, GTQ, HNL, NIO, PAB) — a "lista de moedas por país" do GrupoQ vira o cadastro Manage Currencies |
| **Espec/Estoque físico** | `VehicleDefinition` (espec do modelo/versão, `ProductId` → Product2) e `Vehicle` (unidade com VIN) | Fase futura (test drive/reserva de unidade): a espec técnica referencia o MESMO Product2 do catálogo — sem duplicação entre comercial e físico |

**Por que esse desenho aguenta a escala:** 22 marcas × 6 países × N sociedades não multiplica produto — multiplica **entrada de preço**, que é exatamente o objeto que a plataforma desenhou para escalar (o pricing standard suporta milhões de entradas). Rollout de um país novo = ativar a moeda + criar as listas das sociedades + carregar entradas. Zero metadado novo.

## Decisões de governança registradas
1. **Não criar objeto custom quando o processo cabe no standard** (objeto de solicitud descartado; auditoria = history nativo).
2. **Não criar campo custom quando existe nativo** (marca = Business Brand/MakeName nativos).
3. **Moeda**: org com CRC ativa; as fontes indicam que CR precifica em USD — decisão pendente de negócio antes da carga de produção (ativar USD e recarregar, ou operar em CRC).
4. Data de fim do cashback: campo a definir na fase de descontos/promos.

## Nota de escopo — fluxos
Dois fluxos de automação de pedido foram construídos sob especificação anterior e **estão fora do escopo desta entrega**. Recomendação: mantê-los **desativados** até a fase de pedidos (desativação em 2 cliques; pacote de remoção também disponível). Nada do catálogo depende deles.

## Próxima fase proposta: DESCONTOS
Matriz de descontos por alçada alimentada pelos pisos já carregados (PMV/Exonerado por versão) + aprovação eletrônica espelhando a regra do QRM — mesma engine para desconto na venda e para cambio de precio no catálogo.
