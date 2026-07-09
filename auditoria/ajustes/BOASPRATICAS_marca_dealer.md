# Boas práticas — modelagem marca × dealer/sucursal (Automotive Cloud)

Pesquisa sobre como a indústria automotiva modela "quais marcas cada sucursal vende" e
como isso mapeia no Salesforce Automotive Cloud. Fontes ao final.

## 1. Conceito da indústria: rooftop + franchise (N:N)
No varejo automotivo o padrão consagrado é:
- **Rooftop** = a localização física de venda (a "sucursal"). É UMA por endereço.
- **Franchise** = a marca/OEM que aquele rooftop tem direito de vender. Um rooftop pode
  carregar **várias franquias** (multi-brand), e uma marca está em **vários rooftops** → **N:N**.
- Cada **franquia num rooftop tem o seu próprio código de dealer do OEM/ERP** (contrato,
  reporting, incentivos são por franquia, não por prédio).

Boa prática de dealer group multi-marca (Toyota+Honda+Nissan num mesmo grupo): um **modelo de
dados comum**, **um registro-ouro de cliente/VIN** atravessando marcas e rooftops, e decisão
explícita de **system of record** por objeto. (Pedowitz, Driftrock.)

## 2. Como isso se aplica ao GrupoQ (e resolve a colisão de SAP)
O que parecia "dealer duplicado" no nosso load é, na verdade, o padrão franchise:
- `La Uruca` (Autos, centro **C011**) e `La Uruca ... Forland/Vehiculos` (centro **C311**) são
  **o mesmo rooftop** com **franquias diferentes**, cada uma com **seu código SAP**.
- Por isso `ExternalReferenceNumber` (único) **colide** se tratado por rooftop — ele é, na
  verdade, a chave **por franquia**, não por prédio.

Conclusão: o código SAP pertence à **franquia (marca no rooftop)**, não ao Account do rooftop.

## 3. Mapeamento no Automotive Cloud (objetos)
| Papel | Objeto | Observação |
|---|---|---|
| Rooftop (sucursal física) | **Account** (Record Type "Concesionaria") | 1 por localização |
| Catálogo de marcas (OEM) | **BusinessBrand** | marca mestre; parent = grupo/OEM |
| Marca-no-rooftop (franquia) | **BranchUnit** (Branch Management) *ou* junção custom | é o N:N; carrega o código SAP e o BusinessProfile daquela franquia |
| Chave SAP por franquia | **BusinessProfile.ExternalReferenceNumber** | 1 BP por franquia (não por rooftop) |
| Branding de site/portal | **AccountBrand** | só se usar Experience Cloud; 1 identidade de marca por conta; exige licença community |

### Duas implementações válidas do N:N
- **A) BranchUnit por franquia** (recomendado): cada rooftop tem N BranchUnits (uma por marca
  que vende). Nativo do AC, dá **visibilidade/handover** (proposta Wilmar) e resolve multi-marca.
  A disponibilidade "marca X na sucursal Y" = existência do BranchUnit. O BusinessProfile
  (Sales Dealer) e o código SAP ficam na franquia.
- **B) Junção custom `DealerBrand__c`** (Account ↔ BusinessBrand): mais leve, puro dado de
  disponibilidade + reporting, sem a maquinaria de visibilidade. Boa se não precisar de sharing
  por franquia.

**AccountBrand não é o objeto da matriz** — ele é identidade de marca de um Partner Account para
branding de Experience Cloud (logo/website/nome), 1 por conta. Só entra se o objetivo for
brandear os sites (cadillac.cr / chevroletcr.com / forlandcr.com) como Digital Experiences.

## 4. Recomendação para o GrupoQ
1. **Account = rooftop** (uma sucursal por local), com Record Type "Concesionaria".
2. **BusinessBrand** = catálogo de marcas (já há 23 na org) — validar contra a marca-por-país.
3. **BranchUnit por franquia** no rooftop (A). Ali penduram-se:
   - o **BusinessProfile** `Sales Dealer` com o **código SAP daquela franquia** (`ExternalReferenceNumber`),
   - a associação à **BusinessBrand** (lookup, se existir no describe; senão junção custom).
4. **AccountBrand** apenas se/quando os sites de test-drive virarem Experience Cloud.

Efeito colateral positivo: como o SAP passa a ser por franquia (BranchUnit), some a colisão de
`ExternalReferenceNumber` — cada linha (Autos/Forland/Repuestos) tem seu código sem duplicar o rooftop.

## 5. A confirmar na org (antes de construir)
- `describe_branch.apex` — campos/lookups de BranchUnit (tem lookup para BusinessBrand? para Account?).
- `describe_brands.apex` — BusinessBrand: parent/lookups; AccountBrand presente (licença)?.
- Definir se a disponibilidade precisa de **visibilidade** (→ BranchUnit) ou só **dado** (→ junção custom).

## Fontes
- Automotive Cloud — Data Model Gallery (Developer): developer.salesforce.com/docs/platform/data-models/guide/automotive-cloud-overview.html
- Automotive Cloud Standard Objects (Developer Guide): developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm
- Create Business Brands in Automotive Cloud: help.salesforce.com/s/articleView?id=ind.auto_business_brands.htm
- BusinessBrand (Object Reference): developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_businessbrand.htm
- AccountBrand (Object Reference): developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_accountbrand.htm
- Configure Branch Management for Automotive Cloud: help.salesforce.com/s/articleView?id=sf.auto_configure_branch_mngmnt_dealer.htm
- Como automakers unificam CRM e dados de dealer (Pedowitz Group): pedowitzgroup.com/automakers-unify-crm-and-dealer-data
- Automotive dealer software / multi-rooftop (Driftrock): driftrock.com/blog/automotive-dealer-software

> Corpos das páginas salesforce.com não puderam ser baixados nesta sessão (egresso bloqueia
> *.salesforce.com, HTTP 403); síntese feita a partir das referências de objeto, docs de AC e
> fontes de indústria acima. Confirmar os lookups exatos via os describe read-only citados.
