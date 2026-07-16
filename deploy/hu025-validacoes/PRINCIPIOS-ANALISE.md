# Princípios de análise das HUs (rubrica padrão)

Toda análise de história de usuário deve seguir estes princípios. Cada resposta
técnica é avaliada por eles.

1. **Cobertura fundamentada.** Cobrir tecnicamente o requisito com base nas
   **melhores práticas e documentos oficiais do Automotive Cloud**. Se um
   documento não abrir (403), registrar o **link** e pedir o conteúdo.
2. **Native-first + Object Reference.** Recomendar sempre o recurso **nativo** e
   modelar conforme a **modalidade apropriada** da **Object Reference** da
   Salesforce / Automotive Cloud (PDF no projeto). Só cair para custom
   (campo/flow/integração) quando não houver nativo que cubra.
3. **OmniStudio Standard Runtime.** Toda recomendação de OmniStudio
   (OmniScript / FlexCards / Integration Procedures / Data Mapper) assume o
   **Standard Runtime (on-core)** — nada do managed package.
4. **Não assumir escopo não previsto (ATENÇÃO).** Quando um cenário não tem ID
   no Tech Annex / Fit & Gap, **não** presumir que está coberto. Marcar
   explicitamente: **Nativo**, **GAP** (desenvolvimento) ou **dependência**
   (integração/contrato/licença). Escopo novo = sinalizar, nunca embutir.
5. **Direcionar o cliente ao nativo.** Guiar o cliente para o que o Salesforce /
   Automotive Cloud já oferece, e só então para desenvolvimento.

## Veredito padrão (usar em toda resposta)
- ✅ **Nativo** — coberto por recurso padrão (citar o objeto/feature + doc).
- ⚠️ **Parcial** — nativo com ressalva (licença, config ou limite de plataforma).
- ❌ **GAP** — exige desenvolvimento/custom.
- 🔌 **Dependência** — depende de integração (MuleSoft/SAP), contrato ou licença.
