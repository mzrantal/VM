"""Oletukset: Googlen 13 mrd. euron konesaliinvestoinnin (2027-2028)
jakautuminen toimialoittaisiksi kysyntashokeiksi seka naiden toimialojen
kotimaisen arvonlisayksen kertoimet.

TARKEAA GOOGLE-INVESTOINNISTA:
Google ei ole julkaissut investoinnin toimialakohtaista jakoa. Alla olevat
osuudet ovat arvioita, jotka perustuvat tyypilliseen suuren konesalihankkeen
kustannusrakenteeseen (IT-laitteet, rakennus, talotekniikka, maanrakennus).
Muokkaa TOIMIALAOSUUDET- ja VUOSIJAKAUMA-sanakirjoja, jos tarkempaa tietoa
investoinnin ajoituksesta tai koostumuksesta on saatavilla.

TARKEAA KERTOIMISTA:
ARVONLISAYS_KERTOIMET-arvot eivat ole Tilastokeskuksen tarjonta- ja
kayttotaulukoista (panos-tuotostaulukoista) laskettuja tarkkoja kertoimia,
vaan kirjallisuuteen ja toimialarakenteeseen perustuvia karkeita arvioita.
Tama johtuu siita, etta tama istunto ei paassyt kasiksi Tilastokeskuksen
PxWeb-rajapintaan (ks. hae_tilastokeskus.py). Korvaa nama luvut oikeilla,
taulukoista lasketuilla kertoimilla heti kun rajapintayhteys on kaytettavissa
- katso laske_vaikutus.py ja malli.py, joissa on valmis Leontief-laskenta
oikeaa panos-tuotosmatriisia varten.
"""

# Investoinnin kokonaissumma (euroa), 2027-2028 yhteensa
INVESTOINTI_YHTEENSA = 13_000_000_000

# Vuosijakauma: oletus tasainen 50/50, jos tarkempaa aikataulua ei tiedeta
VUOSIJAKAUMA = {
    2027: 0.50,
    2028: 0.50,
}

# Toimialakohtainen osuus investoinnista (osuuksien summa = 1.0)
TOIMIALAOSUUDET = {
    # Palvelimet, verkkolaitteet, GPU:t yms. (TOL 26/46) - hyvin tuontivaltainen,
    # Suomessa ei juuri valmisteta vastaavia laitteita
    "it_laitteet": 0.75,
    # Konesalirakennukset (TOL F41)
    "talonrakennus": 0.10,
    # Sahko-, LVI-, jaahdytys- ja koneasennus (TOL F43 / C33)
    "talotekniikka_asennus": 0.10,
    # Tontti, liittymat, tie- ja kaapelityot (TOL F42)
    "maa_ja_vesirakentaminen": 0.05,
}

assert abs(sum(TOIMIALAOSUUDET.values()) - 1.0) < 1e-9
assert abs(sum(VUOSIJAKAUMA.values()) - 1.0) < 1e-9

# Kotimaisen arvonlisayksen kertoimet (suora + epasuora vaikutus alihankinta-
# ketjussa, tuontivuodolla oikaistu) toimialoittain. KARKEITA ARVIOITA, ks.
# yllaoleva huomautus.
ARVONLISAYS_KERTOIMET = {
    "it_laitteet": 0.15,
    "talonrakennus": 0.60,
    "talotekniikka_asennus": 0.45,
    "maa_ja_vesirakentaminen": 0.62,
}
