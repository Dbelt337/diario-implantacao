# Runbook E — PROD: incidente de auto-contenção (Mullvad)

**Pré-condição obrigatória: Diego presente. Nenhum passo deste runbook é executável sem ele.**

Org PROD: `00DHu00000FcxIg` · Usuário congelado: `005V200000L0VZB` ·
Evento: login via proxy anonimizador Mullvad, IP `193.19.205.96`, em 10/08/2026.

## Sequência

1. **Descongelar**: abrir `<URL prod>/005V200000L0VZB` no Setup → botão Descongelar.
2. **Forense** (antes de qualquer outra mudança):
   ```sql
   SELECT LoginTime, SourceIp, Application, Status FROM LoginHistory
   WHERE UserId = '005V200000L0VZB' ORDER BY LoginTime DESC LIMIT 50
   ```
   - Confirmar o login Mullvad em 10/08.
   - Capturar o IP legítimo monótono (candidato: `168.227.237.47` — validar na PROD,
     não assumir a partir do QA).
3. **Blindagem**: Login IP Ranges no perfil `Salesforce API Only System Integrations`
   da PROD com o(s) IP(s) legítimo(s) confirmados no passo 2.
4. **Teste do ciclo + termômetro** (na PROD o schema TEM Status__c/TargetSystem__c):
   ```sql
   SELECT IntegrationName__c, NotProcessed__c, COUNT(Id), MAX(CreatedDate)
   FROM IntegrationLog__c WHERE CreatedDate = LAST_N_DAYS:5
   GROUP BY IntegrationName__c, NotProcessed__c
   ```
5. **Credencial**: se o LoginType da PROD for username-password (não OAuth):
   Reset Password coordenado com o Thiago (e-mail vai para ele) + atualização no
   sistema chamador.
6. **Higiene**: se o username da PROD terminar em `.qa`, renomear na janela
   (batismo errado de promoção).

## Entradas do dossiê de segurança (registrar junto)

1. Exposição de payload do IntegrationLog por design (toda a operação lia
   Request/ResponsePayload) — remediação no item D.
2. Quebra de imutabilidade do log (4 PS com Edit+Delete) — remediação no item D.
3. `Admin_User_Test` ativo com poder total — 3ª aparição; já na lista de
   desativação do programa de segurança.
4. **Nova (11/08)**: `client_secret` do app Keycloak `troubleTicket-app`
   (realm master, keycloak-hml) exposto em chat pelo time Mule junto com curl de
   teste. Ação: rotacionar o secret no Keycloak-HML, reenviar por canal seguro,
   e reforçar com o time Mule a regra "segredo nunca em chat".
