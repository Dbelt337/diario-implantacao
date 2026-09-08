# W-000089 — US TEC-B2C-06 — Infraestrutura de Geração de Documentos (Minuta de Contrato)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 08/09/2026 16:10 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-06: Infraestrutura de Geração de Documentos (Minuta de Contrato)
Narrativa: Como time de implantação, quero o motor de Document Generation configurado com template jurídico e mapeamento de dados, para a US-NEW-02 gerar a minuta sem edição manual.
Escopo técnico:
- OmniStudio Document Generation com template Word/PDF aprovado pelo jurídico.
- DataRaptor Extract consolidando Quote, linhas, dados do cliente e parâmetros de faturamento.
- Saída em PDF bloqueado anexado à cotação (ContentDocumentLink) com preview.
Critérios de aceite: minuta gerada a partir de cotação de teste com todas as variáveis mescladas; documento não editável pelo vendedor.
Dependências: template aprovado pelo jurídico; B2C-17 (dados de faturamento disponíveis).

## Critérios de Aceite (related list)

**1. Critério 2** (New)
documento não editável pelo vendedor.

**2. Critério 1** (New)
minuta gerada a partir de cotação de teste com todas as variáveis mescladas.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO COM B2B ---
Esta fundação de Document Generation atende também a proposta comercial B2B (B2B-03): template de proposta multi-site gerado da Quote aprovada, com aceite formal congelando a cotação. Prever os dois conjuntos de templates (minuta B2C e proposta B2B) na mesma infraestrutura.

--- DECISAO 04/09 - GERACAO ASSINCRONA, DISPARO POR EVENTO ---
A infraestrutura de Document Generation permanece no Salesforce, porem a execucao passa a ser disparada pelo Platform Event QuoteContractRequested__e (assinado via MuleSoft) e roda assincrona, fora da transacao de tela. Gatilho na COTACAO. Callback QuoteContractReady__e anexa o PDF bloqueado a Quote (ContentDocumentLink) e atualiza o status. Requisito de performance: o clique do vendedor nunca aguarda a compilacao do documento. Ver work US TEC-INT-01 para o contrato do canal.

--- SAIDA DO DOCGEN E VERSAO ASSINADA (08/09) ---
O DocGen produz a minuta como ContentVersion vinculada à Quote (tipo "Minuta", template e versão gravados, ver B2C-33). O PDF assinado que retorna da plataforma NÃO sobrescreve a minuta: é gravado como documento separado (tipo "Contrato assinado"), vinculado à Quote, ao Contract e à Account. Os dois ficam no Salesforce Files; capacidade confirmada na org (1.034.000 gerações/mês; storage de Files 10 GB + 2 GB por licença, um contrato tem cerca de 300 KB).
