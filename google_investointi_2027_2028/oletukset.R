# Oletukset: Googlen 13 mrd. euron konesaliinvestoinnin (2027-2028)
# jakautuminen toimialoittaisiksi kysyntashokeiksi seka naiden toimialojen
# kotimaisen arvonlisayksen kertoimet.
#
# TARKEAA GOOGLE-INVESTOINNISTA:
# Google ei ole julkaissut investoinnin toimialakohtaista jakoa. Alla olevat
# osuudet ovat arvioita. Muokkaa TOIMIALAOSUUDET- ja VUOSIJAKAUMA-vektoreita,
# jos tarkempaa tietoa investoinnin ajoituksesta tai koostumuksesta on
# saatavilla.
#
# TARKEAA KERTOIMISTA:
# ARVONLISAYS_KERTOIMET-arvot eivat ole Tilastokeskuksen tarjonta- ja
# kayttotaulukoista (panos-tuotostaulukoista) laskettuja tarkkoja kertoimia,
# vaan kirjallisuuteen ja toimialarakenteeseen perustuvia karkeita arvioita.
# Tama johtuu siita, etta tama istunto ei paassyt kasiksi Tilastokeskuksen
# PxWeb-rajapintaan (ks. hae_tilastokeskus.R). Korvaa nama luvut oikeilla,
# taulukoista lasketuilla kertoimilla heti kun rajapintayhteys on
# kaytettavissa - katso laske_vaikutus.R ja malli.R, joissa on valmis
# Leontief-laskenta oikeaa panos-tuotosmatriisia varten.

# Investoinnin kokonaissumma (euroa), 2027-2028 yhteensa
INVESTOINTI_YHTEENSA <- 13000000000

# Vuosijakauma: oletus tasainen 50/50, jos tarkempaa aikataulua ei tiedeta
VUOSIJAKAUMA <- c(
  "2027" = 0.50,
  "2028" = 0.50
)

# Toimialakohtainen osuus investoinnista (osuuksien summa = 1.0)
TOIMIALAOSUUDET <- c(
  # Palvelimet, verkkolaitteet, GPU:t yms. (TOL 26/46) - hyvin tuontivaltainen,
  # Suomessa ei juuri valmisteta vastaavia laitteita
  it_laitteet = 0.75,
  # Konesalirakennukset (TOL F41)
  talonrakennus = 0.10,
  # Sahko-, LVI-, jaahdytys- ja koneasennus (TOL F43 / C33)
  talotekniikka_asennus = 0.10,
  # Tontti, liittymat, tie- ja kaapelityot (TOL F42)
  maa_ja_vesirakentaminen = 0.05
)

stopifnot(abs(sum(TOIMIALAOSUUDET) - 1.0) < 1e-9)
stopifnot(abs(sum(VUOSIJAKAUMA) - 1.0) < 1e-9)

# Kotimaisen arvonlisayksen kertoimet (suora + epasuora vaikutus alihankinta-
# ketjussa, tuontivuodolla oikaistu) toimialoittain. KARKEITA ARVIOITA, ks.
# yllaoleva huomautus.
ARVONLISAYS_KERTOIMET <- c(
  it_laitteet = 0.15,
  talonrakennus = 0.60,
  talotekniikka_asennus = 0.45,
  maa_ja_vesirakentaminen = 0.62
)

# Tyollisyyskertoimet: henkilotyovuosia (htv) miljoonaa tuotantoon kaytettya
# euroa kohti, toimialoittain (suora + epasuora vaikutus alihankintaketjussa).
# Tallennettu tassa yksikossa "htv / euro" (ts. jaettu 1e6:lla), jotta
# laske_vaikutus.R:n yleinen kerroinlaskin (joka kertoo euromaaraisen
# kysyntashokin suoraan kertoimella) toimii samalla tavalla kuin
# ARVONLISAYS_KERTOIMET:n kanssa.
#
# RAJAUS: kertoimet kuvaavat vain SUOMEEN kohdistuvaa tyovoiman kysyntaa
# (tyo joka tehdaan/kysytaan Suomessa), ei investoinnin globaalia
# tyollisyysjalanjalkea. Siksi it_laitteet-kerroin on niin matala: palvelin-
# ja verkkolaitevalmistuksen tyovoima (Taiwan, USA, Etela-Korea ym.) on
# tarkoituksella jatetty kokonaan pois, koska se ei kohdistu Suomeen. Vain
# Suomessa tehtava logistiikka-, tukkukauppa- ja asennustyo lasketaan mukaan.
# Rakentamisen/asennuksen kertoimet taas lasketaan tayspainoisina, koska
# tyomaat sijaitsevat Suomessa - malli ei erottele suomalaisia ja ulkomaisia
# (esim. lahetettyja) tyontekijoita, vain sen missa tyo suoritetaan. Ks.
# RAPORTTI.md:n kohta "Tyollisyysvaikutukset" / "Rajaus: vain Suomeen
# kohdistuva tyovoiman kysynta".
#
# KARKEITA ARVIOITA - ei Tilastokeskuksen tyollisyys-panos-tuotostaulukoista
# laskettuja tarkkoja kertoimia, samasta rajapintarajoitteen syysta kuin
# ARVONLISAYS_KERTOIMET (ks. yllaoleva huomautus ja RAPORTTI.md:n kohdat
# "Lahteet..." ja "Tyollisyysvaikutukset"). Rakentaminen on selvasti
# tyovoimavaltaisempaa kuin tuontivaltaiset IT-laitteet, joissa kotimaahan jaa
# lahinna logistiikka-, tukkukauppa- ja asennustyota.
TYOLLISYYS_KERTOIMET_HTV_PER_MILJ_EUR <- c(
  it_laitteet = 1.0,
  talonrakennus = 6.5,
  talotekniikka_asennus = 5.5,
  maa_ja_vesirakentaminen = 5.0
)
TYOLLISYYS_KERTOIMET <- TYOLLISYYS_KERTOIMET_HTV_PER_MILJ_EUR / 1e6
