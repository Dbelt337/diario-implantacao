# Regra canônica — país deriva do código da sociedade

O país é a **1ª letra** do código da sociedade. Um país tem várias sociedades e várias marcas.

| Letra | País | Cód. país (IOU) | Sociedades |
|---|---|---|---|
| C | Costa Rica (CR) | GQ_CR | C101, C105, C106-PROV |
| H | Honduras (HN) | GQ_HN | H101, H105, H106-PROV |
| N | Nicaragua (NI) | GQ_NI | N101, N105, N106-PROV |
| S | El Salvador (SV) | GQ_SV | S101, S105, S106-PROV, S206 |
| G | Guatemala (GT) | GQ_GT | G101, G105 |
| P | Panamá (PA) | GQ_PA | P103, P105 |

## Implicações de modelagem
- Hierarquia: Holding → País (agrupa sociedades da mesma letra) → Sociedade → Dealer.
  O país é derivável/validável pela letra (não deve divergir da sociedade).
- Marca: vive na sociedade (planilha marca×sociedade). País = roll-up das suas sociedades.
- Sites/test-drive são por país (cadillac.cr, chevroletcr.com) → país é o eixo do site;
  sociedade é onde a disponibilidade de marca mora; sucursal = ServiceTerritory.
- Fonte única: código da sociedade → país (letra) + marca (planilha) + código SAP (BusinessProfile).

## Regra para os scripts
Derivar país da 1ª letra em vez de hardcodar nome:
`Map<String,String> letraPais = {'C'=>'Costa Rica','H'=>'Honduras','N'=>'Nicaragua','S'=>'El Salvador','G'=>'Guatemala','P'=>'Panama'}`
e o código IOU do país = 'GQ_' + {CR,HN,NI,SV,GT,PA}. Assim os scripts servem os 6 países sem reescrever.
