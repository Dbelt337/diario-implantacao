# ADR US025-H6-02 — Descuentos exonerados na matriz de descontos

**Status:** Aprovado (Diego, arquiteto) · **Data:** 2026-07-14
**Contexto:** Santiago identificou que a planilha do cliente traz, por marca/sociedade,
colunas de teto separadas para vendas **exoneradas** (regime de exoneração fiscal —
diplomatas/governo/regimes especiais, comum em CR/HN/NI), em cada nível da escada:
`descuento_gerente_ventas` / `descuento_exonerados_gerente_ventas`, idem `gerente_marca`
e `vicepresidencia`. Evidência de que é dimensão real e não cópia: FORLAND H105 tem
VP normal = 10 e VP exonerado = **0** (teto exonerado pode ser MENOR).

---

## D1 — Modelagem na Decision Matrix: colunas de OUTPUT adicionais (formato wide)

**Decisão:** a `Discount_Rules_GrupoQ` mantém as mesmas filas (chave Marca/Sociedad) e
ganha colunas de saída novas: `MaxGerVentasExon`, `MaxGerMarcaExon` (e `MaxVPExon` como
dado, ver D4). **Não** criar input "Exonerado Sí/No".

**Por quê:** (a) espelho 1:1 da planilha do cliente ⇒ carga e atualizações futuras são
copy-paste de filas, sem transformação — coerente com a diretriz "updates de filas, cero
deploy"; (b) input extra dobraria as filas (~36+) e cada atualização do cliente exigiria
desdobrar linhas manualmente = fonte de erro; (c) os APROBADORES são os mesmos nos dois
regimes — só o teto muda — então a escada, o CMDT e a orquestração ficam intactos.

**Consequência no flow (`Opp_AS_EvaluarDescuento` v3):** mapear os outputs novos e, logo
após `Matrix_OK`, UM Assignment condicional: se a venda é exonerada, `vMaxGerVentas` /
`vMaxGerMarca` recebem os valores `*Exon`. `Evaluar_Nivel` e todo o resto não mudam.

## D2 — Origem do flag na Opportunity: `VentaExonerada__c` (checkbox)

**Decisão:** criar `VentaExonerada__c` (Checkbox, default false) na Opportunity,
preenchido pelo asesor; habilitar **field history tracking** (muda teto de aprovação ⇒
auditável). Evolução futura (fora do H6): derivar do regime fiscal do cliente/cotização
quando esse dado existir no Account — vira fórmula/flow, sem mudar a matriz.

**Descartado:** esticar TipoVenta (Autos/Motos/…) com variantes "exonerado" — mistura
duas dimensões ortogonais (linha de negócio × regime fiscal) e explode a matriz.

## D3 — Semântica dos tetos exonerados

1. **`0` significa PROIBIDO nesse nível** (não "sem limite"). O flow já trata isso
   naturalmente: `LessThanOrEqualTo 0` falha para qualquer % positivo ⇒ escala ou NoPermitido.
2. **Célula vazia na carga = 0 (fail-closed), nunca null.** Null nos outputs exonerados
   com `VentaExonerada__c = true` derrubaria a venda no fail-safe da matriz; carregar 0
   explícito evita ambiguidade. Validar na carga: nenhuma célula em branco.

## D4 — Nível Vicepresidencia: CARREGAR como dado, NÃO ligar no processo

**Decisão:** as colunas `descuento_vicepresidencia` / `..._exonerados_vicepresidencia`
**entram na matriz** (espelho completo da planilha, sem perda de dado), mas o flow
**não consome** `MaxVP*` e o CMDT **não recebe** tokens `VP_*` até resposta do negócio
(Melisa). Interim: desconto acima de `MaxGerMarca` ⇒ `NoPermitido`.

**Impacto de negócio a comunicar (torna a pergunta urgente):** pelos números da planilha,
GM ≤ 4–8% e VP = 10% ⇒ no interim, descontos entre o teto GM e 10% ficam BLOQUEADOS.
Se o negócio pratica esses descontos hoje, a resposta da Melisa vira pré-requisito de go-live.

**Se Melisa aprovar VP:** delta pequeno e já conhecido — recolocar `R_N3`/`A_N3` no flow
(removidos na v2), mapear `MaxVP`/`MaxVPExon`/`RolVP`, e criar tokens `VP_<país>` no
CMDT (deixam de ser órfãos). Se negar: colunas VP ficam como dado morto documentado.

## D5 — Teto do asesor (`MaxSinAprobacion`) ausente na planilha

**Decisão:** a planilha do cliente não traz coluna de auto-aprovação do asesor. Enquanto
o cliente não confirmar, **`MaxSinAprobacion` = 0 (fail-closed: todo desconto > 0 requer
aprovação)** nas filas carregadas da planilha; pedir ao cliente que inclua a coluna na
versão final. Não inventar teto de asesor — é dinheiro.

## D6 — Sequência de implementação (Santiago)

1. Criar `VentaExonerada__c` na Opportunity (checkbox + history tracking) — DevSales.
2. Adicionar colunas `MaxGerVentasExon`, `MaxGerMarcaExon`, `MaxVP`, `MaxVPExon` na
   Decision Matrix e carregar a planilha completa (regras D3/D5). VP entra como dado (D4).
3. Flow v3 (delta sobre a v2 deployada): outputs novos + 1 Assignment condicional
   pós-`Matrix_OK`. (Diego gera o XML quando os API names de 1–2 estiverem confirmados.)
4. Teste: mesma opp com/sem checkbox exonerada deve mudar de nível com o mesmo % (usar
   FORLAND H105, onde os tetos divergem bastante).
5. NÃO criar nada de VP no processo (flow/CMDT) até decisão registrada aqui.

## Perguntas abertas (donos)

| # | Pergunta | Dono | Bloqueia |
|---|---|---|---|
| 1 | Escada tem nível VP para descontos extremos ou a coluna é formato legado? (impacto: faixa GM–10% bloqueada no interim) | Melisa (negócio) | Go-live H6 se a faixa for praticada |
| 2 | Teto de auto-aprovação do asesor por marca/sociedade (coluna ausente) | Cliente via Melisa | Carga final da matriz (interim = 0) |
| 3 | Regra de quando uma venda é exonerada (quem marca, com que evidência) | Melisa/fiscal | Evolução do D2 (interim: asesor marca) |
