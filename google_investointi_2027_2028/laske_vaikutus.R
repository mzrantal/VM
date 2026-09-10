# Laskee Googlen 13 mrd. euron konesaliinvestoinnin (2027-2028) BKT-vaikutuksen.
#
# Kaytto:
#   Rscript laske_vaikutus.R
#
# Menetelma (tarkemmin RAPORTTI.md:ssa):
#   1. Investointi jaetaan toimialoittaisiin kysyntashokkeihin vuosille 2027
#      ja 2028 (oletukset.R: TOIMIALAOSUUDET, VUOSIJAKAUMA).
#   2. Kukin toimialan shokki kerrotaan sen kotimaisen arvonlisayksen
#      kertoimella, joka sisaltaa seka suoran etta epasuoran
#      (alihankintaketjun) vaikutuksen ja on puhdistettu tuontivuodosta
#      (ARVONLISAYS_KERTOIMET).
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

laske <- function() {
  tulokset <- list()
  bkt_yhteensa <- 0

  for (vuosi in names(VUOSIJAKAUMA)) {
    vuosiosuus <- VUOSIJAKAUMA[[vuosi]]
    investointi_vuonna <- INVESTOINTI_YHTEENSA * vuosiosuus
    bkt_toimialoittain <- setNames(numeric(length(TOIMIALAOSUUDET)), names(TOIMIALAOSUUDET))
    vuoden_bkt <- 0

    for (toimiala in names(TOIMIALAOSUUDET)) {
      osuus <- TOIMIALAOSUUDET[[toimiala]]
      shokki <- investointi_vuonna * osuus
      kerroin <- ARVONLISAYS_KERTOIMET[[toimiala]]
      bkt_vaikutus <- shokki * kerroin
      bkt_toimialoittain[[toimiala]] <- bkt_vaikutus
      vuoden_bkt <- vuoden_bkt + bkt_vaikutus
    }

    tulokset[[vuosi]] <- list(
      investointi = investointi_vuonna,
      bkt_toimialoittain = bkt_toimialoittain,
      bkt_yhteensa = vuoden_bkt
    )
    bkt_yhteensa <- bkt_yhteensa + vuoden_bkt
  }

  list(tulokset = tulokset, bkt_yhteensa = bkt_yhteensa)
}

tulosta_raportti <- function(tulos) {
  tulokset <- tulos$tulokset
  bkt_yhteensa <- tulos$bkt_yhteensa

  cat(strrep("=", 68), "\n", sep = "")
  cat("Google-datakeskusinvestoinnin (13 mrd. e, 2027-2028) BKT-vaikutus\n")
  cat("HUOM: karkea arvio - katso RAPORTTI.md oletuksista ja rajoitteista\n")
  cat(strrep("=", 68), "\n", sep = "")

  for (vuosi in names(tulokset)) {
    tiedot <- tulokset[[vuosi]]
    cat(sprintf("\n%s: investointi %.2f mrd. e\n", vuosi, tiedot$investointi / 1e9))
    for (toimiala in names(tiedot$bkt_toimialoittain)) {
      arvo <- tiedot$bkt_toimialoittain[[toimiala]]
      cat(sprintf("  %-26s +%8.1f milj. e BKT:hen\n", toimiala, arvo / 1e6))
    }
    cat(sprintf("  %-26s +%8.1f milj. e\n", "YHTEENSA", tiedot$bkt_yhteensa / 1e6))
  }

  cat(sprintf("\nKAIKKI VUODET YHTEENSA: +%.3f mrd. e BKT:hen\n", bkt_yhteensa / 1e9))
  implisiittinen_kerroin <- bkt_yhteensa / INVESTOINTI_YHTEENSA
  cat(sprintf(
    "(implisiittinen kokonaiskerroin: %.2f e BKT / e investointia)\n",
    implisiittinen_kerroin
  ))
}

tulos <- laske()
tulosta_raportti(tulos)
