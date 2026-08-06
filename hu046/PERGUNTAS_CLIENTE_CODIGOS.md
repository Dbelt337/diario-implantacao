# HU-046 · Códigos SAP — o que fechou e as 4 perguntas que faltam

Contexto: recebemos `Sucursales_QRM_4.xlsx` + a gravação "Sucursales activas Salesforce QRM" (Luis Chavarría, 04/06). **Achado-chave, confirmado em áudio pelo cliente: "la combinación centro+almacén es la llave que identifica el patio"** — o centro (WERKS) repete (todas as C101 = `C011`; almacén 1200 existe em C101, C105, N105, N101...). Portanto o código de sucursal adotado é o **composto Centro+Almacén** (coluna E, ex. `C0111200` = La Uruca), gravado em `BranchCode__c` (37 dos 40 cupos CR+NI) e no `AccountNumber` das 21 contas dealer (fix4).

**Mais 3 fatos da gravação que entram no desenho:**
- **Interface de reserva SAP pedirá só o CENTRO** (não o almacén) — vale para novos e usados; o almacén é referencial, o inventário determina. (Impacta o mapping do Flavio: payload de reserva = WERKS.)
- **Um mesmo patio atende 2 sucursais QRM**: Lindora + Santa Ana Comercial = `C0111210`; La Uruca + Uruca Flotas = `C0111200`; Forland La Uruca Central + Active Motors Central = `C3111200`. Consequência: AccountNumber NÃO é único entre contas dealer → chave de upsert de contas continua sendo outra (SourceSystemIdentifier/SAPCode__c por conta, decisão pendente).
- **Depuração vem aí**: CR não vende mais motos — as sucursais C105 de motos (Autopits, GOLLO, Curacao) serão inativadas; Vanessa trará a lista depurada do time Active Motors. Não carregar essas como Accounts.
- Marcas das sociedades "5": Forland (camiones), Chery, GWM, Arcfox e GAC (entrando em CR) → reforça que GWM Liberia é operação C105.

## Perguntas para o GrupoQ (mandar no Teams)

1. **Forland Pérez Zeledón aparece DUAS vezes** na planilha: `C211/1202` (linha 14, junto com as demais Forland) e `C311/1202` (linha 109). Qual é o centro correto para a operação de vehículos da sucursal? *(Assumimos `C2111202` por consistência com Forland Liberia/San Carlos/Guápiles — corrigir se for C311.)*
2. **GWM Liberia**: qual sucursal física/centro atende a marca GWM em Liberia — GrupoQ Liberia (`C0111209`) ou Forland Liberia (`C2111201`)? (cupo `CR_GWM_Liberia` está sem código).
3. **Nicarágua — marcas × sociedades**: CHERY e FORLAND em Chinandega saem de qual centro? (Só existe Chinandega na N101 = `N0211210`; não há Chinandega na N105.) E em Managua, CHEVROLET/NISSAN vendem pela N101 (Jean Paul Genie `N0211200` / Los Robles `N0211217`) ou pela Active Motors N105 (`N1211200`)? *(Assumimos N105 `N1211200` para os 4 cupos Managua por ser a única conta NI no Salesforce — validar.)*
4. **Uruca Usados** tem centro `C817` **sem almacén** na planilha. Confirmar se o código completo é só `C817` (foi o que gravamos no AccountNumber da conta).

## Decisões tomadas (registrar na HU)

- `BranchCode__c` (CMDT) e `AccountNumber` (Account dealer) = **Centro+Almacén** (`C0111200`), não o centro sozinho.
- A planilha QRM cobre TODOS os países (596 linhas, incl. GT/HN/PA/SV) → versionada em `integracion/data/sucursales_qrm_completo.csv`; é o de-para mestre do rollout e da carga de Locations (almacén→Location.ExternalReference, HU-045/T09).
- Contas de nível sociedade continuam com o código curto (C101/C105/N105) do fix1.
- 3 cupos ficam sem código até resposta: `CR_GWM_Liberia`, `NI_CHERY_Chinandega`, `NI_FORLAND_Chinandega`.
