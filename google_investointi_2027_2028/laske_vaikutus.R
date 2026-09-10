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
# Jos Tilastokeskuksen PxWeb-rajapintaan on yhteys ja hae_tilastokeskus.R:aan
# on lisatty oikea taulukon URL ja siita on rakennettu toimialoittainen
# kerroinmatriisi A seka arvonlisayskertoimet, kaytetaan sen sijaan malli.R:n
# taytta Leontief-laskentaa (arvonlisays_vaikutus()).
#
# TAMA ISTUNTO: Tilastokeskuksen rajapinta ei ollut tavoitettavissa
# (hiekkalaatikkoymparistön ulosmenevan verkkoliikenteen rajoitus), joten
# tulokset perustuvat oletukset.R:n karkeisiin, kirjallisuuteen pohjautuviin
# arvioihin. Nama tulokset ovat siis suuruusluokka-arvioita, ei tarkkoja
# tilastollisia laskelmia.

skriptin_kansio <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  polku <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(polku) == 1) dirname(normalizePath(polku)) else "."
}
source(file.path(skriptin_kansio(), "oletukset.R"))

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

tulos_bkt <- laske()
tulosta_raportti(tulos_bkt)

tulos_tyollisyys <- laske_vaikutus(TYOLLISYYS_KERTOIMET)
tulosta_tyollisyys(tulos_tyollisyys)
