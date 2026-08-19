# W0382 | O papel B2B_Head_B2G nao deve ser criado

Fonte: `Hierarquia_Roles_BrasilTecpar.xlsx` (140 roles, 362 usuarios ativos,
snapshot de debug log sobre UserRole) + arvore de Papeis da sandbox Staging.

## O que a hierarquia real diz

```
C-Level  (CLevel, 1 usuario)
└── B2B Diretor Geral  (B2B_GeneralDirector, 0)
    └── B2B Arquiteto Backoffice  (B2B_BackofficeArchitect, 87)
        ├── B2B - Delivery  (B2B_Delivery, 60)
        │   └── B2B Head B2S  (B2B_Head_B2S, 0)
        ├── B2B Head B2B  (B2B_Head_B2B, 2)      <-- os B2G penduram AQUI
        │   ├── B2B Gerente Avato B2G  (1)
        │   │   ├── B2B Coordenador B2G - Terceiro  (0)
        │   │   │   └── B2B Vendedor B2G - Terceiro  (0)
        │   │   └── B2B Vendedor B2G  (10)
        │   └── B2B Gerente Avato CO / MG / PR / RS / SC / SP
        ├── B2B Head B2W    (B2B_Head_B2W, 2)
        ├── B2B Head Blink  (B2B_Head_Blink, 1)
        └── B2B Head SEMPRE (B2B_Head_SEMPRE, 1)
```

**Nao existe Head de B2G, e nao e um buraco na hierarquia.** Os Heads sao por
marca/canal -- B2B, B2W, Blink, SEMPRE, B2S. B2G nao e um canal com Head
proprio: e uma carteira dentro do canal B2B, sob `B2B_Gerente_Avato_B2G`, cujo
Head e o **B2B Head B2B**.

Ou seja: para uma Oportunidade `Type = B2G`, o Head responsavel **ja existe** e
e o `B2B_Head_B2B`. Os 10 vendedores B2G e o gerente Avato B2G reportam a ele.

## Por que o flow quebra

O `GetDirectorUser` procura um papel derivado do `Type` da Oportunidade. Com
`Type = B2B` ele acha `B2B_Head_B2B` e segue; com `Type = B2G` ele procura
`B2B_Head_B2G`, que nao existe, e nao acha ninguem.

O defeito nao e o papel faltando. E a premissa de que **canal de venda (Head)
e Type de Oportunidade (B2B/B2G) sao a mesma dimensao.** Nao sao:

| Dimensao        | Valores                                  |
|-----------------|------------------------------------------|
| Head (canal)    | B2B, B2W, Blink, SEMPRE, B2S             |
| Type (negocio)  | B2B, B2G                                 |

Elas coincidem em exatamente um ponto -- `B2B` -- e foi essa coincidencia que
sustentou a convencao de nome ate alguem abrir uma Oportunidade B2G.

## Por que criar B2B_Head_B2G seria pior que o bug

1. Inventa um cargo que a empresa nao tem. Nao ha quem atribuir: o Head dessa
   gente ja e o Head B2B.
2. Para "funcionar", o Head B2B teria de ser movido para o papel novo -- e um
   usuario tem um papel so. Ele sairia de `B2B_Head_B2B`, perdendo visibilidade
   dos 6 gerentes Avato e de toda a carteira B2B abaixo deles. Consertaria B2G
   quebrando B2B.
3. Ou entraria um segundo usuario duplicando a pessoa, e ai a hierarquia passa
   a mentir sobre quem responde por quem -- justamente o que ela existe para
   dizer.
4. Nao resolve o desempate: `B2B_Head_B2B` tem 2 usuarios ativos e o
   `GetDirectorUser` pega um qualquer, sem `LIMIT` e sem `IsActive`.

## O que resolve

O ajuste e no flow, nao na hierarquia. Em ordem de esforco:

**A. Mapear Type -> papel do Head.** `B2G` resolve para `B2B_Head_B2B`; `B2B`
continua como esta. Menor mudanca possivel, nenhum efeito em compartilhamento,
nenhum usuario movido. Nao resolve o desempate dos 2 usuarios.

**B. Resolver o Head subindo a hierarquia** a partir do owner da Oportunidade
ate encontrar um papel Head. Funciona para B2W, Blink, SEMPRE e B2S de graca,
e para qualquer canal novo. Nao depende de convencao de nome. Tambem nao
resolve o desempate.

**C. Filas (recomendado, e ja apontado no LEIAME original).** Criar as filas
`C-Level` e `Head B2B` e passar o Id da fila em `assigneeId` -- a acao padrao
aceita fila. Resolve B2G e desempate de uma vez: os 2 Heads recebem, qualquer
um assume. Nao toca na hierarquia de papeis. Exige Setup + decisao de negocio.

A recomendacao e **C**, com **A** como paliativo se houver pressa de destravar
producao antes da decisao sobre filas.

## O que fica exposto quando isso for arrumado

- `CLevel` tem **1** usuario ativo. O caminho C-Level so e deterministico por
  acidente: o segundo usuario C-Level quebra do mesmo jeito que B2G quebrou.
- `B2B_Head_B2S`, `B2C_Head` e `Head` tem **0** usuarios ativos. Qualquer
  caminho que caia neles falha igual.
- A tela `FailNoApproverScreen` que entrou nesta entrega e o que transforma
  todos esses casos de falha silenciosa em erro visivel. Ela continua sendo a
  parte mais valiosa do deploy, independente de qual opcao acima for escolhida.
