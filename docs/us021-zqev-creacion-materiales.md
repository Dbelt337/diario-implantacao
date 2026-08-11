# US-021 — ZQEV_DBM_CREACION_MATERIALES (alta de material de repuesto)

Contrato recebido de SAP em 11/08/2026 (doc + WSDL `ZWS_CREACION_MATERIALES`).
Fecha o gap apontado na HU-043 (`sinCatalogo`) e no `MaterialSearchService`
("solicitar material" no miss do SAP).

## Contrato

| Campo | Tipo SAP | Obrig. | Descrição |
|---|---|---|---|
| MATERIAL | MATNR (18) | Sim | Código do material a criar |
| SOCIEDAD | BUKRS (4) | Sim | Sociedade SAP |
| CANAL | VTWEG (2) | Sim | Canal de distribuição |
| SERIE | ZSERIE_APLIC | Sim | Série associada (ZREP exige série) |
| VER_DEFAULT | CHAR1 | Não | 'X' = lógica adicional + commit |
| → MENSAJE | CHAR255 | — | Resultado ou erro (texto livre) |

Regras internas da RFC: fixa Tipo Material **ZREP**, UoM **ZUN**, condição de
preço **ZQRP**; valida série (sem série o material é eliminado do
processamento) e **partida arancelaria** (sem ela o material é rejeitado).
Variantes: padrão, com versão default, outra sociedade, outro canal, outra série.

## Implementação (pacote `deploy-us021-creacion-materiales`)

- `SapMuleClient.creacionMateriales(MaterialCreateRequest)` →
  `POST /api/v1/materials` no MuleGateway (proposta de rota, mesmo padrão do
  mapa RFC→endpoint da fachada). Mock determinista valida os 4 obrigatórios.
- DTOs `MaterialCreateRequest` / `MaterialCreateResult` (ok + mensaje).
- 2 testes novos no `SapMuleClientTest` (mock com validação de série; modo
  real com resposta normalizada).

## Pontos de atenção para fechar com Emmanuel/Flavio (Mule)

1. **WSDL × documento divergem**: o WSDL declara todos os campos
   `minOccurs=0`; o documento diz MATERIAL/SOCIEDAD/CANAL/SERIE obrigatórios.
   Adotamos o documento (a validação de série é regra interna da RFC) — o
   Mule deve validar antes de chamar o SAP.
2. **MENSAJE é texto livre, sem código de sucesso**: a RFC não devolve flag.
   O contrato com o Mule precisa definir como distinguir sucesso de erro
   (parse do texto? código HTTP? campo `ok` derivado?). Na fachada assumimos
   que o Mule normaliza para `{ok, mensaje}` preservando o MENSAJE cru.
3. **Commit**: a policy do WS traz `enableCommit=false`, mas o documento diz
   que `VER_DEFAULT='X'` executa confirmação da transação. Confirmar quando o
   material fica efetivamente persistido (e se a chamada é idempotente para
   retry).
4. **Partida arancelaria**: pré-condição de dados SAP que o Salesforce não
   controla — o erro chega via MENSAJE; a UI deve exibi-lo tal cual.
5. Exemplo do doc usa SOCIEDAD `1000` e CANAL `Q1` — confirmar os valores
   reais por sociedade GrupoQ (C101/C105... e canal QB de usados/repuestos).

## Encaixe no fluxo

`lineasRepuestos` (HU-043) devolve `sinCatalogo` → o passo seguinte natural é
um botão "Solicitar creación de material" chamando `creacionMateriales` (com
sociedade/canal do contexto) e, no sucesso, upsert do `Product2` local por
`ProductCode` (mesmo padrão do leg SAP do `MaterialSearchService`). Fica como
tarefa da US-021 quando ela entrar em sprint.
