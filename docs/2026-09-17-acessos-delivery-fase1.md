# 17/09/2026 - Acessos do Delivery no Salesforce: fase 1 (leitura), planilha da Priscila

Pedido da Priscila De Lima (17/09, 11h38): planilha Acesso_Salesforce_Delivery_3.xlsx com 69 pessoas (Nome, Cargo, Email).
Regra: perfil igual ao da Fernanda Ientzn da Rosa; role e demais permissoes como o Romulo Gustavo Ramos da Silva.
Fase 1 SOMENTE LEITURA na btp-prod (13h, 17/09): normalizar_planilha.py, 14 consultas geradas + 17 manuais
(tools/acesso_usuarios/saida/consultas e consultas_manual), cruzamento por tools/acesso_usuarios/cruzar.py. Planilha, JSONs e
CSVs de saida ficam fora do git. Nenhum User criado ou alterado.

## Resumo

- **Fernanda e Romulo DIVERGEM.** Mesma role (B2B - Delivery) e mesma licenca (Salesforce), mas perfis diferentes: Fernanda
  e **B2B - Backoffice** (cria/edita/exclui Conta, Contato, Lead, Oportunidade, Cotacao, Pedido, Contrato, Ativo), Romulo e
  **Read Only** (so leitura em tudo) com o permission set **App BTP B2B - Visibilidade**. Nenhum dos dois tem permission set
  license, grupo, fila ou licenca de pacote (Vlocity nao entra).
- **62 dos 69 ja existem na org, todos ativos**; 7 nao existem. Nenhum esta "igual aos modelos" (lista A = 0), porque a
  combinacao pedida (perfil da Fernanda + PS do Romulo) nao existe em ninguem hoje, nem neles. 57 dos 62 estao exatamente
  como o Romulo (Read Only + B2B - Delivery), so sem o permission set.
- **A planilha ja foi executada antes**: os 62 foram criados pela "Seguranca Informacao" em 3 lotes (19/12/2025: 1;
  28/04/2026: 23; 01/06/2026: 38), como Read Only + B2B - Delivery. 42 dos 62 nunca fizeram login.
- **Licenca nao e problema**: Salesforce 2.158 usadas de 3.968 (1.810 livres); os 7 novos cabem. Sem PSL nem pacote envolvido.
- **A decisao que falta e da Priscila**: aplicar "perfil da Fernanda" significa trocar 58 pessoas de Read Only para
  B2B - Backoffice (de leitura para edicao dos objetos B2B). Se a intencao era "como o Romulo", quase todos ja estao
  prontos e falta so o permission set e os 7 novos.

## A. Fernanda x Romulo

| Item | Fernanda Ientzn da Rosa | Romulo Gustavo Ramos da Silva | Bate? |
|---|---|---|---|
| Perfil | B2B - Backoffice (00eV200000Bj8MTIAZ) | Read Only (00eHu000003dU4HIAU) | NAO |
| Licenca do perfil | Salesforce | Salesforce | sim |
| Role | B2B - Delivery (00EV2000001cwdiMAA), pai B2B Arquiteto Backoffice, avo B2B Diretor Geral | idem | sim |
| Permission sets (IsOwnedByProfile = false) | nenhum | App BTP B2B - Visibilidade (App_BTP_B2B_Visibilidade) | NAO |
| Permission set licenses | nenhuma | nenhuma | sim |
| Grupos / filas | nenhum | nenhum | sim |
| Licencas de pacote (UserPackageLicense) | nenhuma (sem vlocity_cmt) | nenhuma | sim |
| Feature licenses | Support, Marketing, Content = false; Interaction (Flow) = true | idem | sim |
| Fuso/Locale/Idioma/Encoding | America/Sao_Paulo, pt_BR, pt_BR, ISO-8859-1 | idem | sim |
| Criacao | 01/06/2026, Seguranca Informacao | 01/06/2026, Seguranca Informacao | |
| Ultimo login | 14/08/2026 | 16/09/2026 | |

Diferenca pratica entre os perfis (ObjectPermissions do perfil):

| Objeto | B2B - Backoffice | Read Only |
|---|---|---|
| Account, Contact, Lead, Opportunity, Quote, Order, Contract, Asset | ler, criar, editar, excluir | so ler |
| Case, WorkOrder, ServiceAppointment | ler, criar, editar | so ler |
| Permissoes de sistema | + EditTask, EditEvent, ConvertLeads | RunReports, ExportReport, API, ViewSetup (iguais nos dois) |

Onde os pos-vendas estao hoje (usuarios ativos): Read Only + B2B - Delivery = 59; B2B - Backoffice + B2B Arquiteto
Backoffice = 46 (backoffice de arquitetura); B2B - Backoffice + B2B - Delivery = 1 (so a Fernanda). Ou seja, o time de
Delivery foi montado como Read Only, e a Fernanda (gerente) e a excecao. Nao existe role "Delivery" alem da B2B - Delivery.

## B. Licencas

| Licenca | Usadas / total | Livres | Necessaria? |
|---|---|---|---|
| UserLicense Salesforce (perfil da Fernanda e do Romulo) | 2.158 / 3.968 | 1.810 | 7 novos: sim, cabe |
| PermissionSetLicense | nenhuma atribuida aos modelos | - | nao |
| PackageLicense vlocity_cmt | 1 / 1 | 0 | nao (modelos nao tem) |
| PackageLicense agf, FSL, et4ae5 etc. | ilimitadas (-1) | - | nao |

Trocar perfil de Read Only para B2B - Backoffice nao muda licenca (as duas sao Salesforce).

## C. Cruzamento dos 69 (por Email, Username e Name)

| Lista | Qtde | Significado |
|---|---|---|
| A - existe igual aos modelos (perfil Backoffice + role Delivery + PS Visibilidade) | 0 | ninguem, nem a Fernanda (sem PS) nem o Romulo (Read Only) |
| B - existe mas diverge | 62 | 57 Read Only + Delivery sem PS; 1 Read Only + Delivery com PS (Romulo); 3 B2B - Especialistas + B2B Arquiteto Backoffice (Ciro Librino, Telmo Baggio, Oscar Oesterreich); 1 Backoffice + Delivery sem PS (Fernanda) |
| C - nao existe | 7 | Leticia Santos (avato, Analista de Pos Vendas) e 6 Analistas de Projetos: Heberty Silva, Luiza Souza, Jessica Carrico, Henrique Parreira, Kaue Munhoz, Guilherme Pfeifer (5 deles com e-mail .t@) |

Todos os 62 casaram por e-mail (= username); a busca por nome nao trouxe ninguem a mais, entao nao ha usuario existente com
e-mail diferente da planilha. Todos ativos. Nenhum tem Title preenchido na org (a planilha traz o cargo). Tabela completa,
sem e-mail (esta em saida/cruzamento.csv):

| Linha | Nome | Cargo | Lista | Perfil / role hoje | Divergencia |
|---|---|---|---|---|---|
| 2 | Fernanda Ientzn da Rosa | Gerente de Pos Vendas | B | B2B - Backoffice / B2B - Delivery | sem PS Visibilidade |
| 3 | Mirian Simone de Souza Romero | Coordenadora Pos vendas | B | Read Only / B2B - Delivery | perfil; sem PS |
| 4 | Romulo Gustavo Ramos da Silva | Especialista de Pos Vendas | B | Read Only / B2B - Delivery | perfil |
| 5 | Fernanda Vitt Prelelue | Analista de Pos Vendas | B | Read Only / B2B - Delivery | perfil; sem PS |
| 6 | Leticia Galhard | Analista de Pos Vendas | B | Read Only / B2B - Delivery | perfil; sem PS |
| 7 | Andressa Righi | Analista de Pos Vendas | B | Read Only / B2B - Delivery | perfil; sem PS |
| 8 | Eduardo Silveira | Coordenador de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 9 | Leticia Santos | Analista de Pos Vendas | C | - | nao existe |
| 10 | Vanessa Garcia | Analista de Pos Vendas | B | Read Only / B2B - Delivery | perfil; sem PS |
| 11 | Rafael Fernando Orth | Especialista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 12 | Ana Paula Schwengber Bohn | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 13 | Edevaldo de Andrade Rosa | Especialista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 14 | Rhany Tamires Leite de Aspiazu | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 15 | Andressa Aparecida da Silva | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 16 | Erica Xavier Brandao | Assistente de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 17 | Paula Rissiani dos Santos Rizzi | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 18 | Stefani de Souza Martelli | Assistente de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 19 | Daiana Freitas Peixoto | (sem cargo, .t@) | B | Read Only / B2B - Delivery | perfil; sem PS |
| 20 | Gabrielli Barbosa Nunes | (sem cargo, .t@) | B | Read Only / B2B - Delivery | perfil; sem PS |
| 21 | Joziane da Maia Vargas Silva | (sem cargo, .t@) | B | Read Only / B2B - Delivery | perfil; sem PS |
| 22 | Leonardo Samuel Effel Drescher | (sem cargo, .t@) | B | Read Only / B2B - Delivery | perfil; sem PS |
| 23 | Leonardo de Souza de Abreu | Coordenador de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 24 | Henry Shinkai | Especialista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 25 | Felipe Dalla Porta | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 26 | Joel Farias | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 27 | Pedro Ariel Goncalves | Assistente de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 28 | Henrique Obata | Analista de Aprovisionamento | B | Read Only / B2B - Delivery | perfil; sem PS |
| 29 | Laion Porto | Gerente de Solucoes e Contratacoes | B | Read Only / B2B - Delivery | perfil; sem PS |
| 30 | Ciro Librino | Coordenadora Solucoes e Contratacoes de Redes | B | B2B - Especialistas / B2B Arquiteto Backoffice | perfil; role; sem PS |
| 31 | Irondina Vargas | Analista de Solucoes | B | Read Only / B2B - Delivery | perfil; sem PS |
| 32 | Bruna Maria Duarte Farias | Coordenadora Financeira | B | Read Only / B2B - Delivery | perfil; sem PS |
| 33 | Simone de Miranda | Jovem Aprendiz | B | Read Only / B2B - Delivery | perfil; sem PS |
| 34 | Leonardo Costa Fernandes | Gerente de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 35 | Henrique Felix Cavalcante | Coodendador de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 36 | Luiz Henrique Castrezana de Souza | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 37 | Jeferson Igor Dias de Souza | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 38 | Marcelo Stringini Rubin | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 39 | Rafael Neves Almeida | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 40 | Joseline Radunz | Coodendadora de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 41 | Karen Bueno | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 42 | Telmo Juliano Baggio | Gerente | B | B2B - Especialistas / B2B Arquiteto Backoffice | perfil; role; sem PS |
| 43 | Cristiane Alves Bastos | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 44 | Fausto Cristiano | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 45 | Mauricio Favero | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 46 | Mauricio Ortigara Zardinello | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 47 | Nasare Jesus de Oliveira Junior | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 48 | Jaciara Ferreira Marques Cardoso | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 49 | Ricardo Menezes da Silva | Analista de Configuracao | B | Read Only / B2B - Delivery | perfil; sem PS |
| 50 | Raquel da Gama Escouto | Analista de Engenharia | B | Read Only / B2B - Delivery | perfil; sem PS |
| 51 | Jhonanthan Ravel da Silva | Analista de Engenharia | B | Read Only / B2B - Delivery | perfil; sem PS |
| 52 | Andre Lucas Lanhi | Analista de Engenharia | B | Read Only / B2B - Delivery | perfil; sem PS |
| 53 | Marcondes Pires | Analista de Engenharia | B | Read Only / B2B - Delivery | perfil; sem PS |
| 54 | Leonardo Santos Faleiro | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 55 | Samael da Silva Oliveira | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 56 | Bianca Barao | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 57 | Felipe Alberton Hermes de Mello | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 58 | Luiz Yukio Minami | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 59 | Maria Fernanda Alves Guimaraes | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 60 | Tamara Goncalves Guilherme | Analista de Projetos | B | Read Only / B2B - Delivery | perfil; sem PS |
| 61 | Vinicius Soares Ramos da Silva | Especialista | B | Read Only / B2B - Delivery | perfil; sem PS |
| 62 | Everton Luiz Goulart Ferreira | Especialista | B | Read Only / B2B - Delivery | perfil; sem PS |
| 63 | Heberty Jose Soares da Silva | Analista de Projetos (.t@) | C | - | nao existe |
| 64 | Luiza Teixeira de Souza | Analista de Projetos (.t@) | C | - | nao existe |
| 65 | Jessica Gomer Carrico | Analista de Projetos | C | - | nao existe |
| 66 | Henrique Parreira | Analista de Projetos (.t@) | C | - | nao existe |
| 67 | Kaue Munhoz | Analista de Projetos (.t@) | C | - | nao existe |
| 68 | Guilherme Muller Pfeifer | Analista de Projetos (.t@) | C | - | nao existe |
| 69 | Oscar Oesterreich | Especialista de Pos Vendas | B | B2B - Especialistas / B2B Arquiteto Backoffice | perfil; role; sem PS |
| 70 | Luciana Kremer | Especialista de Pos Vendas | B | Read Only / B2B - Delivery | perfil; sem PS |

Atencao com os 3 de B2B - Especialistas (Ciro Librino, Telmo Baggio, Oscar Oesterreich): sao membros da fila Arquitetura
(role B2B Arquiteto Backoffice, mesma dos 43 arquitetos). Trocar para Backoffice + Delivery tira os tres da arquitetura.
Provavel erro de lista, ou eles precisam de acesso extra e nao de troca. Confirmar com a Priscila.

## D. "Essa planilha e nova?" - usuarios criados nos ultimos 90 dias e lotes anteriores

Criados nos ultimos 90 dias com o perfil da Fernanda (B2B - Backoffice): 4, nenhum da planilha, todos por Alex Patrik da
Silva (Jaine da Maia Alves 01/07, Melline Pituco 09/07, Patricia Mello 20/07, Fernanda da Silveira Duarte 31/07). Ou seja,
ninguem da planilha foi criado como Backoffice.

Mas os 62 existentes foram criados como Read Only + B2B - Delivery pela "Seguranca Informacao" em tres lotes: 1 em 19/12/2025,
23 em 28/04/2026 e 38 em 01/06/2026 (a Fernanda e o Romulo estao no de 01/06). As versoes 1 e 2 desta planilha ja foram
executadas, como Read Only. Uso: 42 dos 62 nunca fizeram login; 6 logaram em setembro; 14 antes de setembro.

## E. Pendencias para a Priscila

1. **Perfil: Backoffice ou Read Only?** O pedido literal (perfil da Fernanda) passa 58 pessoas de leitura para edicao de
   Conta, Oportunidade, Cotacao, Pedido, Contrato, Ativo, Caso e Ordem de trabalho. O time inteiro foi criado como Read
   Only em abril/junho. Se a intencao e "como o Romulo", o que falta e so o permission set App BTP B2B - Visibilidade em
   61 pessoas e criar 7.
2. **Os 3 arquitetos** (Ciro Librino, Telmo Baggio, Oscar Oesterreich): trocar de verdade ou tirar da lista?
3. **4 sem cargo** (Daiana Peixoto, Gabrielli Nunes, Joziane Silva, Leonardo Drescher): ja existem como Read Only + Delivery
   desde 01/06, nunca logaram. Cargo para o Title e confirmar se continuam.
4. **10 e-mails .t@** (temporario/terceiro): os 4 acima ja existem; os outros 6 (Heberty, Luiza, Henrique Parreira, Kaue,
   Guilherme Pfeifer... e Jessica Carrico sem .t) sao os 7 a criar. Confirmar que entram e ate quando.
5. **Nenhum** usuario existente com e-mail diferente da planilha.
6. 42 dos 62 nunca logaram: vale a Priscila avisar o time (novo login gera e-mail de redefinicao de senha).

## F. Saidas geradas (fora do git, tools/acesso_usuarios/saida/)

- cruzamento.csv: os 69 com Lista, UserId, perfil, role, PS e divergencia.
- C_criar.csv: 7 linhas com Username (= e-mail, todos livres), FirstName, LastName, Alias (8), CommunityNickname, Title =
  cargo, ProfileId 00eV200000Bj8MTIAZ, UserRoleId 00EV2000001cwdiMAA, fuso/locale/idioma/encoding do modelo, PS a atribuir.
- B_ajustar.csv: 62 linhas com UserId, perfil e role atuais, PS, divergencia, e os Ids-alvo. Se a Priscila escolher
  "como o Romulo", o alvo muda para o perfil Read Only (00eHu000003dU4HIAU) e sobra so o PS.

## Fase 2 (so com o "vai" do Diego e a resposta da Priscila)

Script 46, duas fases: (a) inserir os 7 Users do C_criar.csv (decidir EmailHeader.triggerUserEmail: e-mail de boas-vindas ou
a Priscila avisa); (b) atribuir o PS App BTP B2B - Visibilidade aos 61 + 7; (c) se confirmado, trocar o perfil dos 58 Read
Only (e dos 3 especialistas, se mantidos) para B2B - Backoffice e a role dos 3 para B2B - Delivery; (d) preencher Title com o
cargo da planilha nos 69. Tudo em lote pequeno, com DEPOIS no log.

## Rascunho para a Priscila

> Pri, rodei a planilha contra a org. Dos 69, 62 ja existem e estao ativos (foram criados em abril e junho como Read Only +
> role B2B - Delivery, igual ao Romulo); 42 deles nunca entraram. Faltam criar 7 (Leticia Santos e 6 analistas de projetos,
> 5 com e-mail .t). Licenca tem de sobra. Duas coisas antes de eu executar: (1) a Fernanda e Backoffice (edita conta,
> oportunidade, pedido, contrato) e o Romulo e Read Only (so le) com o permission set "App BTP B2B - Visibilidade". Voce
> quer todo mundo editando, como a Fernanda, ou so lendo, como o Romulo? Hoje o time inteiro esta como o Romulo, sem o
> permission set. (2) Ciro Librino, Telmo Baggio e Oscar Oesterreich estao na arquitetura (perfil Especialistas); mudo
> eles tambem ou saem da lista? Os 4 sem cargo e os e-mails .t ja existem em parte; me confirma que todos continuam.

## Fase 2 executada (17/09, 14h): decisao do Diego, "nao cria usuarios novos e todos com o perfil do Romulo"

Script 46 (scripts/46_AcessosDelivery_ComoRomulo_1709.apex), por Id dos 62 existentes, alvo = Romulo (Read Only,
B2B - Delivery, PS App BTP B2B - Visibilidade). Fase 1: perfil a trocar 0, role a trocar 0, PS a atribuir 57, 1 ja ok
(Romulo), 4 excecoes fora. Fase 2: 57 permission sets atribuidos, nenhum User alterado. DEPOIS: 58 dos 62 com Read Only +
B2B - Delivery + PS; 59 usuarios ativos Read Only + B2B - Delivery na org.

Ficaram de fora, aguardando a Priscila (INCLUIR_EXCECOES = true no script 46 aplica): Fernanda Ientzn da Rosa (gerente,
B2B - Backoffice; virar Read Only tira a edicao dela) e Ciro Librino, Telmo Baggio, Oscar Oesterreich (B2B - Especialistas
na role e fila de Arquitetura; trocar tira os tres da arquitetura). Os 7 da lista C nao foram criados (decisao do Diego).
Title nao foi preenchido (nao pedido). 42 dos 58 nunca fizeram login: a Priscila avisa o time.
