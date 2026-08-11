# Demo para Diretores e Gerentes — quinta-feira, 13/08/2026

## Contexto

Na reunião anterior, o Hugo deixou claro o critério de aceite das demos: **"funcionalidade completa, testada e implementada para o cliente"** — não o acumulado de desenvolvimento dos sprints. Marcelino e Dubra reforçaram o mesmo ponto em conversas privadas com a Melisa.

Objetivo desta demo: mostrar **produto funcionando, tomando forma para o cliente** — com a marca, telas em espanhol e os modelos do GrupoQ. A jornada será demonstrada ao vivo, de ponta a ponta.

## O que já está entregue e funcionando

Hoje temos **38 automações funcionando**, cobrindo a jornada completa de Lead a Cotización.

### 1. Lead

- Entrada pela **UI ou pela integração**, já com produtos de interesse e vendedor preferido
- **Roteamento automático** por fila e skill via Omni-Channel
- **SLA de primeira atenção** com recordatórios e escalada
- **Controle de duplicados**
- **Máquina de estados** com motivo de descarte
- **Lead Score**

### 2. Conversão

- Leva tudo do lead para a oportunidade: dados, produtos de interesse
- **Record type correto por linha de negócio** — Autos, Motos, Usados, Repuestos/PA — cada um com seu sales process e caminho de etapas próprio

### 3. Oportunidade

- **Avalúo de usados**, com notificação ao proveedor
- **Test drive** com autorização em PDF
- **Aprovação de desconto** com matriz de decisão
- **Visitas** com hand-off entre sucursais
- **Venta guiada**: o vendedor escolhe veículo, acessórios, financiamento e gera a **cotización com linhas reais**

### 4. Console

- Gestão de **veículos demo** no console
  - Pendente um ajuste: nem o GrupoQ conseguiu transmitir corretamente a necessidade — alinhar antes da demo

## Roteiro sugerido para a demo ao vivo

1. Criar um lead pela UI (e mostrar a entrada via integração), com produtos de interesse e vendedor preferido
2. Mostrar o roteamento automático (fila + skill / Omni-Channel) e o Lead Score
3. Deixar o SLA de primeira atenção disparar recordatório/escalada (ou mostrar o histórico de um caso real)
4. Tentar criar um duplicado e mostrar o bloqueio
5. Percorrer a máquina de estados, incluindo descarte com motivo
6. Converter o lead → oportunidade com o record type da linha de negócio correta
7. Na oportunidade: avalúo de usado, test drive com PDF de autorização, aprovação de desconto pela matriz, visita com hand-off entre sucursais
8. Fechar com a venta guiada gerando a cotización com linhas reais

## Pendências rastreadas (não bloqueiam a demo, mas estão no radar)

| Item | Situação |
|------|----------|
| Ajustes HU-028 e HU-039 | Melisa e Diego vão fechar o entendimento dos ajustes |
| HU-119 — Integração SAP/MuleSoft (sincronização) | Dúvida da Vane sobre a **RN6** em aberto |
| HUs para o Time de Integração | Sem BA definido; Flavio indicou que a BA seria a Melisa — envolver o Paulo para viabilizar agenda |
| Ajuste de veículos demo (console) | Requisito do GrupoQ ainda mal definido |
| Deploy `Buscar_Lead_GrupoQ_FA` | Feito com o Davi (ver histórico deste repositório) |
