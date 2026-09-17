# 17/09/2026 - Catalog Control Plane (ccp.evo.digital): origem do template de carga do catálogo

O presidente da empresa construiu um painel chamado **Catalog Control Plane** ("estado atual do catálogo canônico em
design-time"). Segundo o Diego, a ferramenta **gera o template para carregar os produtos no Salesforce via Claude**. Isso
fecha o fluxo do deck v3 (docs/deck-catalogo/Catalogo_Carga_e_Manutencao_v3_Template_Claude_CLI.pptx):

Control Plane (desenho e aprovação) -> Exportação (template) -> Claude via CLI lê, confere e carrega na sandbox
(DataPacks / Vlocity Build) -> comercial homologa -> publicação em produção (IDX).

Print de 17/09: 72 entidades canônicas, 2 ofertas comerciais, 27 componentes reutilizáveis, 2 demandas; ciclo de vida
Rascunho 21 / Aprovado 38 / Publicado 13. Tipos de entidade: Atributo, Valor de picklist, Produto, Picklist, Recurso, RFS,
Especificação, Oferta, Catálogo, Mercado, Canal, Zona, Classe de produto, CFS, Lista de preço, Regra, Portfólio (vocabulário
Vlocity EPC + TM Forum). Menu: Painel, Minhas pendências, Copiloto de demanda, Portfolio Explorer, Espaço de desenho, Reuse
Center, Validação, Pricing Studio, Prévia de preço, Promoções, Disponibilidade, Atributos e segmentos, Dimensões de contexto,
Materiais SAP, Assets e MACD, Decomposição técnica, Conteúdo comercial, Implantação, Mapa de implantação, Reconciliação e
UAT, Indicadores, Exportação.

## O que muda no projeto

| Antes (16/09) | Agora |
|---|---|
| W-000102 CAT-TPL-01: SysMap desenha o template de carga | O template é a **Exportação** do Control Plane. A work vira: definir o formato de export (DataPack JSON x planilha) e o mapeamento entidade -> objeto EPC. |
| Modelagem EPC (W-000051 a 055) feita direto na org pela SysMap | A modelagem canônica vive no Control Plane; a org recebe carga. SysMap precisa modelar lá ou receber o export dele. **Decidir com Davi e Gerson.** |
| Claude "lê o template e executa via CLI" | Igual, mas o validador (tools/) passa a validar o export da ferramenta: consulta a org antes, nunca duplica, carrega pelo Id/GlobalKey. |
| Agente custom (Davi) | Provável "Copiloto de demanda" do painel + Claude Code no CLI. |

## Mapeamento menu -> works (para não duplicar escopo)

Espaço de desenho / Atributos e segmentos / Dimensões de contexto -> 051 a 055 (EPC); Exportação / Implantação / Mapa de
implantação -> 102 (CAT-TPL-01); Pricing Studio / Prévia de preço -> 108, 121; Promoções -> 128; Disponibilidade / Zona ->
114; Decomposição técnica (CFS/RFS) -> 137; Materiais SAP -> TEC-INT; Assets e MACD -> 109 e pós-venda; Validação /
Reconciliação e UAT -> homologação comercial do deck v3.

## Pendências

1. Acesso à ferramenta e uma **exportação de exemplo** (1 oferta completa) para o Claude montar o validador e o mapeamento
   para os objetos EPC (Product2, AttributeCategory/AttributeAssignment, Picklist, PriceList/PricingElement, Promotion,
   ObjectClass, Catalog, ContextDimension, Zone).
2. Definir a fonte da verdade do catálogo (Control Plane) e comunicar à SysMap antes que EPC-01 a 09 avancem na Sprint 1.
3. Chave de idempotência da carga: GlobalKey do Vlocity ou código canônico da ferramenta. Sem isso não dá para "consultar
   primeiro, atualizar pelo Id".
4. Sandbox alvo da primeira carga e quem homologa (comercial).
