# Oikea Tilastokeskus-data tähän kansioon

Tämä kansio on tarkoitettu kahdelle Tilastokeskuksen (pxdata.stat.fi)
panos-tuotos-taulukolle, jotka `laske_vaikutus.R` osaa lukea automaattisesti,
jos ne löytyvät täältä. Jos tiedostoja ei ole, skripti käyttää
`oletukset.R`:n karkeita arvioita (nykyinen oletustila).

## Miksi juuri nämä kaksi taulukkoa

- **14yq - Leontiefin käänteismatriisi**: valmiiksi laskettu (I-A)^-1,
  laskettu Tilastokeskuksen mukaan **kotimaisesta** käyttötaulukosta (ei siis
  sisällä tuontia) - sopii suoraan tälle mallille ilman lisäkäsittelyä.
- **14yn - Panos-tuotostaulukko perushintaan** (tai vastaava taulukko, josta
  löytyvät toimialoittainen tuotos ja arvonlisäys): tarvitaan, koska
  käänteismatriisi itsessään ei sisällä arvonlisäystietoa - siitä lasketaan
  toimialoittainen arvonlisäys/tuotos-kerroin.

## Näin viet tiedot PxWebistä

1. Avaa taulukko pxdata.stat.fi:ssä (Kansantalouden tilinpito -> Tarjonta- ja
   käyttötaulukot / Panos-tuotos -> 14yq / 14yn tai vastaava).
2. Valitse kaikki toimialat riveille ja sarakkeille (14yq) / tarvittavat
   muuttujat (tuotos, arvonlisäys) toimialoittain (14yn).
3. Vie taulukko CSV-muodossa (yleensä "Lataa tiedosto" / "Vie" -> CSV).
4. Tallenna tiedostot tähän kansioon täsmälleen näillä nimillä:
   - `kaanteismatriisi_14yq.csv`
   - `arvonlisays_tuotos_14yn.csv`

## Odotettu tiedostomuoto

**`kaanteismatriisi_14yq.csv`**: ensimmäinen sarake toimialakoodit (rivit),
muut sarakkeet toimialakoodien mukaan nimettyjä (sarakkeet), solut
käänteismatriisin arvoja. Rivien ja sarakkeiden koodien on täsmättävä.

```
toimiala,F41,F42,F43,C26,...
F41,1.42,0.03,0.01,0.00,...
F42,0.02,1.31,0.00,0.00,...
...
```

**`arvonlisays_tuotos_14yn.csv`**: sarakkeet `toimiala`, `tuotos`,
`arvonlisays` (samat toimialakoodit kuin yllä).

```
toimiala,tuotos,arvonlisays
F41,12345,6789
F42,...,...
```

**HUOM:** PxWebin CSV-vienti ei aina näytä täsmälleen tältä (erotin,
otsikkorivien määrä, desimaalipilkku vs. -piste voivat vaihdella). Jos
`lataa_oikea_data.R`:n lukufunktiot eivät toimi sellaisenaan viedyn
tiedoston kanssa, muokkaa niitä vastaamaan oikeaa muotoa - virheilmoitus
kertoo yleensä mikä täsmää väärin.

## Toimialakoodien vastaavuus

`oletukset.R`:n `TOIMIALA_KOODIT_14Y`-muuttujassa on **tarkistamaton arvaus**
siitä, mitkä 14yq/14yn:n toimialakoodit vastaavat tämän mallin neljää
toimialaryhmää (talonrakennus, maa- ja vesirakentaminen,
talotekniikka-/koneasennus, IT-laitteet). Tarkista ja korjaa nämä koodit
taulukon oikeiden "Toimiala"-muuttujan arvojen mukaan ennen tulosten
käyttöä.
