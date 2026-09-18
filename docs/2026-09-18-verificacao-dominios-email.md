# 18/09/2026 - Verificacao de dominios de e-mail (Email on Core): status para o relatorio do Gerson

Contexto: Salesforce (Norman Carranza, 18/08) avisou que a lista de permissao temporaria das duas orgs (Signature = btp-prod e
Blink Telecom) cai em **26/10/2026**. Sem dominio verificado (DKIM ou Dominio de E-mail Autorizado, AED), os e-mails passam a
sair por endereco substituto @id.sfcustomeremail.com. Gerson (20/08) pediu ao time de Seguranca os registros DNS e aos admins
a validacao em Setup. Diego enviou os codigos AED em 27/08; Pedro (DNS) publicou o TXT de brasiltecpar.com.br em 28/08.
Gerson (11/09 e 18/09) pede relatorio com evidencias para o Bismarck devolver ao Ary e ao Vanicelli.

Levantamento de 18/09, 9h50: leitura na btp-prod (EmailDomainKey, OrgWideEmailAddress, User, EmailMessage) e consultas DNS
publicas feitas da maquina do Diego (Resolve-DnsName). Nada foi alterado.

## Resumo

| Dominio | Envia pela btp-prod? | AED (TXT 00DHu00000FcxIg=...) | DKIM (btp1/btp2) | Situacao |
|---|---|---|---|---|
| brasiltecpar.com.br | sim, 1.477 usuarios ativos | **publicado na raiz** em 28/08: `00DHu00000FcxIg=1TBV200000001li` | chave criada 21/08, inativa; CNAMEs nao publicados | provavelmente OK por AED; falta confirmar "Verified" em Setup e a grafia do codigo |
| sejaamigo.com.br | sim, 218 usuarios | nao publicado (nem raiz nem sfdv.) | chave criada 21/08, inativa; CNAMEs nao publicados | **pendente** |
| avato.com.br | sim, 121 usuarios; unicos envios registrados em 60 dias | nao publicado | chave criada 21/08, inativa; CNAMEs nao publicados | **pendente** |
| taak.com.br | 1 usuario | nao publicado | chave criada 21/08, inativa; CNAMEs nao publicados | pendente (baixo impacto) |
| blinktelecom.com.br (org Blink) | org nao autenticada nesta sessao | nenhum registro 00D... no DNS | nenhum seletor btp1/btp2 | **pendente; sem evidencia da org** |

Nenhum dos quatro SPF inclui `include:_spf.salesforce.com` (nao e exigido pela verificacao, mas ajuda a entregabilidade).

## 1. O que existe na org btp-prod (evidencia por API)

Chaves DKIM (objeto EmailDomainKey), todas criadas pelo Diego em 21/08/2026, 2048 bits, DomainOnly, plataforma
"Salesforce Messaging", publish state Published (a Salesforce ja publicou as chaves publicas do lado dela), **Status Inactive**:

| Dominio | Registro DNS esperado (CNAME) | Aponta para |
|---|---|---|
| brasiltecpar.com.br | btp1._domainkey.brasiltecpar.com.br | btp1.q7s0qc.custdkim.salesforce.com |
| brasiltecpar.com.br | btp2._domainkey.brasiltecpar.com.br | btp2.6pt0db.custdkim.salesforce.com |
| sejaamigo.com.br | btp1._domainkey.sejaamigo.com.br | btp1.roru7e.custdkim.salesforce.com |
| sejaamigo.com.br | btp2._domainkey.sejaamigo.com.br | btp2.j69lux.custdkim.salesforce.com |
| avato.com.br | btp1._domainkey.avato.com.br | btp1.0uj1gv.custdkim.salesforce.com |
| avato.com.br | btp2._domainkey.avato.com.br | btp2.g69ixe.custdkim.salesforce.com |
| taak.com.br | btp1._domainkey.taak.com.br | btp1.xtm63z.custdkim.salesforce.com |
| taak.com.br | btp2._domainkey.taak.com.br | btp2.egulcr.custdkim.salesforce.com |

Nenhum desses oito CNAMEs existe no DNS (consulta de 18/09). Por isso as chaves continuam inativas: a ativacao em Setup so
funciona depois que o CNAME do seletor responde. Sem CNAME, nao ha DKIM.

Enderecos de envio da organizacao (OrgWideEmailAddress): nenhum. Os envios saem com o e-mail do usuario. Dominios dos
usuarios ativos: brasiltecpar.com.br 1.477, gmail.com 287 (externos, nao verificaveis), sejaamigo.com.br 218, avato.com.br
121, hotmail 25, amigoperto.com.br 13, outlook 11, prestadortsp.com.br 10, taak.com.br 1. EmailMessage dos ultimos 60 dias:
2 envios, ambos de avato.com.br (a maioria dos e-mails da org sai por flow/alerta e nao gera EmailMessage).

Dominios de e-mail autorizados (AED): a lista e o codigo de verificacao de cada dominio ficam em Setup > "Dominios de e-mail
autorizados" e nao sao expostos pela API (o Id 1TBV200000001Ii do codigo pertence a um objeto oculto). A evidencia e o print
da tela, com a coluna Status.

## 2. O que existe no DNS (consulta publica, 18/09)

- **brasiltecpar.com.br**: TXT na raiz `00DHu00000FcxIg=1TBV200000001li` (publicado por Pedro em 28/08). ATENCAO: o DNS devolve
  os dois ultimos caracteres como `l` minusculo (ASCII 108) e `i` (105). O e-mail do Diego de 27/08 escreveu `...001Ii`, com `I`
  maiusculo. Ids do Salesforce diferenciam maiusculas: se o codigo em Setup for `Ii`, o registro publicado esta errado por um
  caractere e a verificacao nao fecha. Conferir na tela e, se preciso, pedir ao Pedro a correcao. Sem sfdv.; sem CNAMEs DKIM.
  SPF: mx + ips + google + sendgrid + zendesk (~all). DMARC p=none. MX Google.
- **sejaamigo.com.br**: sem TXT 00D..., sem sfdv., sem CNAMEs btp1/btp2. Ha um TXT DKIM solto na raiz (v=DKIM1, k=rsa) que nao
  e do Salesforce. SPF com avatohosting, sendgrid, zendesk, google. DMARC p=none.
- **avato.com.br**: sem TXT 00D..., sem sfdv., sem CNAMEs. SPF com google, sendgrid, zendesk. DMARC p=none.
- **taak.com.br**: sem TXT 00D..., sem sfdv., sem CNAMEs.
- **blinktelecom.com.br**: sem TXT 00D... (de nenhuma org), sem CNAMEs btp1/btp2. SPF google + amazonses. DMARC p=quarantine.

## 3. Conclusao para o relatorio

- **Feito**: chaves DKIM criadas para 4 dominios na btp-prod (21/08); codigos AED levantados e enviados ao DNS (27/08); TXT AED
  de brasiltecpar.com.br publicado (28/08).
- **Nao esta completo**: (a) brasiltecpar.com.br so fica "verificado" quando Setup mostrar Verified, e ha risco de um caractere
  errado no TXT; (b) sejaamigo.com.br, avato.com.br e taak.com.br nao tem TXT AED nem CNAME DKIM, logo NAO estao verificados;
  (c) os 8 CNAMEs DKIM de nenhum dominio foram publicados, entao nenhuma chave DKIM esta ativa; (d) a org Blink Telecom nao foi
  conferida (sem acesso nesta sessao) e o DNS de blinktelecom.com.br nao tem nenhum registro de verificacao.
- **Risco em 26/10**: e-mails de usuarios @sejaamigo, @avato e @taak (e tudo da Blink) saem por endereco substituto. Os
  @brasiltecpar dependem da confirmacao do item (a).

## 4. O que falta fazer (ate 26/10)

| # | Acao | Quem |
|---|---|---|
| 1 | Setup > Dominios de e-mail autorizados: print com Status de cada dominio; conferir o codigo de brasiltecpar.com.br caractere a caractere (Ii x li) | Diego (admin) |
| 2 | Publicar os TXT AED de sejaamigo.com.br, avato.com.br e taak.com.br (codigo de cada um esta na tela do item 1; na raiz ou em sfdv.<dominio>) | Pedro (DNS) |
| 3 | Publicar os 8 CNAMEs DKIM da tabela da secao 1 (ou decidir que AED basta e apagar as chaves inativas; a Salesforce recomenda DKIM) | Pedro (DNS) |
| 4 | Depois da propagacao, ativar as chaves DKIM em Setup > Chaves DKIM (botao Ativar) e marcar os dominios AED como verificados | Diego |
| 5 | Repetir 1 a 4 na org Blink Telecom (blinktelecom.com.br): quem e o admin? Diego nao tem acesso hoje | Gerson / admin da Blink |
| 6 | Opcional: incluir `include:_spf.salesforce.com` no SPF dos dominios que enviam pelo Salesforce | Pedro |

Comandos de conferencia (qualquer maquina): `nslookup -type=TXT brasiltecpar.com.br`, `nslookup -type=CNAME btp1._domainkey.brasiltecpar.com.br`.

## Rascunho de e-mail para Gerson e Bismarck

Assunto: Verificacao de dominios de e-mail no Salesforce - status em 18/09

> Gerson, Bismarck,
>
> Segue o status da verificacao de dominios (prazo Salesforce: 26/10).
>
> Feito ate agora: (1) chaves DKIM criadas na org de producao para brasiltecpar.com.br, sejaamigo.com.br, avato.com.br e
> taak.com.br em 21/08; (2) codigos de Dominio de E-mail Autorizado enviados ao time de DNS em 27/08; (3) TXT de
> brasiltecpar.com.br publicado pelo Pedro em 28/08 (confirmado no DNS hoje).
>
> O que ainda falta para ficar conforme a orientacao da Salesforce:
> - sejaamigo.com.br, avato.com.br e taak.com.br ainda nao tem o TXT de verificacao no DNS: hoje NAO estao verificados.
>   Os codigos estao na tela de Dominios de E-mail Autorizados; mando ao Pedro junto com este e-mail.
> - Os CNAMEs DKIM (btp1 e btp2 de cada dominio, 8 registros, lista em anexo) nao foram publicados, entao as chaves DKIM
>   seguem inativas. Recomendo publicar; e o metodo que a Salesforce indica como preferencial.
> - Em brasiltecpar.com.br preciso confirmar na tela que o status ficou "Verificado" e conferir um caractere do codigo
>   publicado (o DNS mostra "...001li"; se o correto for "...001Ii", o Pedro corrige em minutos).
> - A org Blink Telecom nao esta no meu acesso; o DNS de blinktelecom.com.br nao tem nenhum registro de verificacao. Precisa
>   de um admin daquela org fazendo o mesmo passo a passo.
>
> Evidencias: consulta das chaves DKIM na org (tabela com os CNAMEs esperados), consultas DNS publicas de hoje e o print da
> tela de Dominios Autorizados (anexo assim que confirmar o status). Impacto se nada mudar ate 26/10: e-mails de @sejaamigo,
> @avato, @taak e da Blink saem por endereco substituto da Salesforce.
>
> Diego

## Atualizacao 18/09, 10h30: tela de Setup e Tooling API

Print do Diego (Setup > Dominios de email autorizados): os 4 dominios com **"Propriedade verificada: Nao"**, "Exigir verificacao
de email: Sim". Codigos: avato `00DHu00000FcxIg=1TBV200000001lh`, brasiltecpar `...=1TBV200000001li`, sejaamigo `...=1TBV200000001lj`,
taak `...=1TBV2000000037Z`. O codigo de brasiltecpar e `li` minusculo, igual ao que esta no DNS: **o registro do Pedro esta
correto**; a duvida do caractere caiu.

Tooling API (objeto AuthorizedEmailDomain), leitura: IsDomainOwnershipVerified = false nos 4; LastModifiedDate 05/06/2026 nos 4.
Nada mudou nos registros desde junho: **a checagem de verificacao nunca foi disparada depois da publicacao do TXT (28/08)**.
A verificacao nao e automatica: e feita em Setup > "Verificar dominios de envio de e-mail" (Check Your Email-Sending Domains),
informando o dominio e clicando em verificar; e o passo 2 do proprio e-mail do Gerson de 20/08 ("Validar os dominios").

DNS (Pedro, 27/08): avato.com.br e sejaamigo.com.br sao tratados pelo time CSTI, nao pela Seguranca; taak e demais clusters
com os pontos de contato locais. O Diego reenviou ao Pedro em 18/09 os 3 TXT que faltam e os 8 CNAMEs DKIM.

Proximo passo imediato (Diego, 5 minutos): Setup > Verificar dominios de envio de e-mail > brasiltecpar.com.br > verificar. Se
voltar "Dominio verificado", print para o relatorio e a coluna da tela de Dominios autorizados passa a "Sim". Se falhar, o
DNS esta certo (conferido hoje), entao abrir caso na Salesforce com o print e o nslookup.
