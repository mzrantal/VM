# Tilastokeskus-data (ladattu ja käytössä)

Tässä kansiossa on kaksi Tilastokeskuksen (pxdata.stat.fi) taulukkoa, jotka
`laske_vaikutus.R` lukee automaattisesti rakentamisen BKT- ja
työllisyysvaikutuksen laskentaan (ks. `../RAPORTTI.md`). Tiedostot on
ladattu ja vahvistettu tässä projektissa - ne EIVÄT ole esimerkkejä.

## Tiedostot

- **`panoskertoimet_14yq.csv`** - taulukko 14yq "Tuotoksen panoskertoimet"
  (`https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__pt/14yq.px/`):
  toimialoittainen (63 toimialaa) tekninen kerroinmatriisi A - kuinka monta
  euroa toimialan i tuotantoa tarvitaan yhtä euroa kohti toimialan j
  tuotosta. **Vahvistetusti kotimainen** (ei sisällä tuontia). Sisältää myös
  rivin "B1GPH Bruttoarvonlisäys perushintaan" (arvonlisäys/tuotos-kerroin
  suoraan, ei tarvitse laskea itse).
- **`kayttotaulukko_14yn.csv`** - taulukko 14yn "Panos-tuotostaulukko
  perushintaan"
  (`https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__pt/14yn.px/`):
  tästä käytetään vain rivejä "P1R Tuotos perushintaan" (toimialan tuotos,
  milj. e) ja "E1 Työlliset, kotimaa (1000 henkeä)" (työllisyys), joista
  `lataa_oikea_data.R` laskee työllisyys/tuotos-kertoimen.

Molemmat kattavat vuodet 2021-2023 (PxWeb-vienti, puolipisteerotin,
desimaalipiste, puuttuva arvo merkitty pisteellä ".", UTF-8-koodaus BOM-
merkillä). Laskennassa käytetään oletuksena vuotta 2023
(`vuoden_data_oletus`, `lataa_oikea_data.R`).

## Miksi vain rakentamiselle, ei IT-laitteille

`laske_vaikutus.R` kohdistaa näistä taulukoista rakennettavan Leontief-
mallin vain rakentamiseen (talonrakennus, maa- ja vesirakentaminen,
talotekniikka-/koneasennus - yhdistetty toimialaksi "F Rakentaminen
(41-43)"). IT-laitteet lasketaan edelleen `oletukset.R`:n karkealla
arviolla, koska 14yq:n kotimainen A-matriisi olettaisi virheellisesti että
koko IT-laitteiden kysyntä kohdistuu kotimaiseen tietokonevalmistukseen
(toimiala 26) - todellisuudessa se on lähes kokonaan tuontia. Katso
tarkempi selitys `../RAPORTTI.md`:n kohdasta "Miksi IT-laitteet ei käytä
oikeaa Leontief-mallia".

## Jos päivität tai vaihdat taulukot

Jos lataat uudemman vuoden taulukot tai eri toimialaluokituksen, säilytä
samat tiedostonimet (`panoskertoimet_14yq.csv`, `kayttotaulukko_14yn.csv`)
niin `laske_vaikutus.R` löytää ne automaattisesti. Jos toimialaluokitus
muuttuu (esim. hienojakoisempi, F41/F42/F43 erikseen), päivitä myös
`oletukset.R`:n `TOIMIALA_KOODIT_14Y`-vastaavuus vastaamaan uusia koodeja.
