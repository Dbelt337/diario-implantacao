# Runbook H — Pós-refresh de sandbox (processo permanente)

Responde ao pedido do Thiago ("carregar os ambientes") como checklist repetível.
Executar na ordem, a cada refresh de sandbox que participe de integração.

## 1. Seed de dados de referência Field Service

- Rodar `scripts/seed_field_service.apex` (idempotente — reexecutável sem duplicar):
  OperatingHours "Horário Comercial BTP" + TimeSlots seg–sex 08:00–18:00;
  WorkTypes Instalação (120 min) e Reparo Técnico (90 min), Product BandaLarga;
  ServiceTerritories CBA/JIA/PVT/IUZ/ROI/PDG/RVG com faixas de CEP 99999-999
  sem sobreposição; Account "CONTA TESTE INTEGRACAO FIELD" com CNPJ de teste
  `11.222.333/0001-81`.
- Validar com: `SELECT COUNT() FROM ServiceTerritory` (esperado >= 7) e
  `SELECT Id FROM Account WHERE DocumentNumber__c = '11.222.333/0001-81'`.

## 2. Credenciais e endpoints (o refresh NÃO copia segredos)

- [ ] Recadastrar principal da External Credential `MuleAuth` (secret por canal seguro).
- [ ] Auditar TODAS as Named Credentials: nenhuma pode apontar para path/host de
      PROD (caso conhecido: `MuleCallout` → `btp-salesforce-eapi-prod`).
- [ ] Verificar Remote Site Settings necessários (My Domain para testes de composite).

## 3. Drift de schema

- Comparar `FieldDefinition` dos objetos de integração (mínimo `IntegrationLog__c`)
  entre origem e sandbox:
  ```sql
  SELECT QualifiedApiName, DataType FROM FieldDefinition
  WHERE EntityDefinition.QualifiedApiName = 'IntegrationLog__c'
  ```
- Corrigir divergências por deploy de metadata versionada (`metadata/` deste
  diretório), nunca por criação manual sem auditoria prévia.

## 4. Checklist de acesso

- [ ] Usuário de integração: perfil `Salesforce API Only System Integrations` +
      PS `Integracao_Field_Service` (mínimo do fluxo). Sem perfil admin, nunca.
- [ ] Sufixos de username coerentes com o ambiente (`.qa` só no QA; PROD sem sufixo).
- [ ] Senhas/segredos rotacionados a cada refresh; e-mail do usuário de serviço em
      DL de integração, não em caixa pessoal.
- [ ] Login IP Ranges no perfil de integração com os IPs legítimos do Mule.
- [ ] Conferir que `Admin_User_Test` e afins continuam desativados.

## 5. Prova de fumaça da integração

- Rodar `scripts/composite_teste_encadeado.apex` no sandbox: os 3 GETs por chave
  de negócio devem retornar registro e o POST de WorkOrder deve criar com Ids
  encadeados.
- Reteste ponta a ponta com o time Mule (payload com chaves que existem no seed:
  CNPJ `11.222.333/0001-81`, WorkType `Instalação`/`Reparo Técnico`, CEP dentro
  das faixas semeadas, formato 99999-999).
- Verificação dupla: WorkOrder criada + IntegrationLog gravado + login do usuário
  de integração no LoginHistory.

## Aprendizados incorporados (histórico 08/2026)

- NOT_FOUND em composite quase sempre é Id de outra org ou connector apontando
  para org errada — nunca assumir "falta dado" sem checar LoginHistory.
- `WorkType.Product__c` é picklist restrita; se insert recusar valor ativo,
  investigar com describe `getController()` antes de mexer em valores.
- `ServiceTerritory` tem validação custom de CEP (formato 99999-999) e campos
  fórmula-espelho — filtrar `isUpdateable()` em descoberta de campos.
- `Account` tem defaults por automação e callout pós-insert (`AccountGetSapIdQueueable`)
  — em sandbox recém-atualizado esse callout falha até o passo 2 ser feito.
