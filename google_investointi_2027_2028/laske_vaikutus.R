# Laskee Googlen 13 mrd. euron konesaliinvestoinnin (2027-2028) BKT- ja
# tyollisyysvaikutuksen.
#
# Kaytto:
#   Rscript laske_vaikutus.R
#
# Menetelma (tarkemmin RAPORTTI.md:ssa):
#   1. Investointi jaetaan toimialoittaisiin kysyntashokkeihin vuosille 2027
#      ja 2028 (oletukset.R: TOIMIALAOSUUDET, VUOSIJAKAUMA).
#   2. Kukin toimialan shokki kerrotaan sen kotimaisen arvonlisayksen
#      kertoimella (ARVONLISAYS_KERTOIMET) - saadaan BKT-vaikutus - tai
#      tyollisyyskertoimella (TYOLLISYYS_KERTOIMET) - saadaan
#      henkilotyovuosina (htv) mitattu tyollisyysvaikutus. Molemmat
#      kertoimet sisaltavat seka suoran etta epasuoran (alihankintaketjun)
#      vaikutuksen ja on puhdistettu tuontivuodosta.
#   3. Tulokset summataan vuosittain ja koko ajanjaksolle.
#
# BKT-osalle on kaksi laskentapolkua:
#   1. OIKEA DATA (jos data/kaanteismatriisi_14yq.csv ja
#      data/arvonlisays_tuotos_14yn.csv loytyvat - ks. data/README.md):
#      kaytetaan Tilastokeskuksen valmista Leontiefin kaanteismatriisia
#      (malli.R: arvonlisays_vaikutus_kaanteismatriisilla()) - tarkka tulos.
#   2. KARKEA ARVIO (oletus, jos oikeaa dataa ei loydy): oletukset.R:n
#      kirjallisuuteen pohjautuvat ARVONLISAYS_KERTOIMET kerrottuna
#      toimialoittaisilla kysyntashokeilla - suuruusluokka-arvio.
#
# TYOLLISYYSVAIKUTUS lasketaan aina karkealla arviolla (TYOLLISYYS_KERTOIMET),
# koska vastaavaa valmista tyollisyys-panos-tuotostaulukkoa ei ole (viela)
# kaytetty tassa.
#
# TAMA ISTUNTO: Tilastokeskuksen rajapinta ei ollut tavoitettavissa
# (hiekkalaatikkoymparistön ulosmenevan verkkoliikenteen rajoitus), joten
# data/-kansio on tyhja ja BKT-laskenta kayttaa polkua 2 (karkea arvio).
# Ks. data/README.md, miten oikea data otetaan kayttoon.

skriptin_kansio <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  polku <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(polku) == 1) dirname(normalizePath(polku)) else "."
}
source(file.path(skriptin_kansio(), "oletukset.R"))
source(file.path(skriptin_kansio(), "malli.R"))
source(file.path(skriptin_kansio(), "lataa_oikea_data.R"))
data_kansio <- file.path(skriptin_kansio(), "data")

#' Yleinen laskin: kerroo vuosittaiset toimialakohtaiset kysyntashokit
#' annetulla kerroinvektorilla (esim. ARVONLISAYS_KERTOIMET tai
#' TYOLLISYYS_KERTOIMET) ja summaa tulokset toimialoittain, vuosittain ja
#' kokonaisuudessaan.
laske_vaikutus <- function(kertoimet) {
  tulokset <- list()
  yhteensa <- 0

  for (vuosi in names(VUOSIJAKAUMA)) {
    vuosiosuus <- VUOSIJAKAUMA[[vuosi]]
    investointi_vuonna <- INVESTOINTI_YHTEENSA * vuosiosuus
    vaikutus_toimialoittain <- setNames(numeric(length(TOIMIALAOSUUDET)), names(TOIMIALAOSUUDET))
    vuoden_vaikutus <- 0

    for (toimiala in names(TOIMIALAOSUUDET)) {
      osuus <- TOIMIALAOSUUDET[[toimiala]]
      shokki <- investointi_vuonna * osuus
      kerroin <- kertoimet[[toimiala]]
      vaikutus <- shokki * kerroin
      vaikutus_toimialoittain[[toimiala]] <- vaikutus
      vuoden_vaikutus <- vuoden_vaikutus + vaikutus
    }

    tulokset[[vuosi]] <- list(
      investointi = investointi_vuonna,
      vaikutus_toimialoittain = vaikutus_toimialoittain,
      vaikutus_yhteensa = vuoden_vaikutus
    )
    yhteensa <- yhteensa + vuoden_vaikutus
  }

  list(tulokset = tulokset, yhteensa = yhteensa)
}

laske <- function() laske_vaikutus(ARVONLISAYS_KERTOIMET)

#' BKT-vaikutus oikealla Tilastokeskus-datalla (14yq: kaanteismatriisi,
#' 14yn: tuotos/arvonlisays), TOIMIALA_KOODIT_14Y-vastaavuuden kautta.
#' Palauttaa saman list(tulokset=..., yhteensa=...) -muodon kuin
#' laske_vaikutus(), mutta tiedot$vaikutus_toimialoittain kattaa TASSA
#' KAIKKI kaanteismatriisin toimialat (ei vain omaa nelja ryhmaamme),
#' koska kaanteismatriisi levittaa vaikutuksen koko toimialaverkostoon.
laske_bkt_oikealla_datalla <- function(data_kansio) {
  kaanteismatriisi <- lataa_kaanteismatriisi(
    file.path(data_kansio, "kaanteismatriisi_14yq.csv")
  )
  arvonlisays_kertoimet_oikea <- lataa_arvonlisays_tuotos(
    file.path(data_kansio, "arvonlisays_tuotos_14yn.csv")
  )
  kaikki_koodit <- rownames(kaanteismatriisi)

  tulokset <- list()
  yhteensa <- 0
  for (vuosi in names(VUOSIJAKAUMA)) {
    investointi_vuonna <- INVESTOINTI_YHTEENSA * VUOSIJAKAUMA[[vuosi]]
    oma_shokki <- investointi_vuonna * TOIMIALAOSUUDET
    d <- rakenna_kysyntavektori(kaikki_koodit, oma_shokki)
    tulos <- arvonlisays_vaikutus_kaanteismatriisilla(
      kaanteismatriisi, arvonlisays_kertoimet_oikea, d
    )
    tulokset[[vuosi]] <- list(
      investointi = investointi_vuonna,
      vaikutus_toimialoittain = setNames(tulos$tuotanto * arvonlisays_kertoimet_oikea, kaikki_koodit),
      vaikutus_yhteensa = tulos$bkt
    )
    yhteensa <- yhteensa + tulos$bkt
  }
  list(tulokset = tulokset, yhteensa = yhteensa)
}

tulosta_raportti <- function(tulos) {
  tulokset <- tulos$tulokset
  bkt_yhteensa <- tulos$yhteensa

  cat(strrep("=", 68), "\n", sep = "")
  cat("Google-datakeskusinvestoinnin (13 mrd. e, 2027-2028) BKT-vaikutus\n")
  cat("HUOM: karkea arvio - katso RAPORTTI.md oletuksista ja rajoitteista\n")
  cat(strrep("=", 68), "\n", sep = "")

  for (vuosi in names(tulokset)) {
    tiedot <- tulokset[[vuosi]]
    cat(sprintf("\n%s: investointi %.2f mrd. e\n", vuosi, tiedot$investointi / 1e9))
    for (toimiala in names(tiedot$vaikutus_toimialoittain)) {
      arvo <- tiedot$vaikutus_toimialoittain[[toimiala]]
      cat(sprintf("  %-26s +%8.1f milj. e BKT:hen\n", toimiala, arvo / 1e6))
    }
    cat(sprintf("  %-26s +%8.1f milj. e\n", "YHTEENSA", tiedot$vaikutus_yhteensa / 1e6))
  }

  cat(sprintf("\nKAIKKI VUODET YHTEENSA: +%.3f mrd. e BKT:hen\n", bkt_yhteensa / 1e9))
  implisiittinen_kerroin <- bkt_yhteensa / INVESTOINTI_YHTEENSA
  cat(sprintf(
    "(implisiittinen kokonaiskerroin: %.2f e BKT / e investointia)\n",
    implisiittinen_kerroin
  ))
}

#' Tulostaa BKT-raportin, kun laskenta on tehty oikealla kaanteismatriisilla
#' (laske_bkt_oikealla_datalla()). Ei tulosta toimialoittaista erittelya,
#' koska kaanteismatriisin toimialoja on tyypillisesti kymmenia - vain
#' vuosittainen ja kokonais-BKT-vaikutus.
tulosta_raportti_oikea <- function(tulos) {
  tulokset <- tulos$tulokset
  bkt_yhteensa <- tulos$yhteensa

  cat(strrep("=", 68), "\n", sep = "")
  cat("Google-datakeskusinvestoinnin (13 mrd. e, 2027-2028) BKT-vaikutus\n")
  cat("Laskettu Tilastokeskuksen 14yq/14yn-datalla (data/-kansio)\n")
  cat(strrep("=", 68), "\n", sep = "")

  for (vuosi in names(tulokset)) {
    tiedot <- tulokset[[vuosi]]
    cat(sprintf(
      "\n%s: investointi %.2f mrd. e -> BKT-vaikutus +%.1f milj. e\n",
      vuosi, tiedot$investointi / 1e9, tiedot$vaikutus_yhteensa / 1e6
    ))
  }

  cat(sprintf("\nKAIKKI VUODET YHTEENSA: +%.3f mrd. e BKT:hen\n", bkt_yhteensa / 1e9))
  implisiittinen_kerroin <- bkt_yhteensa / INVESTOINTI_YHTEENSA
  cat(sprintf(
    "(implisiittinen kokonaiskerroin: %.2f e BKT / e investointia)\n",
    implisiittinen_kerroin
  ))
}

tulosta_tyollisyys <- function(tulos) {
  tulokset <- tulos$tulokset
  htv_yhteensa <- tulos$yhteensa

  cat("\n", strrep("=", 68), "\n", sep = "")
  cat("Tyollisyysvaikutus (henkilotyovuotta, htv) - karkea arvio\n")
  cat(strrep("=", 68), "\n", sep = "")

  for (vuosi in names(tulokset)) {
    tiedot <- tulokset[[vuosi]]
    cat(sprintf("\n%s:\n", vuosi))
    for (toimiala in names(tiedot$vaikutus_toimialoittain)) {
      arvo <- tiedot$vaikutus_toimialoittain[[toimiala]]
      cat(sprintf("  %-26s %8.0f htv\n", toimiala, arvo))
    }
    cat(sprintf("  %-26s %8.0f htv\n", "YHTEENSA", tiedot$vaikutus_yhteensa))
  }

  cat(sprintf("\nKAIKKI VUODET YHTEENSA: ~%.0f henkilotyovuotta\n", htv_yhteensa))
  cat("(vain rakennusvaiheen tilapainen tyollisyysvaikutus, ei konesalin\n")
  cat(" kaytonaikaista, pysyvaa henkilostoa - ks. RAPORTTI.md)\n")
}

if (oikea_data_saatavilla(data_kansio)) {
  tulos_bkt_oikea <- tryCatch(
    laske_bkt_oikealla_datalla(data_kansio),
    error = function(e) {
      cat("Oikean datan kaytto epaonnistui:", conditionMessage(e), "\n")
      cat("Kaytetaan sen sijaan karkeita arvioita (oletukset.R).\n\n")
      NULL
    }
  )
} else {
  tulos_bkt_oikea <- NULL
  cat("Ei loytynyt Tilastokeskus-dataa data/-kansiosta - kaytetaan karkeita,\n")
  cat("kirjallisuuteen pohjautuvia arvioita (oletukset.R). Ks. data/README.md,\n")
  cat("miten oikea data otetaan kayttoon.\n\n")
}

if (!is.null(tulos_bkt_oikea)) {
  tulosta_raportti_oikea(tulos_bkt_oikea)
} else {
  tulos_bkt <- laske()
  tulosta_raportti(tulos_bkt)
}

tulos_tyollisyys <- laske_vaikutus(TYOLLISYYS_KERTOIMET)
tulosta_tyollisyys(tulos_tyollisyys)
