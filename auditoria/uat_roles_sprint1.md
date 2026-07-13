# UAT Sprint 1 — Roles dos usuários da planilha de aprovisionamento

**Fonte:** `Usuarios_UAT_Sprint1_Perfiles_Aprovisionamiento2.xlsx` (39 linhas) · **Data:** 13/07/2026 · **Escopo:** frente Vendas, fase 1 = Costa Rica · Proposta linha a linha em `uat_roles_sprint1.csv`.

## Resposta à pergunta "estão certas as roles?"

**A planilha não atribui role a ninguém — não existe coluna de role.** O próprio checklist dela (item 2) exige "crear los usuarios con el perfil de la pestaña 1 **y el rol indicado en la jerarquía**", mas a aba 1 só traz Perfil e Puesto. Não há o que validar; há o que preencher. Este documento é a coluna que falta.

## Mapeamento Puesto → Role (árvore v16, frente Vendas apenas)

| Puesto | Usuários | Role (DeveloperName) | Base |
|---|---|---|---|
| Director Comercial | Rodolfo Araya, Harvey Wills | `GQ_Ger_Regional_CA` | Diagrama A: nível regional CA acima dos países |
| Gerente Comercial Motos | Jorge Camilo (@grupoactivemotors) | `GQ_Ger_Marca_CR` | gerência de marca no país |
| Gerente Online / Gerente Online Motos | Johana Bonilla, Susana Segura, Alexis Mayorga | `GQ_Ger_VentasOnline_CR` | mesmo nó usado no re-role QA fase 1 |
| Asesor Online / Asesor Online Motos | Nicole Mora, Ana Nohemy Lopez, Marcela Moraga, Allison Rios, Keyla Espinoza | `GQ_AVO_CR` | mesmo nó do re-role QA |
| Asesor de Ventas Motos (presencial) | Roberto Flores | `GQ_Op_<sucursal>` — **bloqueado** | precisa da sucursal dele; e o perfil correto é AC_Vend_Veh, não AC_BDC_Ag |
| IT / Gestión de procesos (AC_Admin ×4) | Hector, Emmanuel, Marcela Mulato, Juan Carlos | sem role | admin enxerga tudo pelo perfil; role só polui a hierarquia |

**IDs de role NÃO viajam entre orgs** — em UAT, GrupoQ TI atribui pela DeveloperName (a árvore GQ_* precisa existir lá; se não existir, o pacote é `deploy/roles_v16/Roles_GQ_v16.zip`, deploy additive que a TI pode aplicar — você não deploya em UAT).

## O que NÃO recebe role de Vendas (23 dos 39)

- **17 usuários de mercadeo / repuestos / contact center** com AC_BDC_Ag: os puestos não são da frente Vendas. Encaixá-los em `GQ_AVO_CR` faria gerentes de vendas enxergarem leads de repuestos/mercadeo pela hierarquia. Ficam **sem role de Vendas** até o item 8 do checklist (alcance Contact Center/Mercadeo) definir o lugar deles.
- **5 usuários com Perfil "?"** (Efrain Sosa, Mariana Mora, Paola Safiano, Sergio Marroquin, Milton Muñoz): sem perfil definido não há role a validar — mesmo item 8.

## Bloqueios que impedem a criação correta (antes de qualquer role)

1. **Duplicados com o MESMO username**: `eledezma@grupoq.com.uat` e `mvillalobosm@grupoq.com.uat` aparecem 2× com perfis diferentes (AC_BDC_Ag vs "?"). O insert do segundo falha — decidir qual linha vale.
2. **ProfileIds misturam orgs**: `00eWK...` (UAT) e `00eao...` (outra org). Importar pela **API Name do perfil**, nunca pelos Ids da planilha.
3. **Coluna sociedad vazia** (Carmen/Vanessa devem): para os @grupoq.com não dá para afirmar país; assumi CR (fase 1) — confirmar antes do insert. @grupoactivemotors = Active Motors CR, esses são seguros.
4. Item 2 do checklist também pede **ManagerId** implícito na cadeia de aprovação — a planilha não traz gerente de ninguém.
