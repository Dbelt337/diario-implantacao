# Einstein Lead Scoring não habilita na QA — pesquisa de fóruns e documentação

Data: 17/08/2026. Org: QA, `00DWJ000008GgDB2A0`.

## O achado que muda o diagnóstico

**Falta de dado nunca impede habilitar.** A documentação oficial diz que quando não há
histórico de conversão suficiente, o Einstein usa o **modelo global**, anônimo, montado
com dados de muitos clientes, e depois troca para o modelo próprio quando a org acumula
dado suficiente.

Consequência direta: **criar leads não desbloqueia a habilitação**. Nem retroagir datas,
nem converter mais lead. O caminho de dado está encerrado como hipótese, e o script
`crear-leads-historicos-qa.apex` só serve para melhorar a qualidade do modelo depois que
ele treinar.

## Segundo achado: existem dois produtos com nome parecido

| Produto | Vem de | Funciona em sandbox |
|---|---|---|
| **Sales Cloud Einstein**, add-on pago | compra à parte, incluso em Unlimited e Performance | **Sim** |
| **Sales Cloud Einstein for Everyone** | incluído no Enterprise | **Não.** O permission set não aparece no sandbox nem depois de license match, e isso é comportamento esperado, não erro |

O KB 000393373 é explícito: se você tem o permission set do *for Everyone* em produção e
ele não aparece no sandbox depois do license match, é o esperado, o uso só é possível em
produção.

O log de 15/08 mostrou `SalesCloudEinsteinPsl` com 80 assentos e 2 em uso, que é o
**add-on**, o sabor que funciona em sandbox. Então este não deve ser o bloqueio, mas o
script confirma imprimindo `Status` e data de expiração de cada licença, que o
diagnóstico anterior não mostrou. Uma licença pode estar listada e ao mesmo tempo
expirada.

## Terceiro achado: 72 horas, não 24

A tela fala de 24 horas, e a documentação de features fala em **24 a 72 horas para a
criação do primeiro modelo**. Se a habilitação foi disparada em 15/08, em 17/08 ainda
estamos **dentro da janela normal**. Pode não haver defeito nenhum ainda.

## Quarto achado: o known issue

Existe known issue registrado, **"Einstein Lead Scoring is stuck. It has been more than
24 hours"**, referência interna **W-9138919**, marcado como corrigido no Winter '22. O
sintoma continua sendo reportado depois disso em threads da Trailblazer Community, com
"Modeling Failed" após as 24 horas, e em todas elas a saída é a mesma: **caso de
Support**. Não há workaround publicado. Isso é a resposta honesta sobre os fóruns: não
existe truque, existe caso.

## O que fazer, nesta ordem

1. **Setup, Company Information, Match Production Licenses.** Leva as licenças de
   produção para o sandbox sem refresh: atualiza contagens, acrescenta o que existe em
   produção e falta no sandbox, e remove o que não existe mais. Exige **Modify All Data**
   e que sandbox e produção estejam na **mesma release**. É grátis e é um minuto. Se as
   duas orgs estiverem em releases diferentes, o botão falha, e aí a resposta é esperar a
   janela de release;
2. Rodar **`docs/scripts/check-einstein-sabor-y-bloqueo.apex`**, que diz qual sabor a org
   tem, se a licença está ativa e não expirada, e se o permission set correto está
   atribuído;
3. Entrar de novo pelo **Setup, Sales Cloud Einstein, Setup Assistant**, e de lá em
   Einstein Lead Scoring. Não pela busca do Setup. Threads relatam que o caminho pela
   busca abre a tela sem disparar o job de provisionamento;
4. **Esperar 72 horas** contadas da última habilitação;
5. Passadas as 72 horas com `Lead.ScoreIntelligenceId` ainda inexistente, abrir o caso
   citando o known issue.

## Duas coisas para não errar depois

- **Não referenciar `ScoreIntelligence` em Apex antes de receber o aviso de que a
  habilitação terminou.** A documentação diz isso literalmente, referências ao campo
  ficam inválidas. Os nossos scripts só fazem describe, o que é seguro;
- **Insights em sandbox só atualizam quando o dado do sandbox é atualizado.** E a própria
  Salesforce recomenda **não avaliar a qualidade do modelo em sandbox**. Isso importa para
  a demo aos diretores: mesmo habilitando, o score da QA não é representativo, e o mais
  provável é ele vir do modelo global. Se a demo precisa de score crível, o lugar é
  produção.

## Texto do caso de Support

Em inglês, para colar no caso.

> **Subject:** Einstein Lead Scoring enablement never completes in sandbox
>
> Org Id: 00DWJ000008GgDB2A0 (sandbox, Enterprise Edition)
>
> Einstein Lead Scoring enablement does not complete. `Lead.ScoreIntelligenceId` still
> does not exist in the schema, verified by describe on 2026-08-17.
>
> Already verified on our side:
> - the three documented data thresholds are met: 1,448 leads created in the last 200
>   days, 608 of them converted to account and contact, 507 converted with an opportunity
>   created at conversion;
> - the Sales Cloud Einstein permission set license (`SalesCloudEinsteinPsl`) is
>   provisioned, 80 seats, and is assigned to the running user;
> - the associated permission set is assigned to the same user;
> - production licenses were matched to the sandbox;
> - more than 72 hours have elapsed since enablement was triggered.
>
> This matches known issue "Einstein Lead Scoring is stuck. It has been more than 24
> hours" (W-9138919), reported as fixed in Winter '22. Please check the backend
> provisioning status of Einstein Lead Scoring for this org.

Preencher o item de license match e o das 72 horas só depois de realmente terem sido
feitos. Caso com informação que não confere volta com pedido de esclarecimento e perde
dois dias.

## Fontes

- Considerations for Setting Up Einstein Lead Scoring, `ai.einstein_sales_els_setup_considerations.htm`
- Sales Cloud Einstein and Sandbox, `ai.einstein_sales_sandbox.htm`
- Sales Cloud Einstein for Everyone Permission Set Is Not Available in Sandbox, KB 000393373
- Licenses or features are missing in sandbox, KB 000386961
- Push Updated Licenses to Sandbox Orgs, `sf.overview_licenses_and_sandbox.htm`
- Known issue Einstein Lead Scoring is stuck, W-9138919
- Threads da Trailblazer Community sobre "Modeling Failed" e score ausente
