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
# Seka BKT- etta tyollisyysvaikutukselle on kaksi laskentapolkua:
#   1. OIKEA DATA (jos data/panoskertoimet_14yq.csv ja
#      data/kayttotaulukko_14yn.csv loytyvat - ks. data/README.md):
#      kaytetaan Tilastokeskuksen oikeaa, 63 toimialan teknista
#      kerroinmatriisia A (14yq, kayttajan vahvistamana KOTIMAINEN),
#      ratkaistaan taydellinen Leontief-malli (malli.R:
#      leontief_tuotanto()) ja kerrotaan tuloksena saatu kokonaistuotanto
#      taulukosta 14yq saatavalla arvonlisayskertoimella (BKT) ja
#      taulukosta 14yn lasketulla tyollisyyskertoimella (tyollisyys).
#      HUOM: tata kaytetaan VAIN rakentamiselle (talonrakennus, maa- ja
#      vesirakentaminen, talotekniikka-/koneasennus) - ei IT-laitteille,
#      ks. RAPORTTI.md:n kohta "Miksi IT-laitteet ei kayta oikeaa
#      Leontief-mallia" (lyhyesti: 14yq:n kotimainen A-matriisi olettaisi
#      virheellisesti etta koko tuontivaltainen IT-hankinta kysyisi lisaa
#      kotimaista tietokonevalmistusta).
#   2. KARKEA ARVIO (IT-laitteille aina, ja rakentamisellekin
#      varafallbackina jos oikeaa dataa ei loydy tai sen lukeminen
#      epaonnistuu): oletukset.R:n kirjallisuuteen pohjautuvat
#      ARVONLISAYS_KERTOIMET/TYOLLISYYS_KERTOIMET kerrottuna
#      toimialoittaisilla kysyntashokeilla - suuruusluokka-arvio.

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

#' BKT- ja tyollisyysvaikutus oikealla Tilastokeskus-datalla (14yq: 63
#' toimialan tekninen kerroinmatriisi A + arvonlisayskerroin, 14yn: tuotos
#' ja tyollisyys), TOIMIALA_KOODIT_14Y-vastaavuuden kautta. Ratkaisee taydet
#' Leontief-yhtalot (x = (I-A)^-1 d) 63 toimialan tarkkuudella, joten
#' vaikutus leviaa myos oman nelja ryhmamme ulkopuolelle koko
#' toimialaverkostoon (alihankintaketjut).
#'
#' HYBRIDIMALLI - TARKEA RAJAUS IT-LAITTEISTA:
#' it_laitteet JATETAAN POIS taman oikean Leontief-mallin piirista ja
#' lasketaan edelleen oletukset.R:n karkealla kertoimella. Syy: 14yq:n
#' A-matriisi mallintaa KOTIMAISTA tuotantoa - jos it_laitteet-shokki
#' (Google-laitehankinnat, valtaosin tuontia) syotettaisiin sellaisenaan
#' kysyntana toimialalle "26" (tietokoneiden valmistus), malli olettaisi
#' VIRHEELLISESTI etta koko summa menee kotimaiseen tietokonevalmistukseen.
#' Tama testattiin taman istunnon aikana: se nosti implisiittisen
#' kokonaiskertoimen ~0,59:aan, mika on epauskottavan korkea tuontivaltaiselle
#' laitehankinnalle. Koska taulukoista ei ole saatavilla toimialakohtaista
#' tuontiosuutta, jolla shokin kotimainen osuus voitaisiin netottaa oikein
#' ennen Leontief-laskentaa, it_laitteet-osuus lasketaan turvallisemmin
#' oletukset.R:n karkealla, tuontivuodon tietoisesti huomioivalla
#' kertoimella (ARVONLISAYS_KERTOIMET/TYOLLISYYS_KERTOIMET["it_laitteet"]).
#' Rakentamisen kolme ryhmaa (talonrakennus, maa- ja vesirakentaminen,
#' talotekniikka-/koneasennus) sen sijaan OVAT lahes kokonaan kotimaista
#' palvelutuotantoa, joten niille taysi Leontief-malli on perusteltu.
#'
#' @return list(bkt = list(tulokset=..., yhteensa=...),
#'   tyollisyys = list(tulokset=..., yhteensa=...)), samassa muodossa kuin
#'   laske_vaikutus() palauttaa.
laske_oikealla_datalla <- function(data_kansio, vuosi_data = vuoden_data_oletus) {
  malli_data <- lataa_oikea_malli(data_kansio, vuosi_data)
  toimialat <- malli_data$toimialat
  rakennus_toimialat <- c("talonrakennus", "maa_ja_vesirakentaminen", "talotekniikka_asennus")

  bkt_tulokset <- list()
  bkt_yhteensa <- 0
  tyollisyys_tulokset <- list()
  tyollisyys_yhteensa <- 0

  for (vuosi in names(VUOSIJAKAUMA)) {
    investointi_vuonna <- INVESTOINTI_YHTEENSA * VUOSIJAKAUMA[[vuosi]]

    # Rakentaminen: oikea Leontief-malli (63 toimialaa, kotimainen A)
    rakennus_shokki <- investointi_vuonna * TOIMIALAOSUUDET[rakennus_toimialat]
    d <- rakenna_kysyntavektori(toimialat, rakennus_shokki)
    x <- leontief_tuotanto(malli_data$A, d)
    bkt_rakennus <- sum(malli_data$va_kertoimet * x)
    tyollisyys_rakennus <- sum(malli_data$tyollisyys_kertoimet * x)

    # IT-laitteet: karkea arvio (ks. yllaoleva huomautus)
    it_shokki <- investointi_vuonna * TOIMIALAOSUUDET[["it_laitteet"]]
    bkt_it <- it_shokki * ARVONLISAYS_KERTOIMET[["it_laitteet"]]
    tyollisyys_it <- it_shokki * TYOLLISYYS_KERTOIMET[["it_laitteet"]]

    bkt_vuosi <- bkt_rakennus + bkt_it
    tyollisyys_vuosi <- tyollisyys_rakennus + tyollisyys_it

    bkt_tulokset[[vuosi]] <- list(investointi = investointi_vuonna, vaikutus_yhteensa = bkt_vuosi)
    tyollisyys_tulokset[[vuosi]] <- list(investointi = investointi_vuonna, vaikutus_yhteensa = tyollisyys_vuosi)

    bkt_yhteensa <- bkt_yhteensa + bkt_vuosi
    tyollisyys_yhteensa <- tyollisyys_yhteensa + tyollisyys_vuosi
  }

  list(
    bkt = list(tulokset = bkt_tulokset, yhteensa = bkt_yhteensa),
    tyollisyys = list(tulokset = tyollisyys_tulokset, yhteensa = tyollisyys_yhteensa)
  )
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

#' Tulostaa BKT-raportin, kun laskenta on tehty oikealla Tilastokeskus-
#' datalla (laske_oikealla_datalla()$bkt). Ei tulosta toimialoittaista
#' erittelya, koska taulukossa on 63 toimialaa - vain vuosittainen ja
#' kokonais-BKT-vaikutus.
tulosta_raportti_oikea <- function(tulos) {
  tulokset <- tulos$tulokset
  bkt_yhteensa <- tulos$yhteensa

  cat(strrep("=", 68), "\n", sep = "")
  cat("Google-datakeskusinvestoinnin (13 mrd. e, 2027-2028) BKT-vaikutus\n")
  cat("Rakentaminen: Tilastokeskuksen 14yq/14yn-data (Leontief, 63 toimialaa)\n")
  cat("IT-laitteet:  karkea arvio (oletukset.R) - ks. RAPORTTI.md\n")
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

#' Tulostaa tyollisyysraportin oikealla datalla lasketuista tuloksista
#' (laske_oikealla_datalla()$tyollisyys). HUOM: yksikko on tassa TYOLLISTEN
#' MAARA (henkilotietoa Tilastokeskuksen "E1 Tyolliset"-rivista), EI
#' henkilotyovuosi (htv) kuten karkeassa arviossa - lahella samaa asiaa,
#' mutta ei tasmalleen sama mittayksikko (osa-aikaiset lasketaan tassa
#' yhtena tyollisena, ei osittaisena htv:na).
tulosta_tyollisyys_oikea <- function(tulos) {
  tulokset <- tulos$tulokset
  yhteensa <- tulos$yhteensa

  cat("\n", strrep("=", 68), "\n", sep = "")
  cat("Tyollisyysvaikutus (tyollisten maara)\n")
  cat("Rakentaminen: Tilastokeskuksen 14yq/14yn-data - IT-laitteet: karkea arvio\n")
  cat(strrep("=", 68), "\n", sep = "")

  for (vuosi in names(tulokset)) {
    tiedot <- tulokset[[vuosi]]
    cat(sprintf(
      "\n%s: investointi %.2f mrd. e -> tyollisyysvaikutus ~%.0f tyollista\n",
      vuosi, tiedot$investointi / 1e9, tiedot$vaikutus_yhteensa
    ))
  }

  cat(sprintf("\nKAIKKI VUODET YHTEENSA: ~%.0f tyollista\n", yhteensa))
  cat("(vain rakennusvaiheen tilapainen tyollisyysvaikutus, ei konesalin\n")
  cat(" kaytonaikaista, pysyvaa henkilostoa - ks. RAPORTTI.md. Yksikko on\n")
  cat(" tyollisten maara, ei henkilotyovuosi - ks. yllaoleva huomautus.)\n")
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
  tulos_oikea <- tryCatch(
    laske_oikealla_datalla(data_kansio),
    error = function(e) {
      cat("Oikean datan kaytto epaonnistui:", conditionMessage(e), "\n")
      cat("Kaytetaan sen sijaan karkeita arvioita (oletukset.R).\n\n")
      NULL
    }
  )
} else {
  tulos_oikea <- NULL
  cat("Ei loytynyt Tilastokeskus-dataa data/-kansiosta - kaytetaan karkeita,\n")
  cat("kirjallisuuteen pohjautuvia arvioita (oletukset.R). Ks. data/README.md,\n")
  cat("miten oikea data otetaan kayttoon.\n\n")
}

if (!is.null(tulos_oikea)) {
  tulosta_raportti_oikea(tulos_oikea$bkt)
  tulosta_tyollisyys_oikea(tulos_oikea$tyollisyys)
} else {
  tulos_bkt <- laske()
  tulosta_raportti(tulos_bkt)

  tulos_tyollisyys <- laske_vaikutus(TYOLLISYYS_KERTOIMET)
  tulosta_tyollisyys(tulos_tyollisyys)
}
