# Sharing de Lead e Opportunity — desenho (GrupoQ)

Trabalho de cima pra baixo: **OWD → Role Hierarchy → Sharing Rules → Queues/Teams**.
Este doc é o esqueleto; se preenche com o retrieve do ambiente
(`retrieve-package.xml`) + as respostas das perguntas de negócio.

## 1. Estado atual (preencher com o retrieve)
- [ ] OWD Lead: ______  · OWD Opportunity: ______
- [ ] Role Hierarchy (colar/estruturar): ______
- [ ] Sharing Rules existentes (Lead): ______
- [ ] Sharing Rules existentes (Opportunity): ______
- [ ] Filas de Lead: ______ (já mapeadas: Leads_Repuestos, Leads_C101_Autos,
      Leads_C105_Autos, Leads_CR_Frotas, Leads_CR_Usados, Leads_N101_Motos,
      Leads_N105_Motos, Leads_Productos_Automotrices, Leads_CR_Offline)
- [ ] Campo de escopo do usuário: `$User.Sociedad__c` (confirmado no roteamento).

## 2. Perguntas de negócio (decidem o desenho)
1. Sociedad é a fronteira de visibilidade? (C101 vê C105 / motos?)
2. Marca separa dentro da sociedade? (Hyundai × Chevrolet)
3. Sucursal separa? (vendedores de sucursais diferentes se veem?)
4. Vendedor vê só o dele, ou o do time/sucursal?
5. Gerentes veem tudo da sociedade/marca/país deles? (hierarquia)
6. Repuestos/PA/Frotas/Usados têm visibilidade própria?
7. Time de telemarketing/BDC precisa ver leads de todas as sociedades?

## 3. Modelo proposto (default a validar)
- **OWD**: Lead = **Private**, Opportunity = **Private**.
- **Role Hierarchy** (espelhando a operação):
  ```
  Dirección País
    └─ Gerente Sociedad / Marca (C101, C105, N101, N105 × marca)
        └─ Gerente Sucursal
            └─ Supervisor de Ventas
                └─ Vendedor
  ```
  A hierarquia já dá ao gerente a visão dos registros do time (bottom-up).
- **Sharing Rules** (só o que a hierarquia NÃO cobre — lateral), criteria-based:
  - Por **Sociedad** (`CompanyCode__c` = C101 / C105 / N101 / N105) → compartilha
    com o Public Group da sociedade (ex.: BDC/backup da sociedade). Sem vazar
    entre sociedades.
  - (Se marca separa) refinar por `Brand__c` dentro da sociedade.
- **Queues**: seguem donas dos leads não atribuídos; membros da fila veem os leads.
- **Teams** (se preciso cross-hierarquia pontual): Opportunity Team / Account Team
  para o caso "avalúo em outra sucursal" (Owner não muda, participante via Team) —
  já registrado na HU-036.

## 4. Princípios (rubrica)
- Native-first: OWD + hierarquia + sharing rules declarativas. Sem Apex sharing
  a não ser que uma regra não seja expressável por criteria/owner.
- Menor privilégio: abrir só o necessário; isolamento por sociedade por padrão.
- Não assumir escopo não previsto: confirmar regras de visibilidade com o cliente
  antes de abrir cross-sociedad/marca.
