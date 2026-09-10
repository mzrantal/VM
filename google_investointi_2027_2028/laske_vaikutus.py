"""Laskee Googlen 13 mrd. euron konesaliinvestoinnin (2027-2028) BKT-vaikutuksen.

Kaytto:
    python3 laske_vaikutus.py

Menetelma (tarkemmin RAPORTTI.md:ssa):
  1. Investointi jaetaan toimialoittaisiin kysyntashokkeihin vuosille 2027 ja
     2028 (oletukset.py: TOIMIALAOSUUDET, VUOSIJAKAUMA).
  2. Kukin toimialan shokki kerrotaan sen kotimaisen arvonlisayksen
     kertoimella, joka sisaltaa seka suoran etta epasuoran (alihankintaketjun)
     vaikutuksen ja on puhdistettu tuontivuodosta (ARVONLISAYS_KERTOIMET).
  3. Tulokset summataan vuosittain ja koko ajanjaksolle.

Jos Tilastokeskuksen PxWeb-rajapintaan on yhteys ja hae_tilastokeskus.py:hyn
on lisatty oikea taulukon URL ja siita on rakennettu toimialoittainen
kerroinmatriisi A seka arvonlisayskertoimet, kaytetaan sen sijaan malli.py:n
taytta Leontief-laskentaa (ks. laske_leontief_esimerkki() alla).

TAMA ISTUNTO: Tilastokeskuksen rajapinta ei ollut tavoitettavissa
(hiekkalaatikkoymparistön ulosmenevan verkkoliikenteen rajoitus), joten
tulokset perustuvat oletukset.py:n karkeisiin, kirjallisuuteen pohjautuviin
arvioihin. Nama tulokset ovat siis suuruusluokka-arvioita, ei tarkkoja
tilastollisia laskelmia.
"""
from __future__ import annotations

from oletukset import (
    ARVONLISAYS_KERTOIMET,
    INVESTOINTI_YHTEENSA,
    TOIMIALAOSUUDET,
    VUOSIJAKAUMA,
)


def laske() -> tuple[dict, float]:
    tulokset: dict = {vuosi: {} for vuosi in VUOSIJAKAUMA}
    bkt_yhteensa = 0.0

    for vuosi, vuosiosuus in VUOSIJAKAUMA.items():
        investointi_vuonna = INVESTOINTI_YHTEENSA * vuosiosuus
        bkt_toimialoittain = {}
        vuoden_bkt = 0.0

        for toimiala, osuus in TOIMIALAOSUUDET.items():
            shokki = investointi_vuonna * osuus
            kerroin = ARVONLISAYS_KERTOIMET[toimiala]
            bkt_vaikutus = shokki * kerroin
            bkt_toimialoittain[toimiala] = bkt_vaikutus
            vuoden_bkt += bkt_vaikutus

        tulokset[vuosi] = {
            "investointi": investointi_vuonna,
            "bkt_toimialoittain": bkt_toimialoittain,
            "bkt_yhteensa": vuoden_bkt,
        }
        bkt_yhteensa += vuoden_bkt

    return tulokset, bkt_yhteensa


def tulosta_raportti(tulokset: dict, bkt_yhteensa: float) -> None:
    print("=" * 68)
    print("Google-datakeskusinvestoinnin (13 mrd. e, 2027-2028) BKT-vaikutus")
    print("HUOM: karkea arvio - katso RAPORTTI.md oletuksista ja rajoitteista")
    print("=" * 68)

    for vuosi, tiedot in tulokset.items():
        print(f"\n{vuosi}: investointi {tiedot['investointi'] / 1e9:.2f} mrd. e")
        for toimiala, arvo in tiedot["bkt_toimialoittain"].items():
            print(f"  {toimiala:26s} +{arvo / 1e6:8.1f} milj. e BKT:hen")
        print(f"  {'YHTEENSA':26s} +{tiedot['bkt_yhteensa'] / 1e6:8.1f} milj. e")

    print(f"\nKAIKKI VUODET YHTEENSA: +{bkt_yhteensa / 1e9:.3f} mrd. e BKT:hen")
    implisiittinen_kerroin = bkt_yhteensa / INVESTOINTI_YHTEENSA
    print(
        f"(implisiittinen kokonaiskerroin: {implisiittinen_kerroin:.2f} "
        "e BKT / e investointia)"
    )


if __name__ == "__main__":
    _tulokset, _bkt_yhteensa = laske()
    tulosta_raportti(_tulokset, _bkt_yhteensa)
