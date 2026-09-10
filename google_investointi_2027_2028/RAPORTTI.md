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
joka tekee juuri tämän jaottelun. Nykyisillä oletuksilla (`oletukset.R`,
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
`oletukset.R`-päivityksessä - IT-laitteiden kotimaisen arvonlisäyksen
kerroin on toimialoista matalin.)

## Menetelmä (mitä koodi tekee)

1. **Kysyntäshokit toimialoittain** (`oletukset.R`): 13 mrd. euron
   investointi jaetaan neljään toimialaryhmään tyypillisen suuren
   konesalihankkeen kustannusrakenteen mukaan:
   - IT-laitteet (palvelimet, verkkolaitteet, GPU:t) - 75 %
   - Talonrakennus (konesalirakennukset) - 10 %
   - Talotekniikka-/koneasennus (sähkö, LVI, jäähdytys) - 10 %
   - Maa- ja vesirakentaminen (tontti, liittymät, infra) - 5 %
   - Vuosijakauma 2027/2028: oletus 50/50.

2. **Kotimaisen arvonlisäyksen kertoimet** (`oletukset.R`): kullekin
   toimialalle kerroin, joka kuvaa kuinka moni sentti eurosta jää
   Suomen BKT:hen (arvonlisäyksenä) suoran ja epäsuoran
   (alihankintaketjun) vaikutuksen kautta, tuontivuodolla oikaistuna.
   Rakentamisessa kerroin on korkea (~0,6, koska työ, moni materiaali ja
   koneiden käyttö on kotimaista), IT-laitteissa hyvin matala (~0,15, koska
   Suomessa ei juuri valmisteta palvelimia tai verkkolaitteita - lähes koko
   hinta valuu tuontiin, kotimaahan jää lähinnä tukkukauppa- ja
   asennusmarginaali).

3. **Laskenta** (`laske_vaikutus.R`): shokki x kerroin summattuna
   toimialoittain ja vuosittain.

4. **Täysi panos-tuotosmalli valmiina käytettäväksi** (`malli.R`): jos/kun
   käytössä on oikea Tilastokeskuksen tarjonta- ja käyttötaulukoista laskettu
   toimialoittainen kerroinmatriisi A (vain kotimaiset välituotepanokset) ja
   arvonlisäyskertoimet, `malli.R` ratkaisee Leontief-mallin
   `x = (I - A)^-1 %*% d` (base R:n `solve()`-funktiolla) ja laskee siitä
   tarkan BKT-vaikutuksen. Tämä ottaa oletukset.R:n yksinkertaista
   kerroinmallia paremmin huomioon myös toimialojen väliset epäsuorat
   kytkennät (esim. rakennusteollisuuden panokset metalliteollisuudesta).

5. **Tilastokeskuksen data** (`hae_tilastokeskus.R`): valmis apufunktio
   PxWeb-rajapinnan JSON-kyselyihin (`httr`- ja `jsonlite`-paketeilla).

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

## Lähteet ja taustaoletusten perustelut

**Rehellisyyshuomio ensin:** koska tämän istunnon verkkoyhteys oli estetty (ks.
edellä), en pystynyt hakemaan enkä tarkistamaan täsmällisiä lähdeviitteitä
(tekijä, julkaisuvuosi, sivunumero) käytetyille kertoimille. Alla kerrotaan,
minkä tyyppisiin - oikeasti olemassa oleviin - lähteisiin arvio perustuu, ja
mistä ne kannattaa itse tarkistaa ennen virallista käyttöä. **Älä käytä tätä
listaa sellaisenaan tarkistettuna lähdeluettelona** - se on kartta siitä missä
oikeat luvut sijaitsevat, ei sitaatti niistä.

**Arvonlisäys- ja tuontikertoimet (0,15 / 0,60 / 0,45 / 0,62):**
- Ensisijainen, oikea lähde: Tilastokeskuksen kansantalouden tilinpito -
  tarjonta- ja käyttötaulukot / panos-tuotostaulukot (pxdata.stat.fi,
  StatFin-tietokanta). Näistä toimialoittainen tuotos, välituotekäyttö,
  arvonlisäys ja tuonti saadaan tarkasti, ja niistä lasketaan malli.R:n
  Leontief-laskentaan tarvittava kerroinmatriisi.
- Yleistä tietoa toimialojen kotimaisuusasteesta ja investointien
  kerrannaisvaikutuksista julkaisevat mm. Elinkeinoelämän tutkimuslaitos
  (Etla), Valtion taloudellinen tutkimuskeskus (VATT) ja Suomen Pankki
  talouskatsauksissaan.
- Konesalihankkeiden tyypillisestä kustannusrakenteesta (IT-laitteiden suuri
  osuus rakennus- ja talotekniikkaosuuteen nähden) julkaisevat markkina-
  analyyseja mm. Uptime Institute, JLL, CBRE ja Synergy Research Group.

**Työllisyyskertoimet (0 / 6,5 / 5,5 / 5,0 htv/milj. e):**
- Ensisijainen, oikea lähde: Tilastokeskuksen toimialoittainen
  työllisyys-panos-tuotostaulukko (sama tietokanta kuin yllä), josta saisi
  tarkat htv/tuotanto-suhteet toimialoittain.
- Rakentamisen työllisyyskertoimista julkaisee arvioita mm. Rakennusteollisuus
  RT suhdanne- ja työllisyyskatsauksissaan.
- IT-laitteiden kerroin on asetettu nollaan tietoisena rajauksena (ei
  kirjallisuudesta johdettu luku): ks. "Työllisyysvaikutukset"-kohta.

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

Voit testata muita jakaumia muokkaamalla `oletukset.R`:n
`TOIMIALAOSUUDET`-vektoria ja ajamalla `laske_vaikutus.R` uudelleen.

## Työllisyysvaikutukset

Samalla toimialoittaisella kysyntäshokkimallilla voidaan arvioida karkeasti
myös investoinnin työllisyysvaikutus: arvonlisäyskertoimien sijaan käytetään
toimialoittaisia työllisyyskertoimia (henkilötyövuotta, htv, miljoonaa euroa
kohti - `TYOLLISYYS_KERTOIMET` tiedostossa `oletukset.R`). Nykyisillä
oletuksilla (`laske_vaikutus.R`):

| Vuosi | IT-laitteet | Talonrakennus | Talotekniikka | Maa- ja vesirak. | Yhteensä |
|---|---|---|---|---|---|
| 2027 | 0 htv (rajattu pois) | 4 225 htv | 3 575 htv | 1 625 htv | **9 425 htv** |
| 2028 | 0 htv (rajattu pois) | 4 225 htv | 3 575 htv | 1 625 htv | **9 425 htv** |
| **Yhteensä** | | | | | **~18 850 htv** |

Karkeasti siis **n. 9 425 henkilötyövuotta vuodessa** (yhteensä n. 18 850 htv
kahden vuoden aikana), yksinomaan rakennus- ja asennustyötä.

**Rajaus: vain Suomeen kohdistuva työvoiman kysyntä - IT-laitteet
kokonaan pois.** Luvut kuvaavat tarkoituksella yksinomaan sitä työvoiman
kysyntää, joka syntyy ja on tehtävä Suomessa - eivät investoinnin globaalia
työllisyysjalanjälkeä. Käytännössä:

- **IT-laitteet on rajattu tarkastelusta kokonaan pois (kerroin = 0).**
  Palvelimien, verkkolaitteiden ja GPU:iden valmistus tapahtuu ulkomailla
  (mm. Taiwanissa, Yhdysvalloissa, Etelä-Koreassa), joten se ei kasvata
  Suomen työllisyyttä eikä kuulu tähän tarkasteluun. Myös jäljelle jäävä,
  pienempi kotimainen logistiikka-, tukkukauppa- ja asennustyön osuus on
  tietoisesti jätetty pois, jotta tarkastelu rajautuu selkeästi ja yksin-
  omaan Suomeen kohdistuvaan työhön - tämä tekee arviosta hieman varovaisen
  (todellinen Suomeen kohdistuva htv-määrä voi olla marginaalisesti tätä
  suurempi). Jos investoinnin *koko* globaali työllisyysvaikutus (valmistus
  mukaan lukien) haluttaisiin arvioida, tarvittaisiin täysin eri,
  kansainvälinen malli ja ulkomaiden tilastoja - sitä ei ole tehty tässä.
- **Rakentaminen ja asennus (talonrakennus, talotekniikka-/koneasennus,
  maa- ja vesirakentaminen) lasketaan täysimääräisenä**, koska työmaat
  sijaitsevat Suomessa - kyse on Suomeen kohdistuvasta työvoiman
  kysynnästä riippumatta yksittäisten työntekijöiden kansallisuudesta
  (esim. EU:sta lähetetyt työntekijät lasketaan mukaan, koska työ tehdään
  Suomessa).
- Tuontipanosten (esim. rakennusmateriaalien) valmistukseen ulkomailla
  liittyvä työvoima on samoin jätetty pois, samasta syystä kuin BKT-mallissa
  tuontivuoto on netotettu pois arvonlisäyskertoimista.

Huomioita:

- **Henkilötyövuosi (htv) ei ole sama asia kuin pysyvä työpaikka.** Yksi htv
  voi jakautua usealle henkilölle osa-aikaisena tai lyhytkestoisena työnä -
  luku ei tarkoita 18 850 uutta pysyvää työntekijää.
- **Vain rakennusvaiheen tilapäinen vaikutus.** Työ liittyy 2027-2028
  rakennus- ja asennustöihin; suurin osa siitä päättyy konesalin
  valmistuttua.
- **Konesalin käytönaikainen, pysyvä henkilöstö on tätä paljon pienempi.**
  Suurten konesalien pysyvä ylläpito-, turvallisuus- ja tekninen henkilöstö
  tunnetaan yleisesti suhteellisen pieneksi investoinnin kokoon nähden -
  tyypillisesti kymmeniä tai muutamia satoja työntekijöitä yhtä suurta
  konesalia kohti, ei tuhansia. Tätä pysyvää vaikutusta ei ole tässä
  arvioitu numeerisesti, koska luotettavaa, tarkistettua lukua Googlen
  Suomen-laitosten henkilöstösuunnitelmista ei ollut tämän istunnon aikana
  saatavilla.
- **Sama Type I -rajoitus kuin BKT-mallissa:** ei indusoitua kulutuskysyntää
  eikä kapasiteettirajoitteita (esim. jos rakennusala on jo lähellä
  täystyöllisyyttä, shokki voisi nostaa palkkoja/hintoja työllisyyden kasvun
  sijaan).

Vertailun vuoksi: Suomen koko rakennusala on työllistänyt viime vuosina
suuruusluokkaa 170 000-200 000 henkilöä (karkea, tässä istunnossa
tarkistamaton arvio). N. 9 425 htv/vuosi vastaisi siis karkeasti n. 5 %
koko alan työvoimasta - merkittävä yksittäiselle hankkeelle, mutta
jakautuisi todennäköisesti usealle vuodelle ja monelle eri alihankkijalle eri
puolilla Suomea, ei yhdelle työmaalle.

## Näin jatkat tarkemmalla datalla

1. Etsi selaimella Tilastokeskuksen PxWeb-palvelusta
   (`pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/`) kansantalouden tilinpidon
   kohdasta oikea tarjonta- ja käyttötaulukko / panos-tuotostaulukko
   (uusin saatavilla oleva vuosi).
2. Aseta taulukon rajapinta-URL `hae_tilastokeskus.R`:n
   `TAULUKON_URL`-muuttujaan.
3. Asenna tarvittavat R-paketit: `install.packages(c("httr", "jsonlite"))`.
4. Hae taulukon metatiedot (`hae_taulukon_metatiedot`) selvittääksesi
   toimialakoodit ja muuttujat, rakenna kysely ja hae data
   (`hae_pxweb_data`).
5. Muodosta taulukoista tekninen kerroinmatriisi A (vain kotimaiset
   välituotepanokset suhteessa tuotokseen) ja arvonlisäyskertoimet
   toimialoittain.
6. Syötä ne `malli.R`:n `arvonlisays_vaikutus(A, arvonlisayskertoimet, d)`
   -funktioon `oletukset.R`:n kysyntäshokkivektorin (`d`) kanssa - saat
   tarkan, tuontivuodosta puhdistetun BKT-vaikutuksen.

## Tiedostot

- `oletukset.R` - investoinnin toimiala- ja vuosijakauma sekä
  arvonlisäys- ja työllisyyskertoimet (muokattavat lähtöoletukset)
- `malli.R` - Leontief-panos-tuotoslaskenta (base R, ei
  ulkoisia riippuvuuksia)
- `hae_tilastokeskus.R` - PxWeb-rajapinnan hakufunktiot (riippuvuudet:
  `httr`, `jsonlite`)
- `laske_vaikutus.R` - pääskripti, tulostaa sekä BKT- että
  työllisyysvaikutuksen vuosittain ja toimialoittain
  (`Rscript laske_vaikutus.R`)
