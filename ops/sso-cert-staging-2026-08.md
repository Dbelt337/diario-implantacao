# Troca do certificado de assinatura SAML — sandbox Staging (21/08/2026)

Contexto: aviso automatico do Salesforce (cert expira 29/08/2026). Investigacao
provou uso: SelfSignedCert_29Aug2025_134321 era o Request Signing Certificate
do SSO Okta_Brasil_TecPar (criados no mesmo segundo, 29/08/2025 13:43:21).
A config tambem serve SLO assinado e 3 Experience Cloud sites (Rastreio
Tecnico, Rastreio de Atendimento, rastreamento).

Executado:
1. Criado SelfSignedCert_SSO_Staging_2026 (2048, vence 21/08/2027).
2. SSO "Brasil TecPar" reapontado para o cert novo (Save 21/08/2026).

Pendente:
- [ ] Teste: login via Okta em aba anonima + logout (SLO) + login em um portal.
- [ ] Del no SelfSignedCert_29Aug2025_134321 (e o que encerra os e-mails de aviso).
- [ ] PRODUCAO: mesma verificacao (SamlSsoConfig + Certificate and Key
      Management) — cert proprio, relogio proprio, 1.600 usuarios + portais.
- [ ] Calendario do time: 21/07/2027 — renovar o cert novo antes do aviso.

Rollback (se o login quebrar): reapontar o cert antigo no mesmo campo Edit —
valido ate 29/08/2026.
