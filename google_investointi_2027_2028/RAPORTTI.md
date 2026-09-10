# Googlen 13 mrd. euron datakeskusinvestoinnin (2027-2028) BKT-vaikutus

## Kysymys

Kuinka paljon Googlen ilmoittama noin 13 miljardin euron investointi
datakeskuksiin Suomessa vuosina 2027-2028 kasvattaa Suomen BKT:ta?

## Lyhyt vastaus

Suoraan investoinnin euromäärästä ei voi laskea BKT-vaikutusta - 13 mrd. euroa
on **kysyntä** (tilaukset eri toimialoilta), ei **arvonlisäys** (BKT). Osa
rahasta valuu tuontiin (esim. palvelimet ja verkkolaitteet ovat lähes
kokonaan ulkomaista valmistusta), ja loppuosa synnyttää kotimaista
arvonlisäystä sekä suoraan (rakennus- ja asennustyö) että epäsuorasti
(alihankintaketjut: sora, betoni, sähkötarvikkeet, kuljetukset jne.).

Tässä repossa (`google_investointi_2027_2028/`) on toteutettu laskentaputki,
joka tekee juuri tämän jaottelun. Nykyisillä oletuksilla (`oletukset.py`,
ks. rajoitteet alla) tulos on:

| Vuosi | Investointi | BKT-vaikutus | Osuus investoinnista |
|---|---|---|---|
| 2027 | 6,50 mrd. e | **~1,62 mrd. e** | 25 % |
| 2028 | 6,50 mrd. e | **~1,62 mrd. e** | 25 % |
| **Yhteensä** | **13,00 mrd. e** | **~3,23 mrd. e** | **25 %** |

Toisin sanoen: karkealla arviolla noin **neljännes** investoinnin
euromäärästä (n. 3,2 mrd. e kahden vuoden aikana, n. 1,6 mrd. e/vuosi)
näkyisi Suomen BKT:ssä lisäyksenä rakennusvaiheen aikana. Loput valuvat
tuontiin (etenkin IT-laitteet) tai ulkomaisiin voittoihin. **Tämä on
suuruusluokka-arvio, ei tarkka tilastollinen laskelma** - katso alta miksi,
ja miten laskennan voi tarkentaa oikealla aineistolla.

Vertailun vuoksi: Suomen BKT oli v. 2024 noin 280 mrd. euroa, joten n. 1,6
mrd. e/vuosi vastaisi karkeasti n. 0,6 prosenttiyksikköä yhden vuoden BKT:sta
- ei mitätön, mutta ei myöskään dramaattinen, kertaluonteinen
rakennusvaiheen piikki.

(Osuus laski aiemmasta 35 %:sta 25 %:iin, koska oletettua IT-laitteiden
osuutta investoinnista nostettiin 50 %:sta 75 %:iin 10.9.2026 tehdyssä
`oletukset.py`-päivityksessä - IT-laitteiden kotimaisen arvonlisäyksen
kerroin on toimialoista matalin.)

## Menetelmä (mitä koodi tekee)

1. **Kysyntäshokit toimialoittain** (`oletukset.py`): 13 mrd. euron
   investointi jaetaan neljään toimialaryhmään tyypillisen suuren
   konesalihankkeen kustannusrakenteen mukaan:
   - IT-laitteet (palvelimet, verkkolaitteet, GPU:t) - 75 %
   - Talonrakennus (konesalirakennukset) - 10 %
   - Talotekniikka-/koneasennus (sähkö, LVI, jäähdytys) - 10 %
   - Maa- ja vesirakentaminen (tontti, liittymät, infra) - 5 %
   - Vuosijakauma 2027/2028: oletus 50/50.

2. **Kotimaisen arvonlisäyksen kertoimet** (`oletukset.py`): kullekin
   toimialalle kerroin, joka kuvaa kuinka moni sentti eurosta jää
   Suomen BKT:hen (arvonlisäyksenä) suoran ja epäsuoran
   (alihankintaketjun) vaikutuksen kautta, tuontivuodolla oikaistuna.
   Rakentamisessa kerroin on korkea (~0,6, koska työ, moni materiaali ja
   koneiden käyttö on kotimaista), IT-laitteissa hyvin matala (~0,15, koska
   Suomessa ei juuri valmisteta palvelimia tai verkkolaitteita - lähes koko
   hinta valuu tuontiin, kotimaahan jää lähinnä tukkukauppa- ja
   asennusmarginaali).

3. **Laskenta** (`laske_vaikutus.py`): shokki x kerroin summattuna
   toimialoittain ja vuosittain.

4. **Täysi panos-tuotosmalli valmiina käytettäväksi** (`malli.py`): jos/kun
   käytössä on oikea Tilastokeskuksen tarjonta- ja käyttötaulukoista laskettu
   toimialoittainen kerroinmatriisi A (vain kotimaiset välituotepanokset) ja
   arvonlisäyskertoimet, `malli.py` ratkaisee Leontief-mallin
   `x = (I - A)^-1 * d` ja laskee siitä tarkan BKT-vaikutuksen. Tämä ottaa
   oletukset.py:n yksinkertaista kerroinmallia paremmin huomioon myös
   toimialojen väliset epäsuorat kytkennät (esim. rakennusteollisuuden
   panokset metalliteollisuudesta).

5. **Tilastokeskuksen data** (`hae_tilastokeskus.py`): valmis apufunktio
   PxWeb-rajapinnan JSON-stat2-kyselyihin.

## Miksi tulos on vain suuruusluokka-arvio

- **Ei pääsyä Tilastokeskuksen rajapintaan tässä istunnossa.** Tämän
  hiekkalaatikkoympäristön ulosmenevä verkkoliikenne on rajattu, eikä
  `pxdata.stat.fi` ollut tavoitettavissa (yhdyskäytävä palautti HTTP 403).
  Siksi arvonlisäyskertoimet (0,15 / 0,60 / 0,45 / 0,62) ovat kirjallisuuteen
  ja yleiseen toimialarakenteeseen perustuvia arvioita, **eivät**
  Tilastokeskuksen tarjonta- ja käyttötaulukoista laskettuja tarkkoja
  kertoimia. Kun koodi ajetaan ympäristössä, jossa on internet-yhteys, se
  voidaan päivittää hakemaan oikeat kertoimet - ks. "Näin jatkat" alla.
- **Investoinnin toimialajakoa ei ole julkaistu.** 50/20/20/10-jako on oma
  arvio tyypillisestä konesalihankkeen kustannusrakenteesta, ei Googlen
  ilmoittama luku.
- **Malli on ns. Type I -malli**: se sisältää suorat ja epäsuorat
  (alihankintaketjun) vaikutukset, mutta ei ns. indusoituja vaikutuksia
  (rakennustyöläisten palkkojen kulutuksesta syntyvää lisäkysyntää muualla
  taloudessa). Todellinen kokonaisvaikutus on siis todennäköisesti tätä
  hieman suurempi.
- **Vain rakennusvaiheen kertaluonteinen vaikutus.** Laskelma koskee
  investoinnin (capex) vaikutusta 2027-2028. Se ei sisällä konesalin
  käytönaikaisia, toistuvia vaikutuksia (sähkönosto, ylläpitohenkilöstö,
  kiinteistöverot), jotka jatkuisivat investoinnin valmistumisen jälkeen.
- **Ei kapasiteettirajoitteita.** Malli ei ota huomioon, syrjäyttääkö näin
  suuri, lyhyessä ajassa toteutuva rakennusinvestointi muuta rakentamista
  (esim. jos rakennusalan työvoima on jo täystyöllistetty).

## Herkkyys oletuksille

Implisiittinen kokonaiskerroin (BKT-vaikutus / investointi) riippuu
voimakkaasti IT-laitteiden osuudesta, koska niiden kerroin on niin paljon
muita matalampi:

| IT-laitteiden osuus | Implisiittinen kokonaiskerroin | BKT-vaikutus (13 mrd. e) |
|---|---|---|
| 50 % | ~0,35 | ~4,5 mrd. e |
| 60 % | ~0,31 | ~4,0 mrd. e |
| 75 % (nykyinen oletus) | ~0,25 | ~3,2 mrd. e |
| 90 % | ~0,19 | ~2,5 mrd. e |

Voit testata muita jakaumia muokkaamalla `oletukset.py`:n
`TOIMIALAOSUUDET`-sanakirjaa ja ajamalla `laske_vaikutus.py` uudelleen.

## Näin jatkat tarkemmalla datalla

1. Etsi selaimella Tilastokeskuksen PxWeb-palvelusta
   (`pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/`) kansantalouden tilinpidon
   kohdasta oikea tarjonta- ja käyttötaulukko / panos-tuotostaulukko
   (uusin saatavilla oleva vuosi).
2. Aseta taulukon rajapinta-URL `hae_tilastokeskus.py`:n
   `TAULUKON_URL`-muuttujaan.
3. Hae taulukon metatiedot (`hae_taulukon_metatiedot`) selvittääksesi
   toimialakoodit ja muuttujat, rakenna kysely ja hae data
   (`hae_pxweb_data`).
4. Muodosta taulukoista tekninen kerroinmatriisi A (vain kotimaiset
   välituotepanokset suhteessa tuotokseen) ja arvonlisäyskertoimet
   toimialoittain.
5. Syötä ne `malli.py`:n `value_added_impact(A, arvonlisayskertoimet, d)`
   -funktioon `oletukset.py`:n kysyntäshokkivektorin (`d`) kanssa - saat
   tarkan, tuontivuodosta puhdistetun BKT-vaikutuksen.

## Tiedostot

- `oletukset.py` - investoinnin toimiala- ja vuosijakauma sekä
  arvonlisäyskertoimet (muokattavat lähtöoletukset)
- `malli.py` - Leontief-panos-tuotoslaskenta (puhdas Python, ei
  ulkoisia riippuvuuksia)
- `hae_tilastokeskus.py` - PxWeb-rajapinnan hakufunktiot
- `laske_vaikutus.py` - pääskripti, tulostaa BKT-vaikutuksen
  vuosittain ja toimialoittain (`python3 laske_vaikutus.py`)
