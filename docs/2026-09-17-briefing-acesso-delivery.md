# 17/09/2026 - Briefing: acessos do Delivery no Salesforce (planilha da Priscila)

Priscila De Lima (11:38-11:59) mandou a planilha **Acesso_Salesforce_Delivery_3.xlsx** (69 pessoas; colunas Nome, Cargo, Email)
e o link do Google Sheets equivalente. Regras que ela passou:

- **Perfil igual ao da Fernanda da Rosa** (Fernanda Ientzn da Rosa, Gerente de Pós Vendas, avato.com.br, linha 2 da planilha).
- **Como o do Romulo** (Romulo Gustavo Ramos da Silva, Especialista de Pós Vendas, linha 4): role e demais permissões.
- Diego perguntou se "essa galera" entra na role de Delivery; a resposta foi "igual ao perfil do Romulo". Ou seja, a role
  é a do Romulo, não uma role nova. Confirmar na org se as duas modelos estão na mesma role.

Diego lembra dessa planilha: é a versão 3, e as duas pessoas-modelo estão dentro dela. Provável que parte das 69 já tenha
usuário. Por isso a fase 1 é só leitura: **quem já existe, quem falta, e se há licença para os que faltam.**

## O que a planilha tem (normalizar_planilha.py, 17/09)

| Item | Valor |
|---|---|
| Pessoas | 69 (56 brasiltecpar.com.br, 13 avato.com.br) |
| Áreas pelo cargo | Pós-vendas 13; Aprovisionamento 15; Projetos 17; Configuração 7; Engenharia 4; Soluções e Contratações 3; outros 6; sem cargo 4 |
| Sem cargo | Daiana Freitas Peixoto, Gabrielli Barbosa Nunes, Joziane da Maia Vargas Silva, Leonardo Samuel Effel Drescher (todos com e-mail `.t@brasiltecpar`, temporário/terceiro?) |
| E-mails `.t@` | 10 (os 4 acima + Heberty, Luiza, Henrique Parreira, Kaue, Guilherme Pfeifer) |
| Duplicados / sem e-mail / e-mail inválido | nenhum |
| Sujeira | 14 linhas com espaço ou quebra de linha no nome/e-mail; 28 nomes em CAIXA ALTA (linhas 43 a 70). O CSV de saída já corrige. |

Sem CNPJ nem cliente: são colaboradores. Mesmo assim a planilha e a `saida/` ficam fora do git (.gitignore).

## Fase 1 (sessão conectada, somente leitura)

Rodar `python tools/acesso_usuarios/normalizar_planilha.py <planilha>` e depois cada `saida/consultas/NN.soql` com
`sf data query -o btp-prod --json --file`. As consultas respondem:

1. **Modelos**: perfil, licença do perfil, role, permission sets (só `IsOwnedByProfile = false`), permission set licenses,
   grupos/filas, licenças de pacote (vlocity_cmt etc.), feature licenses (Service Cloud, Knowledge, Marketing) da Fernanda
   e do Romulo. Se os dois divergem em perfil ou role, a Priscila precisa escolher: o pedido dela é "perfil da Fernanda" +
   "como o do Romulo".
2. **Licenças**: `UserLicense` (Total x Used), `PermissionSetLicense`, `PackageLicense`. A licença do perfil da Fernanda tem
   quantos assentos livres? O diário de 15/09 registrou 1 assento vlocity_cmt em uso: se o modelo tiver Vlocity, trava.
3. **Roles e perfis** existentes (há role "Delivery"? qual o pai da role do Romulo?). Contagem de usuários ativos por
   perfil x role, para ver onde os pós-vendas de hoje estão.
4. **Quem já existe**: cruzar os 69 por Email, por Username e por Name. Para cada um: existe/ativo/inativo, perfil, role,
   último login. Saída em três listas: A) já existe com perfil e role iguais aos modelos (nada a fazer); B) existe mas
   diverge (ajustar perfil/role/PS, ou reativar); C) não existe (criar).
5. **"Essa planilha é nova?"**: usuários criados nos últimos 90 dias com o perfil da Fernanda, quem criou e quando. Se a
   versão 1 ou 2 já foi executada, aparece aqui.

## Saída da fase 1

- `docs/2026-09-17-acessos-delivery-fase1.md`: configuração dos dois modelos lado a lado; licenças livres x necessárias;
  listas A/B/C com contagem; as 4 pessoas sem cargo e os 10 `.t@` marcados para a Priscila confirmar; perguntas abertas.
- `tools/acesso_usuarios/saida/C_criar.csv` e `B_ajustar.csv` (fora do git) com os campos do User já resolvidos:
  Username (= e-mail, conferir se está livre), Email, FirstName, LastName, Alias (até 8), Nickname, ProfileId, UserRoleId,
  TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, EmailEncodingKey copiados do modelo; Title = Cargo da planilha.
- Nenhum DML. A fase 2 (script 42, criação/ajuste em lote, `sf data import` ou Apex em duas fases) só depois do "vai" do
  Diego e da confirmação da Priscila sobre licenças, `.t@` e sem-cargo. Criar usuário dispara e-mail de boas-vindas: na
  fase 2, decidir se envia (`EmailHeader.triggerUserEmail`) ou se a Priscila avisa.

## Rascunho para a Priscila (depois da fase 1)

"Pri, rodei a planilha contra a org: X já têm acesso igual ao da Fernanda/Romulo, Y existem mas com perfil/role diferente,
Z não existem. Temos N licenças [tipo] livres para Z novos. Preciso que você confirme: (1) os 4 sem cargo e os 10 e-mails
`.t` entram mesmo? (2) Fernanda e Romulo estão em [perfil/role]; é isso para todos, inclusive Projetos/Engenharia? Com o
ok, crio em lote e te mando a lista com login."
