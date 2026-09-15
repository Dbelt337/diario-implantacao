// 12 - Cria os Acceptance Criteria (lista relacionada da work) das works B2B-13 a B2B-16.
// Rodar DEPOIS dos scripts 11a-11d e DEPOIS de conferir no log do script 10 (linhas AC-OBJETO / AC-CAMPO) os nomes
// abaixo. Se o objeto ou os campos tiverem outro nome, ajuste SOMENTE as 5 constantes. Reexecutar e seguro
// (checa por work + Name antes de criar). Filtre o log por AC12|.
String OBJ      = 'agf__ADM_Acceptance_Criterion__c';   // objeto da lista "Acceptance Criteria"
String F_WORK   = 'agf__Work__c';                        // lookup para a work
String F_DESC   = 'agf__Description__c';                 // campo Description da tela
String F_STATUS = 'agf__Status__c';                      // campo Status da tela
String STATUS   = 'New';                                 // valor inicial mostrado na tela

Map<String, List<String>> crit = new Map<String, List<String>>();
crit.put('US B2B-13%', new List<String>{
 'Criterio 1 - Elegibilidade e trava|Dado um contrato B2B ativo com uma Opportunity de Alteracao Contratual aberta, quando o GR aciona "Refidelizar" na 360, entao o sistema bloqueia e exibe o numero da oportunidade em andamento.',
 'Criterio 2 - Prazo padrao|Dado um contrato ativo ha 12 meses sem MACD aberto, quando o GR escolhe 24 meses e confirma, entao o sistema gera o aditivo sem acionar Arquitetura e envia a fila de aprovacao do BKO.',
 'Criterio 3 - Prazo customizado|Dado o OmniScript de renovacao, quando o GR escolhe "Outro" e informa 18 meses sem justificativa, entao o sistema bloqueia o avanco ate a justificativa ser preenchida.',
 'Criterio 4 - Escopo somente leitura|Dado o OmniScript carregado, quando o GR visualiza os ativos, entao eles aparecem em somente leitura e nao existe acao de adicionar item, remover item ou alterar preco.',
 'Criterio 5 - Aditivo e datas|Dado o aditivo de 36 meses aceito pelo signatario legal e aprovado pelo BKO, quando a sincronizacao com o Customer Core retorna sucesso, entao Contract Term = 36, Contract End Date recalculada, Data Fim de Fidelidade atualizada em todos os assets do contrato e o aditivo listado em Amendment Contracts.',
 'Criterio 6 - BKO obrigatorio|Dado o aditivo em Aguardando BKO, quando um usuario GR abre o registro, entao a acao "Aprovar Aditivo" nao aparece; e enquanto o BKO nao aprova, nenhuma chamada ao Customer Core e feita e o contrato permanece com os dados anteriores.',
 'Criterio 7 - Alerta pre-vencimento|Dado um contrato com Data Fim de Fidelidade em 60 dias, quando o scheduled path executa, entao uma Task e criada para o GR; e se o contrato for renovado antes, o path pendente e cancelado sem gerar Task.',
 'Criterio 8 - Guarda-chuva|Dado um contrato com tres etiquetas ativas, quando a refidelizacao e concluida, entao as tres recebem a mesma Data Fim de Fidelidade.',
 'Criterio 9 - Desconto de fidelidade|Dado um frame agreement com desconto contract-based vencendo em 31/12, quando a refidelizacao de 24 meses e ativada, entao a Effective End Date do desconto passa para 24 meses apos o novo inicio e os MRC dos assets nao mudam.' });
crit.put('US B2B-14%', new List<String>{
 'Criterio 1 - Prazo e data|Dado um cancelamento efetivado em 01/10 com aviso previo de 30 dias, quando o usuario confirma, entao Data Fim do Aviso Previo = 31/10, Contract Status = "Em Aviso Previo" e o contrato aparece no painel com 30 dias restantes.',
 'Criterio 2 - Nada no OM durante a janela|Dado um contrato em aviso previo, quando se consulta as ordens do contrato durante a janela, entao nao existe ordem de desativacao criada nem submetida ao OM e o faturamento segue ativo.',
 'Criterio 3 - Corte automatico|Dado um contrato com Data Fim do Aviso Previo em 31/10 e sem reversao, quando o sistema atinge 01/11 (data manipulada em QA), entao o scheduled path cria e submete a ordem ABO de desconexao, o Customer Core recebe a ordem tecnica e, apos o callback, o Billing Stop e enviado e os assets ficam Deleted/Cancelado.',
 'Criterio 4 - Reversao cancela o agendamento|Dado um contrato aguardando aviso previo de 60 dias, quando o Analista de Retencao aciona "Reverter Cancelamento" com motivo, entao o Contract volta a Activated, a Opportunity fecha como Retido e o agendamento some de Time-Based Automations sem nenhuma ordem gerada.',
 'Criterio 5 - Renegociacao de prazo|Dado um contrato com corte agendado para 30/12, quando o usuario altera a Data Fim do Aviso Previo para 30/11, entao o agendamento passa a 01/12; e se tentar uma data passada, a Validation Rule bloqueia.',
 'Criterio 6 - Visibilidade por carteira|Dado dois GRs com carteiras distintas, quando cada um abre o painel, entao ve apenas os contratos em aviso previo das proprias contas, enquanto o perfil Retencao ve todos.',
 'Criterio 7 - Falha e retentativa|Dado que a Integration Procedure de submissao falha, quando o scheduled path executa, entao a plataforma retenta e, esgotadas as tentativas, uma Task e criada para o BKO e o contrato aparece como "Corte com Falha".',
 'Criterio 8 - Reversao apos submissao|Dado uma ordem de desativacao ja submetida e ainda antes do Point of No Return, quando o BKO aciona o cancelamento in-flight, entao o OM congela a ordem e gera a suplementar; e um usuario GR nao ve essa acao.' });
crit.put('US B2B-15%', new List<String>{
 'Criterio 1 - Padrao|Dado uma cotacao B2B nova, quando o GR chega a etapa de dados de faturamento, entao Intervalo = Mensal e Condicao = Mes Corrente vem preenchidos e a cotacao segue sem aprovacao adicional.',
 'Criterio 2 - Nao padrao roteia|Dado uma cotacao para orgao publico, quando o GR seleciona Trimestral e Vencimento Mes Seguinte, entao a aprovacao expressa e bloqueada, a justificativa e exigida e a cotacao vai a fila do BKO/Gestor Financeiro com o registro travado.',
 'Criterio 3 - Preco inalterado|Dado uma cotacao com MRC de R$ 1.000 e intervalo Semestral, quando o carrinho e reprecificado, entao as linhas continuam com R$ 1.000 mensais e o campo informativo mostra R$ 6.000 por ciclo.',
 'Criterio 4 - Somente leitura apos aprovacao|Dado uma cotacao aprovada com condicoes nao padrao, quando o GR tenta alterar o intervalo, entao o sistema bloqueia e orienta a gerar cotacao filha.',
 'Criterio 5 - Propagacao e payload|Dado uma Opportunity Semestral aprovada e convertida, quando o BKO aciona Imputar Venda, entao Order e Contract carregam os mesmos valores e o payload ao SAP traz Billing Frequency e Payment Terms com as chaves do de-para.',
 'Criterio 6 - Sem de-para|Dado um valor de intervalo sem chave SAP cadastrada, quando o handoff e acionado, entao o envio e bloqueado com mensagem indicando o valor sem de-para.',
 'Criterio 7 - B2C inalterado|Dado uma venda B2C, quando o vendedor chega aos dados de faturamento, entao Intervalo continua "Mensal" somente leitura.' });
crit.put('US B2B-16%', new List<String>{
 'Criterio 1 - D0|Dado uma proposta enviada pelo botao "Enviar proposta comercial ao cliente", quando o envio conclui, entao existe um registro Envio para Assinatura com Status Pendente, o signatario legal como contato e o Contact entrou na jornada.',
 'Criterio 2 - D+7 as 08:00|Dado um envio com Status Pendente ha exatos 7 dias, quando o relogio marca 08:00 de Brasilia, entao o signatario recebe o e-mail do template de proposta com copia ao GR, o campo "Ultimo lembrete enviado" passa a D+7 e uma Task Completed "Lembrete de assinatura D+7" aparece na Opportunity em ate 24 horas.',
 'Criterio 3 - Quebra por assinatura|Dado um envio com lembrete D+15 previsto para amanha, quando o callback de assinatura chega hoje a tarde, entao o Status muda para Assinado, o Contact sai da jornada e nenhum e-mail e enviado amanha.',
 'Criterio 4 - Expiracao|Dado um envio pendente ha 30 dias, quando o D+30 dispara, entao e o ultimo e-mail e o Status passa a Expirado pela regra da W-000098.',
 'Criterio 5 - Reenvio manual|Dado um envio pendente em D+5, quando o GR reenvia manualmente o mesmo envelope apos corrigir o e-mail do signatario, entao a cadencia continua contando do envio original e o proximo lembrete e D+7.',
 'Criterio 6 - Novo envelope|Dado um envio pendente, quando um novo envelope e gerado, entao o registro anterior e encerrado e um novo D0 comeca.',
 'Criterio 7 - Contingencia|Dado o Marketing Cloud indisponivel e a contingencia ativa, quando o schedule-triggered flow roda as 08:00, entao os envios com 2, 4, 7, 15 ou 30 dias recebem o e-mail pelo endereco organizacional, com o e-mail registrado na Opportunity e sem envio a quem ja assinou.',
 'Criterio 8 - E-mail corrigido|Dado um envio pendente cujo signatario teve o e-mail corrigido pelo GR em D+3, quando o D+4 dispara, entao o e-mail vai para o endereco corrigido do Contact.' });

Schema.SObjectType t = Schema.getGlobalDescribe().get(OBJ);
if (t == null) { System.debug('AC12| ERRO: objeto ' + OBJ + ' nao existe. Use o nome da linha AC-OBJETO do script 10.'); return; }
Map<String, Schema.SObjectField> fm = t.getDescribe().fields.getMap();
for (String f : new List<String>{ F_WORK, F_DESC, F_STATUS }) {
    if (!fm.containsKey(f.toLowerCase())) { System.debug('AC12| ERRO: campo ' + f + ' nao existe em ' + OBJ + '. Ajuste as constantes.'); return; }
}
Boolean nomeEditavel = fm.get('name').getDescribe().isCreateable();

Integer criados = 0, existentes = 0;
for (String prefixo : crit.keySet()) {
    List<agf__ADM_Work__c> ws = [SELECT Id, Name FROM agf__ADM_Work__c WHERE agf__Subject__c LIKE :prefixo];
    if (ws.size() != 1) { System.debug('AC12| ' + prefixo + ' | PULADO: encontradas ' + ws.size() + ' works (esperado 1)'); continue; }
    agf__ADM_Work__c w = ws[0];
    Set<String> nomesJa = new Set<String>();
    for (SObject e : Database.query('SELECT Name FROM ' + OBJ + ' WHERE ' + F_WORK + ' = :wid'.replace(':wid', '\'' + w.Id + '\''))) {
        nomesJa.add((String) e.get('Name'));
    }
    List<SObject> novos = new List<SObject>();
    for (String linha : crit.get(prefixo)) {
        String nome = linha.substringBefore('|'), desc = linha.substringAfter('|');
        if (nomesJa.contains(nome)) { existentes++; continue; }
        SObject ac = t.newSObject();
        if (nomeEditavel) ac.put('Name', nome);
        ac.put(F_WORK, w.Id);
        ac.put(F_DESC, (nomeEditavel ? '' : nome + ': ') + desc);
        ac.put(F_STATUS, STATUS);
        novos.add(ac);
    }
    if (!novos.isEmpty()) insert novos;
    criados += novos.size();
    System.debug('AC12| ' + w.Name + ' | ' + prefixo + ' | criados agora=' + novos.size() + ' | ja existiam=' + nomesJa.size()
        + ' | total esperado=' + crit.get(prefixo).size());
}
System.debug('AC12| RESULTADO: ' + criados + ' criterios criados, ' + existentes + ' ja existiam. Name editavel=' + nomeEditavel);
