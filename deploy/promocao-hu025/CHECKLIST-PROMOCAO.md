# HU-025 — Checklist de promoção para o próximo ambiente (UAT/Prod)

Ordem importa. Itens 1 e 4 são MANUAIS (não vão em pacote).

## 1. Config manual ANTES do deploy
- [ ] Setup → Feature Settings → Manufacturing → Partner Lead Management:
      ligar **Partner Lead Management** e **Default Mappings** (mesmos toggles
      do DevSales, 15/07/2026).

## 2. Pacote de metadados (retrieve do DevSales → deploy no destino)
Manifest: `package-retrieve.xml` desta pasta. Conteúdo:
- [ ] `ObjectHierarchyRelationship`: LeadLineItem_To_OppLineItem +
      LeadPreferredSeller_To_OppPreferredSeller (mapping CurrencyIsoCode —
      obrigatório em org multicurrency).
      ATENÇÃO à estrutura: pasta `ObjectHierarchyRelationship/` (singular),
      sufixo `.settings` (deploy de 15/07 falhou até acertar isso).
- [ ] `Flow`: Lead_AS_EstampaRTOpp (RT + etapa na conversão). Ativar após
      deploy se chegar inativo.
- [ ] `LeadConvertSettings`: Map Lead Fields (pares Lead→Opp: Marca, Sociedad,
      NationalId, Método de contacto, Estado Lista Negra, Cilindrada, Tipo de
      Moto). RETRIEVE SÓ DEPOIS de completar os pares no DevSales.
      Deploy SUBSTITUI o arquivo inteiro no destino — conferir antes se o
      destino tem mapeamentos próprios que precisem ser mesclados.
- [ ] NÃO promover: Opp_BS_EstampaRT (Obsolete, substituição futura).

## 3. Dados (não é metadado — carga)
- [ ] Products + VehicleDefinitions (carga de 14/07).
- [ ] Price Books das sociedades (ex.: "C101 - Vehiculos y Motos (CR)") e
      PricebookEntries ATIVAS nas moedas de venda (CRC etc.) — sem entry na
      moeda da Opp o line item não é criado na conversão.

## 4. Pós-deploy manual
- [ ] Permission sets nos usuários (Partner Lead Management etc., conforme
      perfil do ambiente).
- [ ] Teste de fumaça: converter 1 lead por sociedade (Industry preenchido,
      line item com produto que tenha entry na moeda, preferred seller) e
      conferir: Products, Preferred Seller, RT/etapa, campos do pai.

## Pendências conhecidas (não bloqueiam a promoção)
- Flow before-save de Price Book por sociedade (Opp convertida hoje cai no
  Standard Price Book, não no book da sociedade).
- Validar teste pós-deploy do mapping CurrencyIsoCode no DevSales (deploy ok
  em 15/07; teste de conversão pendente de confirmação).
