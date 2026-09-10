# Googlen 13 mrd. euron datakeskusinvestoinnin (2027-2028) BKT- ja työllisyysvaikutus

## Kysymys

Kuinka paljon Googlen ilmoittama noin 13 miljardin euron investointi
datakeskuksiin Suomessa vuosina 2027-2028 kasvattaa Suomen BKT:ta - ja
millainen työllisyysvaikutus sillä olisi?

## Lyhyt vastaus

Suoraan investoinnin euromäärästä ei voi laskea BKT-vaikutusta - 13 mrd. euroa
on **kysyntä** (tilaukset eri toimialoilta), ei **arvonlisäys** (BKT). Osa
rahasta valuu tuontiin (etenkin palvelimet ja verkkolaitteet, jotka ovat
lähes kokonaan ulkomaista valmistusta), ja loppuosa synnyttää kotimaista
arvonlisäystä ja työllisyyttä sekä suoraan (rakennus- ja asennustyö) että
epäsuorasti (alihankintaketjut: sora, betoni, sähkötarvikkeet, kuljetukset
jne.).

Tässä repossa (`google_investointi_2027_2028/`) on toteutettu laskentaputki,
joka tekee juuri tämän jaottelun **Tilastokeskuksen oikealla panos-tuotos-
datalla** (rakentamisen osalta - ks. "Menetelmä" alla, miksi IT-laitteet on
edelleen karkea arvio). Tulos:

| Vuosi | Investointi | BKT-vaikutus | Työllisyysvaikutus |
|---|---|---|---|
| 2027 | 6,50 mrd. e | **~1,91 mrd. e** | **~16 900 työllistä** |
| 2028 | 6,50 mrd. e | **~1,91 mrd. e** | **~16 900 työllistä** |
| **Yhteensä** | **13,00 mrd. e** | **~3,82 mrd. e** | **~33 900 työllistä** |

Karkeasti siis **noin 29 %** investoinnin euromäärästä (n. 3,8 mrd. e kahden
vuoden aikana, n. 1,9 mrd. e/vuosi) näkyisi Suomen BKT:ssä lisäyksenä
rakennusvaiheen aikana, ja se työllistäisi karkeasti **~33 900 henkilöä**
(rakennusvaiheen tilapäinen vaikutus, ei pysyviä työpaikkoja - ks.
"Työllisyysvaikutukset" alla). Loput valuvat tuontiin (etenkin IT-laitteet)
tai ulkomaisiin voittoihin.

Vertailun vuoksi: Suomen BKT oli v. 2024 noin 280 mrd. euroa, joten n. 1,9
mrd. e/vuosi vastaisi karkeasti n. 0,7 prosenttiyksikköä yhden vuoden
BKT:sta.

## Menetelmä (mitä koodi tekee)

**Hybridimalli: rakentaminen oikealla datalla, IT-laitteet karkealla
arviolla.** Tähän istuntoon on ladattu kaksi oikeaa Tilastokeskuksen
taulukkoa (`data/panoskertoimet_14yq.csv`, `data/kayttotaulukko_14yn.csv` -
ks. "Tiedot ja lähteet" alla), ja `laske_vaikutus.R` käyttää niitä
automaattisesti - mutta **vain rakentamisen osalta**. Tähän on tekninen syy,
selitetty kohdassa "Miksi IT-laitteet ei käytä oikeaa Leontief-mallia" alla.

1. **Kysyntäshokit toimialoittain** (`oletukset.R`): 13 mrd. euron
   investointi jaetaan neljään toimialaryhmään tyypillisen suuren
   konesalihankkeen kustannusrakenteen mukaan:
   - IT-laitteet (palvelimet, verkkolaitteet, GPU:t) - 75 %
   - Talonrakennus (konesalirakennukset) - 10 %
   - Talotekniikka-/koneasennus (sähkö, LVI, jäähdytys) - 10 %
   - Maa- ja vesirakentaminen (tontti, liittymät, infra) - 5 %
   - Vuosijakauma 2027/2028: oletus 50/50.
   - Nämä osuudet ovat oma arvio - Google ei ole julkaissut jakoa.

2. **Rakentaminen (25 % investoinnista): oikea Leontief-malli.**
   Talonrakennus, maa- ja vesirakentaminen sekä talotekniikka-/koneasennus
   kohdistetaan taulukoiden toimialaan **"F Rakentaminen (41-43)"** (näitä
   kolmea omaa ryhmäämme ei voi tällä toimialaluokituksella - 63 toimialaa -
   erottaa toisistaan, ks. alla). Malli ratkaisee täyden Leontief-yhtälön
   `x = (I - A)^-1 d` 63 toimialan tarkkuudella (`malli.R`:
   `leontief_tuotanto()`, base R:n `solve()`-funktiolla) käyttäen taulukon
   14yq **kotimaista** teknistä kerroinmatriisia A - eli vaikutus leviää
   koko kotimaiseen alihankintaverkostoon (esim. rakennusteollisuuden
   panokset metalli- ja kuljetusalalta), ei vain suoraan rakennustoimialalle.
   BKT-vaikutus lasketaan kertomalla tuloksena saatu kokonaistuotanto
   taulukon 14yq antamalla **arvonlisäys/tuotos-kertoimella** (rivi
   "B1GPH Bruttoarvonlisäys perushintaan" - valmiiksi laskettu, ei tarvitse
   johtaa itse), ja työllisyysvaikutus taulukosta 14yn lasketulla
   **työllisyys/tuotos-kertoimella** (rivit "P1R Tuotos perushintaan" ja
   "E1 Työlliset, kotimaa (1000 henkeä)").

3. **IT-laitteet (75 % investoinnista): karkea arvio.** Lasketaan
   `oletukset.R`:n kirjallisuuteen pohjautuvilla kertoimilla
   (`ARVONLISAYS_KERTOIMET["it_laitteet"]` = 0,15 BKT:lle,
   `TYOLLISYYS_KERTOIMET["it_laitteet"]` = 0,4 htv/milj. e
   työllisyydelle) - ei taulukoiden 14yq/14yn kautta. Katso seuraava kohta
   miksi.

### Miksi IT-laitteet ei käytä oikeaa Leontief-mallia

Tätä kokeiltiin tämän istunnon aikana, ja se paljasti tärkeän
metodologisen ongelman: taulukko 14yq:n tekninen kerroinmatriisi A on
vahvistetusti **kotimainen** (käyttäjän vahvistama). Jos IT-laitteiden koko
kysyntäshokki (n. 4,9 mrd. e/vuosi) syötettäisiin sellaisenaan malliin
kohdistettuna toimialalle "26 Tietokoneiden sekä elektronisten ja optisten
tuotteiden valmistus", malli olettaisi **virheellisesti**, että koko summa
kysyy lisää Suomen kotimaista tietokonevalmistusta - vaikka todellisuudessa
Google ostaa palvelimensa ja verkkolaitteensa lähes kokonaan ulkomailta
(Taiwan, USA, Etelä-Korea ym.), eikä tämä kysyntä juuri kohdistu
suomalaiseen toimialaan 26 lainkaan.

Kokeilimme tätä: se nosti koko investoinnin implisiittisen BKT-kertoimen
0,59:ään - epäuskottavan korkea luku tuontivaltaiselle
laitehankinnalle, ja selvästi ylimitoitettu. Oikea tapa korjata tämä
vaatisi toimialakohtaista (tuote 26:n) **tuontiosuustietoa**, jotta
kysyntäshokin kotimainen osuus voitaisiin netottaa pois ennen
Leontief-laskentaa - tätä tietoa ei ollut ladatuissa taulukoissa
saatavilla tuotetasolla. Siksi IT-laitteet lasketaan turvallisemmin
`oletukset.R`:n karkealla, tuontivuodon jo huomioivalla kertoimella, joka
on suunniteltu nimenomaan kuvaamaan vain Suomessa syntyvää
asennus-/käyttöönottotyötä ja arvonlisäystä (ks. myös
"Työllisyysvaikutukset").

Rakentamisen kolme ryhmää sen sijaan ovat lähes kokonaan kotimaista
palvelutuotantoa (rakennustyömaat sijaitsevat Suomessa), joten niille
täysi Leontief-malli on perusteltu ja luotettava.

## Miksi tulos on silti vain osittain tarkka

- **IT-laitteet-osuus (75 % investoinnista) on edelleen karkea arvio.**
  Kertoimet (0,15 BKT / 0,4 htv-milj. e) ovat kirjallisuuteen ja yleiseen
  toimialarakenteeseen perustuvia arvioita, eivät taulukoista laskettuja -
  ks. yllä miksi.
- **Investoinnin toimialajakoa (75/10/10/5) ei ole julkaistu.** Se on oma
  arvio tyypillisestä konesalihankkeen kustannusrakenteesta, ei Googlen
  ilmoittama luku.
- **Rakentamisen kolmea alaryhmää ei voi erottaa oikealla datalla.** 63
  toimialan luokituksessa koko rakentaminen (talonrakennus F41, maa- ja
  vesirakentaminen F42, erikoistunut rakennustoiminta F43) on yhdistetty
  yhdeksi "F Rakentaminen"-toimialaksi. Tämä ei haittaa
  kokonaissummaa, mutta estää F41/F42/F43-tason erittelyn.
- **Malli on ns. Type I -malli**: suorat ja epäsuorat (alihankintaketjun)
  vaikutukset, mutta ei indusoituja vaikutuksia (rakennustyöläisten
  palkkojen kulutuksesta syntyvää lisäkysyntää muualla taloudessa).
  Todellinen kokonaisvaikutus on siis todennäköisesti hieman suurempi kuin
  tässä esitetty.
- **Vain rakennusvaiheen kertaluonteinen vaikutus.** Laskelma koskee
  investoinnin (capex) vaikutusta 2027-2028, ei konesalin käytönaikaisia,
  toistuvia vaikutuksia (sähkönosto, ylläpitohenkilöstö, kiinteistöverot).
- **Ei kapasiteettirajoitteita.** Malli ei ota huomioon, syrjäyttääkö näin
  suuri, lyhyessä ajassa toteutuva rakennusinvestointi muuta rakentamista
  (esim. jos rakennusalan työvoima on jo täystyöllistetty).
- **Tuotos- ja arvonlisäysluvut ovat vuodelta 2023** (taulukoiden tuorein
  saatavilla oleva vuosi tätä kirjoitettaessa) - ei vuosilta 2027-2028,
  joten ne eivät huomioi mahdollisia rakenteellisia muutoksia talouden
  toimialarakenteessa siihen mennessä.

## Tiedot ja lähteet

**Käytetyt taulukot** (käyttäjän lataamat, viety Tilastokeskuksen
PxWeb-palvelusta pxdata.stat.fi:stä, tallennettu `data/`-kansioon):

- **`data/panoskertoimet_14yq.csv`** - taulukko 14yq "Tuotoksen
  panoskertoimet" (StatFin__pt/14yq.px): toimialoittainen (63 toimialaa)
  tekninen kerroinmatriisi A, **vahvistetusti kotimainen** (käyttäjän
  vahvistama). Sisältää myös valmiin rivin "B1GPH Bruttoarvonlisäys
  perushintaan" (arvonlisäys/tuotos-kerroin suoraan).
- **`data/kayttotaulukko_14yn.csv`** - taulukko 14yn "Panos-tuotostaulukko
  perushintaan" (StatFin__pt/14yn.px): käytetään tästä rivit "P1R Tuotos
  perushintaan" (toimialan tuotos, milj. e) ja "E1 Työlliset, kotimaa
  (1000 henkeä)" (työllisyys), joista lasketaan työllisyyskerroin.
- Molemmat taulukot kattavat vuodet 2021-2023; laskennassa käytetään
  vuotta 2023 (`vuoden_data_oletus` tiedostossa `lataa_oikea_data.R`).

**IT-laitteiden karkeat kertoimet (0,15 BKT / 0,4 htv-milj. e) perustuvat**
sen sijaan yleiseen toimialarakennetietoon (Suomessa ei juuri ole
palvelin-/verkkolaitevalmistusta) ja konesalihankkeiden kustannusrakennetta
käsitteleviin markkina-analyyseihin (mm. Uptime Institute, JLL, CBRE,
Synergy Research Group) - näitä ei ole tarkistettu tässä istunnossa yhtä
täsmällisesti kuin edellä mainittuja Tilastokeskus-taulukoita, koska ne
ovat oma, kirjallisuuteen pohjautuva arvio, ei ladattu tilasto.

## Herkkyys IT-laitteiden osuudelle

Koska rakentamisen (25 %:n osuuden) implisiittinen kokonaiskerroin on nyt
oikealla datalla laskettu (~0,725 - korkeampi kuin aiempi karkea arvio,
koska täysi Leontief-malli vangitsee koko alihankintaverkoston, ei vain
suoraa vaikutusta), IT-laitteiden osuus investoinnista vaikuttaa
tulokseen voimakkaasti:

| IT-laitteiden osuus | Implisiittinen kokonaiskerroin | BKT-vaikutus (13 mrd. e) |
|---|---|---|
| 50 % | ~0,44 | ~5,7 mrd. e |
| 60 % | ~0,38 | ~4,9 mrd. e |
| 75 % (nykyinen oletus) | ~0,29 | ~3,8 mrd. e |
| 90 % | ~0,21 | ~2,7 mrd. e |

Voit testata muita jakaumia muokkaamalla `oletukset.R`:n
`TOIMIALAOSUUDET`-vektoria ja ajamalla `laske_vaikutus.R` uudelleen.

## Työllisyysvaikutukset

Sama hybridimalli (oikea data rakentamiselle, karkea arvio IT-laitteille)
antaa työllisyysvaikutuksen. **Yksikkö on tässä työllisten määrä**
(Tilastokeskuksen "E1 Työlliset"-rivi rakentamiselle, henkilötyövuosi-
approksimaatio IT-laitteille) - ei tarkalleen henkilötyövuosi (htv), koska
osa-aikaiset lasketaan Tilastokeskuksen luvussa yhtenä työllisenä.

| Vuosi | Rakentaminen (oikea data) | IT-laitteet (karkea arvio) | Yhteensä |
|---|---|---|---|
| 2027 | ~14 978 | ~1 950 | **~16 928** |
| 2028 | ~14 978 | ~1 950 | **~16 928** |
| **Yhteensä** | ~29 956 | ~3 900 | **~33 856** |

**Rajaus: vain Suomeen kohdistuva työvoiman kysyntä.** Luvut kuvaavat
tarkoituksella yksinomaan sitä työvoiman kysyntää, joka syntyy ja on
tehtävä Suomessa - eivät investoinnin globaalia työllisyysjalanjälkeä
(esim. palvelinvalmistuksen työvoima Aasiassa ei sisälly tähän).

Huomioita:

- **Rakentamisen luku (~29 956) on nyt oikeasta Tilastokeskus-datasta**,
  Leontief-mallin kautta - se sisältää koko kotimaisen alihankintaketjun
  työllisyysvaikutuksen (esim. rakennusmateriaalien kotimainen tuotanto),
  ei vain suoraa rakennustyömaan työvoimaa. Tämä selittää, miksi luku on
  selvästi korkeampi kuin aiemman karkean arvion (jossa koko rakentamiselle
  oli ~10 425 htv/vuosi).
- **IT-laitteiden luku (~1 950/vuosi) on edelleen karkea arvio** - vain
  Suomessa tehtävä asennus-/käyttöönottotyö, ei laitevalmistus eikä yleinen
  tukkukauppa/logistiikka.
- **Työllisten määrä ≠ pysyvä työpaikka.** Yksi työllinen tässä mielessä
  voi olla osa-aikainen tai lyhytkestoinen - luku ei tarkoita 33 856 uutta
  pysyvää työntekijää.
- **Vain rakennusvaiheen tilapäinen vaikutus.** Työ liittyy 2027-2028
  rakennus- ja asennustöihin; suurin osa siitä päättyy konesalin
  valmistuttua.
- **Konesalin käytönaikainen, pysyvä henkilöstö on tätä paljon pienempi.**
  Suurten konesalien pysyvä ylläpito-, turvallisuus- ja tekninen henkilöstö
  tunnetaan yleisesti suhteellisen pieneksi investoinnin kokoon nähden -
  tyypillisesti kymmeniä tai muutamia satoja työntekijöitä yhtä suurta
  konesalia kohti, ei tuhansia. Tätä pysyvää vaikutusta ei ole tässä
  arvioitu numeerisesti, koska luotettavaa, tarkistettua lukua Googlen
  Suomen-laitosten henkilöstösuunnitelmista ei ollut saatavilla.
- **Sama Type I -rajoitus kuin BKT-mallissa:** ei indusoitua kulutuskysyntää
  eikä kapasiteettirajoitteita (esim. jos rakennusala on jo lähellä
  täystyöllisyyttä, shokki voisi nostaa palkkoja/hintoja työllisyyden kasvun
  sijaan).

Vertailun vuoksi: Suomen koko rakennusala on työllistänyt viime vuosina
suuruusluokkaa 170 000-200 000 henkilöä (karkea, tässä istunnossa
tarkistamaton arvio). N. 16 900 työllistä/vuosi vastaisi siis karkeasti
n. 9 % koko alan työvoimasta - merkittävä yksittäiselle hankkeelle, mutta
jakautuisi todennäköisesti usealle vuodelle ja monelle eri alihankkijalle
eri puolilla Suomea, ei yhdelle työmaalle.

## Näin parantaisit mallia edelleen

1. **IT-laitteiden oikea käsittely vaatisi tuotetason tuontiosuustiedon**
   (esim. Tilastokeskuksen tarjontataulukko, josta näkisi kuinka suuri osa
   tietokonelaitteiden kotimaisesta tarjonnasta on tuontia vs. kotimaista
   tuotantoa). Sillä voisi netottaa IT-laitteet-shokin kotimaisen osuuden
   oikein ennen Leontief-laskentaa, sen sijaan että käytetään karkeaa
   kertoimen arviota.
2. **Uudempi data-vuosi**, kun Tilastokeskus julkaisee 2024/2025-vuoden
   panos-tuotostaulukot.
3. **F41/F42/F43-erittely** vaatisi hienojakoisemman toimialaluokituksen
   käyttävän taulukon (jos Tilastokeskus julkaisee sellaisen) - nykyinen
   63 toimialan luokitus ei erottele niitä.
4. Voit vaihtaa laskentavuotta muuttamalla `lataa_oikea_data.R`:n
   `vuoden_data_oletus`-muuttujaa (esim. `"2021"` tai `"2022"`) ja
   ajamalla `laske_vaikutus.R` uudelleen - taulukot kattavat 2021-2023.

## Tiedostot

- `oletukset.R` - investoinnin toimiala- ja vuosijakauma, IT-laitteiden
  karkeat arvonlisäys-/työllisyyskertoimet, sekä `TOIMIALA_KOODIT_14Y`-
  vastaavuus (oma toimialaryhmä <-> taulukon toimiala) oikeaa dataa varten
- `malli.R` - Leontief-panos-tuotoslaskenta (base R:n `solve()`, ei
  ulkoisia riippuvuuksia): `leontief_tuotanto()` ratkaisee
  `x = (I-A)^-1 d`
- `lataa_oikea_data.R` - lukee `data/`-kansion CSV-tiedostot
  (`panoskertoimet_14yq.csv`, `kayttotaulukko_14yn.csv`), rakentaa
  A-matriisin ja arvonlisäys-/työllisyyskertoimet, ja kysyntävektorin
  oikeassa toimialaluokituksessa
- `data/` - Tilastokeskuksesta ladatut CSV-tiedostot (ks. `data/README.md`)
- `hae_tilastokeskus.R` - PxWeb-rajapinnan hakufunktiot elävää hakua varten
  (riippuvuudet: `httr`, `jsonlite`) - vaihtoehto CSV-tuonnille, jos
  rajapintayhteys on käytettävissä (ei tässä istunnossa)
- `laske_vaikutus.R` - pääskripti: laskee rakentamisen oikealla datalla ja
  IT-laitteet karkealla arviolla, tulostaa BKT- ja työllisyysvaikutuksen
  (`Rscript laske_vaikutus.R`)
