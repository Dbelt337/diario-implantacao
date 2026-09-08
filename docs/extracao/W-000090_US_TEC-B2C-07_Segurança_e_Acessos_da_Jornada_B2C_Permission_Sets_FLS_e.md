# W-000090 — US TEC-B2C-07 — Segurança e Acessos da Jornada B2C (Permission Sets, FLS e Filas)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

US técnica (arquitetura BTP).

TEC-B2C-07: Segurança e Acessos da Jornada B2C
Narrativa: Como time de implantação, quero o modelo de acesso da jornada B2C definido por permission sets, para cada perfil ver e fazer apenas o que o processo permite.
Escopo técnico:
- Permission sets: PS_B2C_Sales_User, PS_B2C_Backoffice_User, PS_B2C_Lead_Importer (US-01), Mesa de Crédito.
- FLS: ocultar score/motivos de reprovação do vendedor (US-09); travar campos de preço da taxa (US-12).
- Filas: Mesa de Crédito, Backoffice Comercial B2C, Fila Vendas E-commerce (US-15/19).
- OWD e Role Hierarchy para a visibilidade gerencial (US-23).
Critérios de aceite: matriz perfil x permissão validada em sandbox com um usuário de teste por perfil.
Dependências: catálogo de perfis provisionados via Senior/Octa (US-22).

## Critérios de Aceite (related list)

**1. Critério 1** (New)
matriz perfil x permissão validada em sandbox com um usuário de teste por perfil.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO COM B2B ---
Incluir no modelo de acesso os papéis da jornada B2B: Gestor de Relacionamento (GR), Arquiteto de Soluções (edição de dados técnicos), Analista de BKO (perfil aberto para correção por 6 meses e botão Imputar Venda restrito) e Analista de Retenção. FLS de margem/custos restrita conforme B2B-03.

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
RISCO DE SEGURANCA - ACAO IMEDIATA (lacunas da consultoria, severidade alta):
Segredo com aparencia ativa em metadata VERSIONADA: namedCredentials/CNPJPublicAPI.namedCredential-meta.xml.
ACAO: rotacionar a credencial e migrar para External Credential/secret store ANTES de qualquer novo desenvolvimento; varrer o repositorio por outros segredos versionados e incluir a verificacao no checklist de seguranca desta work (pipeline com secret scanning).
DIRETRIZ SYSMAP: tratar como item de sprint corrente, fora da fila normal de backlog.
