# Arquitetura Atual — Brasil TecPar

> **Jornada Macro TELECOM** — Diagrama que detalha os entregáveis para o Macro
> Processo do TELECOM, tanto para os segmentos **B2B** quanto **B2C**.
>
> Este documento é a transcrição do desenho de arquitetura atual (memória de
> contexto). Fonte: diagrama "Jornada Macro TELECOM".

## Visão geral em camadas

O fluxo é organizado em camadas, conectadas entre si por **REST APIs**:

```
Fontes de dados  ──►  Salesforce Customer 360  ──►  Mulesoft Anypoint  ──►  Sistemas Externos (BSS/OSS)
   (Data Lake,          (núcleo CRM / 360)          (Orquestração         (catálogo, provisionamento,
    Zendesk)                                          de APIs)              billing, rede, etc.)
```

A integração entre **Salesforce Customer 360 → Mulesoft → Sistemas Externos**
é feita via **REST APIs** em cada fronteira.

## 1. Fontes de dados (entrada)

- **Data Lake** — Data Lake BTP
- **Zendesk** — Atendimento ao Cliente

## 2. Salesforce Customer 360 (núcleo)

Módulos internos:

### Marketing
- Marketing e Comunicação
- Engagement & Personalização
- Feedback

### Vendas & Gestão Comercial
- Gestão de Leads
- Cadastro & Engajamento de Clientes
- Gestão de Oportunidades & Venda Guiada
- Planejamento de Previsão & Gestão de Carteira

### Gestão de Catálogo
- Gestão de Catálogo Comercial
- Gestão de Ofertas & Promoções
- Insumos CPQ
- Gestão de Contratos (Customer Core BTP)
- Gestão de Pedidos
- Análise de Serviço & Previsão de Churn

### Experiência Digital
- Portal de Processos

### Tableau
- Análise de Vendas
- Análise de Gerenciamento de Pedidos
- Análise de Serviço & Previsão de Churn

### Field Services
- Serviço de Campo

### Data 360
- CRM Data
- Data Streams

## 3. Mulesoft Anypoint Platform (integração)

- Orquestração de APIs
- Camada de integração entre o Salesforce Customer 360 e os Sistemas Externos
  (BSS/OSS), sempre via REST APIs.

## 4. Sistemas Externos (BSS/OSS)

- Gestão de Pedidos de Serviço
- Catálogo de Produtos Técnicos
- Base Master de Clientes
- Fault Management
- Service Provisioning
- Network Performance
- Service Fulfilment
- Billing
- Cobrança
- Configuration

## Legenda / capacidades (tags do diagrama)

Agentforce · Marketing · Integration · Data 360 · Sales · Platform ·
Communications · Analytics · Experience · Slack

---

_Documento de memória de contexto. Atualizar conforme o desenho de arquitetura evoluir._
