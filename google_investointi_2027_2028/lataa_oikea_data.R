# Lataa oikeat panos-tuotos-tiedot paikallisista CSV-tiedostoista.
#
# Koska tama istunto ei paassyt kasiksi Tilastokeskuksen PxWeb-rajapintaan
# (verkkoyhteys estetty hiekkalaatikkoymparistossa), tama moduuli ei hae
# dataa elavasti netista, vaan lukee kaksi paikallista CSV-tiedostoa, jotka
# on viety (export) PxWeb-kayttoliittymasta (pxdata.stat.fi) selaimella:
#
#   data/kaanteismatriisi_14yq.csv       - taulukko 14yq (Leontiefin
#                                          kaanteismatriisi, kotimainen)
#   data/arvonlisays_tuotos_14yn.csv     - taulukko 14yn (tuotos ja
#                                          arvonlisays toimialoittain)
#
# Ks. data/README.md odotetusta tiedostomuodosta ja ohjeista viedä
# taulukot PxWebista. HUOM: naita lukufunktioita EI ole voitu testata
# oikealla PxWeb-viennilla tassa istunnossa (verkkoyhteys estetty) - jos
# viety CSV nayttaa toiselta kuin talla oletetaan, muokkaa funktioita
# vastaamaan oikeaa muotoa (virheilmoitus yleensa kertoo mika ei tasmaa).

#' Lukee valmiin Leontiefin kaanteismatriisin CSV-tiedostosta.
#'
#' Odottaa ensimmaisen sarakkeen olevan rivien toimialakoodit ja muiden
#' sarakkeiden olevan nimettyja sarakkeiden toimialakoodien mukaan, niin
#' etta rownames(m) == colnames(m).
lataa_kaanteismatriisi <- function(polku) {
  df <- read.csv(polku, check.names = FALSE, row.names = 1)
  m <- as.matrix(df)
  storage.mode(m) <- "numeric"
  if (!identical(rownames(m), colnames(m))) {
    stop(
      "kaanteismatriisi_14yq.csv: rivi- ja sarakekoodit eivat tasmaa - ",
      "tarkista, etta ensimmaisen sarakkeen toimialakoodit ovat samat ja ",
      "samassa jarjestyksessa kuin sarakeotsikot. Ks. data/README.md."
    )
  }
  m
}

#' Lukee toimialoittaisen tuotoksen ja arvonlisayksen ja palauttaa
#' arvonlisays/tuotos-kertoimet nimettyna vektorina (nimet = toimialakoodit).
lataa_arvonlisays_tuotos <- function(polku) {
  df <- read.csv(polku)
  vaadi_sarakkeet <- c("toimiala", "tuotos", "arvonlisays")
  puuttuu <- setdiff(vaadi_sarakkeet, names(df))
  if (length(puuttuu) > 0) {
    stop(sprintf(
      "arvonlisays_tuotos_14yn.csv: puuttuvat sarakkeet: %s. Ks. data/README.md.",
      paste(puuttuu, collapse = ", ")
    ))
  }
  setNames(df$arvonlisays / df$tuotos, df$toimiala)
}

#' TRUE jos molemmat tarvittavat CSV-tiedostot loytyvat data_kansio:sta.
oikea_data_saatavilla <- function(data_kansio) {
  file.exists(file.path(data_kansio, "kaanteismatriisi_14yq.csv")) &&
    file.exists(file.path(data_kansio, "arvonlisays_tuotos_14yn.csv"))
}

#' Rakentaa kysyntashokkivektorin 14yq/14yn:n toimialaluokituksessa
#' (pituus = length(kaikki_koodit)) omien toimialaryhmiemme (esim.
#' TOIMIALAOSUUDET * investointi_vuonna) pohjalta, TOIMIALA_KOODIT_14Y
#' -vastaavuuden avulla (oletukset.R).
rakenna_kysyntavektori <- function(kaikki_koodit, oma_shokki) {
  d <- setNames(numeric(length(kaikki_koodit)), kaikki_koodit)
  for (oma_toimiala in names(oma_shokki)) {
    koodi <- TOIMIALA_KOODIT_14Y[[oma_toimiala]]
    if (is.null(koodi) || !(koodi %in% kaikki_koodit)) {
      stop(sprintf(
        "Toimialaa '%s' vastaavaa koodia '%s' ei loydy kaanteismatriisista - tarkista TOIMIALA_KOODIT_14Y oletukset.R:ssa.",
        oma_toimiala, koodi
      ))
    }
    d[[koodi]] <- d[[koodi]] + oma_shokki[[oma_toimiala]]
  }
  d
}
