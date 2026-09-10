"""Apufunktiot Tilastokeskuksen PxWeb-rajapinnan kayttoon.

Tama moduuli hakee kansantalouden tilinpidon tarjonta- ja kayttotaulukot /
panos-tuotostaulukot Tilastokeskuksen PxWeb-rajapinnasta (pxdata.stat.fi),
jotta niista voidaan laskea toimialoittainen tekninen kerroinmatriisi A ja
arvonlisayskertoimet malli.py:n Leontief-laskentaa varten.

HUOM - TAMAN ISTUNNON RAJOITUS:
Tata koodia kirjoitettaessa istunnon verkkoyhteys pxdata.stat.fi-osoitteeseen
oli estetty (hiekkalaatikkoymparistön ulosmenevan liikenteen rajoitus, HTTP
403 yhdyskaytavalta). Koodi on kuitenkin toiminnallista PxWeb-rajapinnan
vakiokayttoa (JSON-stat2-kysely) ja toimii ajettuna ymparistossa, jossa on
internet-yhteys, esim. kayttajan omalla koneella.

TAULUKON OSOITE:
PxWeb-taulukoiden tarkat tunnukset (esim. "khtp" tms.) vaihtelevat
julkaisuvuosittain, joten niita ei ole kovakoodattu tahan. Etsi oikea
taulukko selaimella osoitteesta:
    https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/
    -> Kansantalouden tilinpito -> Tarjonta- ja kayttotaulukot / Panos-tuotos
ja aseta taulukon rajapinta-URL alla olevaan TAULUKON_URL-muuttujaan (tai
anna se komentorivilta / kutsuvasta koodista).
"""
from __future__ import annotations

import json
import urllib.error
import urllib.request

TAULUKON_URL = ""  # esim. "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/.../taulukko.px"


def hae_taulukon_metatiedot(taulukon_url: str, timeout: int = 30) -> dict:
    """Hakee taulukon muuttujat ja koodit (GET-pyynto), jotta oikea kysely
    (toimialat, muuttujat, vuodet) voidaan rakentaa."""
    with urllib.request.urlopen(taulukon_url, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def hae_pxweb_data(taulukon_url: str, kysely: dict, timeout: int = 60) -> dict:
    """Lahettaa PxWeb-kyselyn (POST, JSON) ja palauttaa vastauksen
    JSON-stat2-muodossa.

    `kysely` on PxWebin odottama kyselyrakenne, esim.:
        {
            "query": [
                {"code": "Toimiala", "selection": {"filter": "item", "values": ["..."]}},
                {"code": "Vuosi", "selection": {"filter": "item", "values": ["2021"]}},
            ],
            "response": {"format": "json-stat2"},
        }
    """
    data = json.dumps(kysely).encode("utf-8")
    req = urllib.request.Request(
        taulukon_url, data=data, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def yhteys_toimiiko(url: str = "https://pxdata.stat.fi", timeout: int = 5) -> bool:
    """Pika-testi: onko Tilastokeskuksen rajapintaan yhteytta tassa
    ymparistossa. Kaytetaan laske_vaikutus.py:ssa paattamaan, kaytetaanko
    oikeaa dataa vai oletukset.py:n karkeita arvioita."""
    try:
        urllib.request.urlopen(url, timeout=timeout)
        return True
    except (urllib.error.URLError, TimeoutError, OSError):
        return False


if __name__ == "__main__":
    if yhteys_toimiiko():
        print("Yhteys Tilastokeskuksen rajapintaan toimii.")
        if TAULUKON_URL:
            print(json.dumps(hae_taulukon_metatiedot(TAULUKON_URL), indent=2)[:2000])
        else:
            print("Aseta TAULUKON_URL-muuttuja ennen taulukon hakemista.")
    else:
        print(
            "Ei yhteytta Tilastokeskuksen rajapintaan tasta ymparistosta.\n"
            "laske_vaikutus.py kayttaa oletukset.py:n karkeita arvioita."
        )
