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

## Medição de 17/08, org `00DWJ000008GgDB2A0`, instância USA770S

Rodada limpa, sem erro. Os três umbrales seguem cumpridos e **os números não mudaram**:
1448 leads, 1448 criados nos últimos 200 dias, 608 convertidos, 507 com oportunidade,
taxa de 41,99 por cento.

Dois achados que a rodada trouxe e que não estavam registrados.

### 1. Não há história de conversão, há um pico

Agrupando os convertidos por mês de criação:

| Mês de criação | Convertidos |
|---|---|
| 2026-08 | 607 |
| 2026-07 | 1 |

**607 dos 608 convertidos foram criados neste mês.** E os 1448 leads da org, todos eles,
foram criados dentro dos 200 dias, nenhum é mais antigo.

Isso não bloqueia a habilitação, porque o fallback documentado é o modelo global. Mas
significa que, se o modelo algum dia sair, ele sai **do modelo global ou de um modelo
próprio sem valor**, porque conversão concentrada em 17 dias não é comportamento ao longo
do tempo, é um evento único. Para a demo aos diretores, o score não seria defensável se
alguém perguntar de onde vem.

### 2. Segmentar por linha de negócio quebraria tudo

Criados e convertidos nos 200 dias, por Record Type:

| Record Type | Criados | Convertidos | Passa o corte |
|---|---|---|---|
| `GQLeadsAutos` | 1331 | 603 | **sim** |
| `FinancialIndividual` | 79 | 0 | não |
| `GQLeadsRepuestosPA` | 21 | 4 | não |
| `GQLeadsMotos` | 12 | 1 | não |
| `FinancialLegalEntity` | 4 | 0 | não |
| sem Record Type | 1 | 0 | não |

Cada segmento precisa dos mesmos 1000 e 120, o segmento padrão All Leads incluído.
**Decisão: não criar segmento nenhum**, deixar em All Leads. Cinco dos seis não passam, e
segmentar aqui degrada o resultado em vez de melhorar.

### 3. Duas sujeiras de dado, baratas de corrigir

- **`Nuevo` com 821 leads e `New` com 7.** O mesmo estado em dois idiomas na mesma
  picklist. É exatamente o tipo de duplicidade que a regra de governança ataca, e a
  correção é Replace, não Del, senão sobram registros órfãos;
- **1 lead sem Record Type.**

Nenhuma das duas bloqueia Einstein. Ficam registradas porque aparecem em relatório e em
qualquer segmentação futura.

## São duas orgs diferentes, e isso muda tudo

A segunda rodada de 17/08 não foi na mesma org.

| | QA | UAT |
|---|---|---|
| Org Id | `00DWJ000008GgDB2A0` | `00DWK000005VF7x2AG` |
| Instância | USA770S | USA772S |
| Usuário | `diego.beltrao@grupoq.com.qa` | `diego.beltrao@grupoq.com.uat` |
| Leads, total | 1448 | **179** |
| Criados em 200 dias | 1448, cumpre | **179, faltam 821** |
| Convertidos | 608, cumpre | **0, faltam 120** |
| Com oportunidade | 507, cumpre | **0** |
| Taxa de conversão | 41,99 por cento | **0** |

**Em UAT os umbrales não são cumpridos, nem de longe.** Tudo o que foi dito até aqui
sobre "os três umbrales já cumprem" vale para QA e **não** vale para UAT. E o texto do
caso de Support redigido acima cita 1448, 608, 507 e a org `00DWJ`: **não serve para
UAT**, mandar assim volta como pedido de esclarecimento.

Isso não impede habilitar em UAT, porque o fallback documentado é o modelo global. Mas em
UAT o score sairia **inteiramente** do modelo global, sem uma única conversão própria.

E muda o valor do script de criação de leads: em QA ele era irrelevante, porque os
umbrales já cumpriam. **Em UAT ele passa a ter função**, não para desbloquear a
habilitação, e sim para a demo ter lead com score em cima de que falar. Se a demo aos
diretores for em UAT, é aí que ele se aplica, apontado para UAT e com conversão.

Antes de qualquer outro passo: **decidir em qual das duas orgs a demo acontece.** Estamos
gastando esforço em duas frentes.

### Três anomalias de dado em UAT

1. **Um lead com `Status = 'Convertido'` e `IsConverted = false`.** `IsConverted` é de
   leitura e quem escreve é a plataforma ao converter. O `Status` é picklist e qualquer
   pessoa, ou qualquer Flow, escreve. Um lead parado no estado de convertido sem ter sido
   convertido não tem conta, contato nem oportunidade, e mesmo assim sai do embudo em todo
   relatório que filtre por `Status`. É lead perdido em silêncio;
2. **22 dos 179 leads sem Record Type**, doze por cento. Em QA era 1 de 1448. Sem Record
   Type não há layout, nem regra por linha de negócio, nem segmento possível;
3. **A picklist de `Status` difere entre as duas orgs.** QA tem `New` ao lado de `Nuevo`,
   UAT tem `No contactado` e não tem `New`. Os Record Types também: UAT tem
   `GQLeadsFlotas` e não tem `FinancialLegalEntity`, QA o contrário. É deriva de
   configuração entre ambientes, e enquanto existir, relatório de um não se compara com o
   do outro.

Para as três, `docs/scripts/check-lead-status-huerfano.apex`, só leitura. Ele mostra qual
valor de `Status` a plataforma reconhece como conversão, lista os leads em estado de
conversão sem conversão real com quem os modificou por último, e mostra quem está criando
lead sem Record Type. Se concentrar num usuário de integração, o conserto é lá e não a
mão.

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
